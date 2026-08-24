import 'dart:convert';
import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_ble/universal_ble.dart';
import 'package:url_launcher/url_launcher.dart';

/// Jenis sambungan printer struk.
enum PrinterKind {
  /// Bluetooth Classic / SPP — printer thermal umum (mis. IWARE).
  classic,

  /// Bluetooth Low Energy — mis. EcoPrint (service 18F0, karakteristik 2AF1).
  ble,

  /// Diteruskan ke aplikasi RawBT: menjangkau printer USB/OTG & merek lain
  /// tanpa driver sendiri. Setara pilihan `rawbt` di web.
  rawbt,
}

/// Printer pilihan pengguna (disimpan di perangkat).
class SavedPrinter {
  const SavedPrinter({required this.name, required this.address, required this.kind});

  final String name;
  final String address;
  final PrinterKind kind;

  Map<String, dynamic> toJson() =>
      {'name': name, 'address': address, 'kind': kind.name};

  static SavedPrinter? fromJson(Map<String, dynamic> j) {
    PrinterKind? kind;
    for (final k in PrinterKind.values) {
      if (k.name == j['kind']) kind = k;
    }
    if (kind == null) return null;

    return SavedPrinter(
      name: '${j['name'] ?? '-'}',
      address: '${j['address'] ?? ''}',
      kind: kind,
    );
  }
}

/// Perangkat hasil pemasangan/pemindaian.
class PrinterDevice {
  const PrinterDevice({
    required this.name,
    required this.address,
    required this.kind,
    this.paired = false,
  });

  final String name;
  final String address;
  final PrinterKind kind;
  final bool paired;
}

/// Kegagalan cetak dengan pesan siap tampil.
class PrinterException implements Exception {
  const PrinterException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Cetak struk thermal dari aplikasi mobile.
///
/// Tiga jalur, menyamai kemampuan web/APK lama:
///  - **Bluetooth Classic (SPP)** untuk printer thermal umum. Printer harus sudah
///    DIPASANGKAN di Setelan Bluetooth Android (sama seperti APK lama).
///  - **BLE** untuk printer yang hanya menyediakan GATT (service `18F0`,
///    karakteristik tulis `2AF1`, mis. EcoPrint).
///  - **RawBT** sebagai jalur cadangan: perintah ESC/POS dikirim ke aplikasi RawBT
///    yang mampu mencetak ke printer **USB/OTG** maupun Bluetooth.
class PrinterService {
  PrinterService._();

  static const _kPrinter = 'mooda_printer';
  static const _kPaper = 'mooda_paper_width';

  // ------------------------------------------------------------- preferensi
  static Future<SavedPrinter?> saved() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kPrinter);
    if (raw == null) return null;
    try {
      return SavedPrinter.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(SavedPrinter printer) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kPrinter, jsonEncode(printer.toJson()));
  }

  static Future<void> forget() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kPrinter);
  }

  /// Lebar kertas (58/80 mm), disinkronkan dengan pengaturan server.
  static Future<int> paperWidth() async =>
      (await SharedPreferences.getInstance()).getInt(_kPaper) ?? 58;

  static Future<void> setPaperWidth(int mm) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kPaper, mm == 80 ? 80 : 58);
  }

  // -------------------------------------------------------------- pencarian
  /// Printer Bluetooth Classic yang SUDAH dipasangkan di Android.
  static Future<List<PrinterDevice>> pairedClassic() async {
    try {
      final list = await PrintBluetoothThermal.pairedBluetooths;
      return list
          .map((b) => PrinterDevice(
                name: b.name,
                address: b.macAdress,
                kind: PrinterKind.classic,
                paired: true,
              ))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Pindai printer BLE di sekitar.
  static Future<List<PrinterDevice>> scanBle({
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final found = <String, PrinterDevice>{};

    try {
      final state = await UniversalBle.getBluetoothAvailabilityState();
      if (state != AvailabilityState.poweredOn) return const [];

      UniversalBle.onScanResult = (device) {
        final name = (device.name ?? '').trim();
        if (name.isEmpty) return; // perangkat tanpa nama tak berguna dipilih
        found[device.deviceId] = PrinterDevice(
          name: name,
          address: device.deviceId,
          kind: PrinterKind.ble,
        );
      };

      await UniversalBle.startScan();
      await Future<void>.delayed(timeout);
      await UniversalBle.stopScan();
      UniversalBle.onScanResult = null;
    } catch (_) {
      // Bluetooth mati / izin ditolak -> daftar kosong, bukan error keras.
    }

    return found.values.toList();
  }

  // ------------------------------------------------------------------ cetak
  static Future<void> printBytes(List<int> bytes, {SavedPrinter? printer}) async {
    final target = printer ?? await saved();

    if (target == null) {
      throw const PrinterException(
        'Printer belum dipilih. Buka Pengaturan -> Printer untuk memilih.',
      );
    }

    switch (target.kind) {
      case PrinterKind.classic:
        await _printClassic(target, bytes);
        break;
      case PrinterKind.ble:
        await _printBle(target, bytes);
        break;
      case PrinterKind.rawbt:
        await _printRawBt(bytes);
        break;
    }
  }

  static Future<void> _printClassic(SavedPrinter target, List<int> bytes) async {
    final connected = await PrintBluetoothThermal.connectionStatus;

    if (!connected) {
      final ok = await PrintBluetoothThermal.connect(macPrinterAddress: target.address);
      if (!ok) {
        throw PrinterException(
          'Gagal menyambung ke ${target.name}. Pastikan printer menyala dan sudah '
          'dipasangkan di Setelan Bluetooth.',
        );
      }
    }

    final sent = await PrintBluetoothThermal.writeBytes(bytes);
    if (!sent) {
      throw const PrinterException('Struk gagal dikirim ke printer.');
    }
  }

  static Future<void> _printBle(SavedPrinter target, List<int> bytes) async {
    final id = target.address;

    try {
      await UniversalBle.connect(id);
      final services = await UniversalBle.discoverServices(id);

      String? serviceId;
      String? charId;
      bool withoutResponse = false;

      for (final s in services) {
        for (final c in s.characteristics) {
          final canWrite = c.properties.contains(CharacteristicProperty.write) ||
              c.properties.contains(CharacteristicProperty.writeWithoutResponse);
          if (!canWrite) continue;

          // Pakai kandidat pertama, tapi utamakan karakteristik printer yang
          // lazim (2AF1 pada service 18F0 — mis. EcoPrint).
          final isPrinterChar = c.uuid.toLowerCase().contains('2af1');
          if (serviceId == null || isPrinterChar) {
            serviceId = s.uuid;
            charId = c.uuid;
            withoutResponse =
                c.properties.contains(CharacteristicProperty.writeWithoutResponse);
          }
          if (isPrinterChar) break;
        }
      }

      if (serviceId == null || charId == null) {
        throw const PrinterException('Printer BLE ini tidak punya jalur tulis data.');
      }

      // BLE hanya menerima paket kecil; kirim bertahap.
      const chunk = 180;
      for (var i = 0; i < bytes.length; i += chunk) {
        final end = (i + chunk < bytes.length) ? i + chunk : bytes.length;
        await UniversalBle.write(
          id,
          serviceId,
          charId,
          Uint8List.fromList(bytes.sublist(i, end)),
          withoutResponse: withoutResponse,
        );
      }
    } on PrinterException {
      rethrow;
    } catch (e) {
      throw PrinterException('Gagal mencetak lewat BLE: $e');
    } finally {
      try {
        await UniversalBle.disconnect(id);
      } catch (_) {
        // abaikan
      }
    }
  }

  /// Kirim ke aplikasi RawBT (menjangkau printer USB/OTG & merek lain).
  static Future<void> _printRawBt(List<int> bytes) async {
    final uri = Uri.parse('rawbt:base64,${base64Encode(bytes)}');

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw const PrinterException(
        'Aplikasi RawBT tidak ditemukan. Pasang RawBT dari Play Store untuk '
        'mencetak lewat USB/OTG.',
      );
    }
  }

  // ---------------------------------------------------------------- ESC/POS
  /// Susun struk dari payload `GET /fnb/orders/{id}/receipt`.
  static Future<List<int>> buildReceipt(Map<String, dynamic> payload) async {
    final store = Map<String, dynamic>.from((payload['store'] ?? const {}) as Map);
    final order = Map<String, dynamic>.from((payload['order'] ?? const {}) as Map);
    final items = (payload['items'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final mm = (store['paper_width'] as num?)?.toInt() ?? await paperWidth();
    final profile = await CapabilityProfile.load();
    final gen = Generator(mm == 80 ? PaperSize.mm80 : PaperSize.mm58, profile);
    final out = <int>[];

    void line(
      String text, {
      PosAlign align = PosAlign.left,
      bool bold = false,
      PosTextSize size = PosTextSize.size1,
    }) {
      out.addAll(gen.text(
        text,
        styles: PosStyles(align: align, bold: bold, height: size, width: size),
      ));
    }

    void totalRow(String label, dynamic value, {bool bold = false}) {
      out.addAll(gen.row([
        PosColumn(text: label, width: 6, styles: PosStyles(bold: bold)),
        PosColumn(
          text: _rp(value),
          width: 6,
          styles: PosStyles(align: PosAlign.right, bold: bold),
        ),
      ]));
    }

    // ---- kop ----
    line('${store['name'] ?? 'Mooda'}',
        align: PosAlign.center, bold: true, size: PosTextSize.size2);
    if (store['show_address'] == true && '${store['address'] ?? ''}'.isNotEmpty) {
      line('${store['address']}', align: PosAlign.center);
    }
    if (store['show_phone'] == true && '${store['phone'] ?? ''}'.isNotEmpty) {
      line('${store['phone']}', align: PosAlign.center);
    }
    if ('${store['header'] ?? ''}'.isNotEmpty) {
      line('${store['header']}', align: PosAlign.center);
    }
    out.addAll(gen.hr());

    // ---- identitas nota ----
    line('${order['invoice_no'] ?? '-'}');
    line('Antrian #${order['queue_number'] ?? '-'}'
        '${order['table_no'] != null ? '  Meja ${order['table_no']}' : ''}');
    line(_fmtTime(order['created_at']));
    if ('${order['customer_name'] ?? ''}'.isNotEmpty) {
      line('Pelanggan: ${order['customer_name']}');
    }
    out.addAll(gen.hr());

    // ---- item ----
    for (final it in items) {
      line('${it['menu'] ?? '-'}');
      out.addAll(gen.row([
        PosColumn(text: '  ${it['qty']} x ${_rp(it['price'])}', width: 7),
        PosColumn(
          text: _rp(it['subtotal']),
          width: 5,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]));

      for (final a in (it['addons'] as List? ?? const [])) {
        if (a is! Map) continue;
        final qty = (a['qty'] ?? 1) as num;
        final price = (a['price'] ?? 0) as num;
        out.addAll(gen.row([
          PosColumn(text: '  + ${a['name']} x$qty', width: 7),
          PosColumn(
            text: _rp(price * qty),
            width: 5,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]));
      }

      if ('${it['notes'] ?? ''}'.isNotEmpty) {
        line('  (${it['notes']})');
      }
    }
    out.addAll(gen.hr());

    // ---- total ----
    totalRow('Subtotal', order['subtotal']);
    if (((order['discount_amount'] ?? 0) as num) > 0) {
      totalRow('Diskon', order['discount_amount']);
    }
    totalRow('Pajak', order['tax']);
    totalRow('TOTAL', order['grand_total'], bold: true);

    final method = '${order['payment_method'] ?? ''}';
    if (method == 'cash') {
      totalRow('Tunai', order['cash_received']);
      totalRow('Kembali', order['change_amount']);
    } else if (method.isNotEmpty) {
      line('Pembayaran: ${method.toUpperCase()}');
    }

    if (order['voided'] == true) {
      out.addAll(gen.hr());
      line('*** NOTA DITANDAI SALAH ***', align: PosAlign.center, bold: true);
    }

    out.addAll(gen.hr());
    if ('${store['footer'] ?? ''}'.isNotEmpty) {
      line('${store['footer']}', align: PosAlign.center);
    }
    line('Powered by Mooda', align: PosAlign.center);
    out.addAll(gen.feed(2));
    out.addAll(gen.cut());

    return out;
  }

  /// Struk uji untuk memastikan printer benar-benar tersambung.
  static Future<List<int>> buildTestReceipt() async {
    final profile = await CapabilityProfile.load();
    final mm = await paperWidth();
    final gen = Generator(mm == 80 ? PaperSize.mm80 : PaperSize.mm58, profile);

    return [
      ...gen.text(
        'MOODA POS',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ),
      ...gen.text('Tes cetak berhasil',
          styles: const PosStyles(align: PosAlign.center)),
      ...gen.hr(),
      ...gen.text('Lebar kertas: $mm mm'),
      ...gen.text('1234567890 ABCDEFGHIJ'),
      ...gen.feed(2),
      ...gen.cut(),
    ];
  }

  static String _rp(dynamic v) {
    final n = (v is num) ? v : (num.tryParse('$v') ?? 0);
    final s = n.round().abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }

    return '${n < 0 ? '-' : ''}$buf';
  }

  static String _fmtTime(dynamic raw) {
    final d = DateTime.tryParse('$raw')?.toLocal();
    if (d == null) return '';
    String p(int v) => v.toString().padLeft(2, '0');

    return '${p(d.day)}/${p(d.month)}/${d.year} ${p(d.hour)}:${p(d.minute)}';
  }
}
