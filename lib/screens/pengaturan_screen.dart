import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api_client.dart';
import '../core/motion.dart';
import '../core/permissions.dart';
import '../core/theme.dart';
import '../services/fnb_service.dart';
import '../services/printer_service.dart';
import '../widgets/clay.dart';
import '../widgets/clay_dialog.dart';
import '../widgets/feedback.dart';
import '../widgets/module_scaffold.dart';
import 'permissions_screen.dart';

/// Pengaturan: identitas toko, pajak, teks struk, **printer thermal**, izin.
class PengaturanScreen extends StatefulWidget {
  const PengaturanScreen({super.key});

  @override
  State<PengaturanScreen> createState() => _PengaturanScreenState();
}

class _PengaturanScreenState extends State<PengaturanScreen> {
  Map<String, dynamic>? _settings;
  SavedPrinter? _printer;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = await SettingsService.get();
      final p = await PrinterService.saved();
      // Lebar kertas dari server dipakai juga oleh penyusun struk lokal.
      await PrinterService.setPaperWidth(((s['paper_width'] ?? 58) as num).toInt());
      if (mounted) {
        setState(() {
          _settings = s;
          _printer = p;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = ApiClient.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _canEditStore => _settings?['can_edit_store'] == true;

  Future<void> _saveSettings(Map<String, dynamic> payload) async {
    setState(() => _busy = true);
    try {
      await SettingsService.save(payload);
      if (mounted) Notify.toast(context, 'Pengaturan tersimpan.');
      await _load();
    } catch (e) {
      if (mounted) Notify.toast(context, ApiClient.errorMessage(e), success: false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ------------------------------------------------------------------ printer
  /// Pilih printer: daftar Bluetooth terpasang + hasil pindai BLE + jalur RawBT.
  Future<void> _pickPrinter() async {
    // Izin TIDAK diminta di sini: daftar Bluetooth terpasang & pilihan RawBT
    // (USB) tak memerlukannya. Izin diminta tepat saat menekan "Pindai".
    await showClayDialog<void>(
      context: context,
      title: 'Pilih printer',
      subtitle: 'Bluetooth thermal, BLE, atau lewat RawBT (USB/OTG)',
      content: _PrinterPicker(
        onPicked: (device) async {
          await PrinterService.save(SavedPrinter(
            name: device.name,
            address: device.address,
            kind: device.kind,
          ));
          if (mounted) {
            Navigator.of(context).pop();
            Notify.toast(context, 'Printer "${device.name}" dipilih.');
            _load();
          }
        },
      ),
    );
  }

  Future<void> _testPrint() async {
    setState(() => _busy = true);
    try {
      final bytes = await PrinterService.buildTestReceipt();
      await PrinterService.printBytes(bytes);
      if (mounted) Notify.toast(context, 'Perintah cetak terkirim.');
    } on PrinterException catch (e) {
      if (mounted) Notify.toast(context, e.message, success: false);
    } catch (e) {
      if (mounted) Notify.toast(context, 'Gagal mencetak: $e', success: false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgetPrinter() async {
    await PrinterService.forget();
    if (!mounted) return;
    Notify.toast(context, 'Printer dilepas.');
    _load();
  }

  // -------------------------------------------------------------------- build
  @override
  Widget build(BuildContext context) {
    return ModuleScaffold(
      title: 'Pengaturan',
      onRefresh: _load,
      child: (_loading || _error != null)
          ? ModuleState(loading: _loading, error: _error, onRetry: _load)
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
              children: [
                FadeSlideIn(child: _printerCard()),
                const SizedBox(height: 14),
                FadeSlideIn(index: 1, child: _storeCard()),
                const SizedBox(height: 14),
                FadeSlideIn(index: 2, child: _receiptCard()),
                const SizedBox(height: 14),
                FadeSlideIn(index: 3, child: _permissionCard()),
              ],
            ),
    );
  }

  Widget _printerCard() {
    final p = _printer;

    return ClayBox(
      radius: MoodaTheme.radiusLg,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const ClayIconBadge(
                  icon: LucideIcons.printer, color: MoodaTheme.primary, size: 44),
              const SizedBox(width: 13),
              const Expanded(
                child: Text('Printer Struk',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800, color: MoodaTheme.ink)),
              ),
              if (p != null) ClayTag(text: _kindLabel(p.kind), fontSize: 10),
            ],
          ),
          const SizedBox(height: 14),
          if (p == null)
            const Text(
              'Belum ada printer terpilih. Untuk printer Bluetooth, pasangkan dulu '
              'di Setelan Bluetooth Android. Printer USB/OTG dicetak lewat aplikasi RawBT.',
              style: TextStyle(color: MoodaTheme.muted, fontSize: 12.5, height: 1.45),
            )
          else ...[
            Text(p.name,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: MoodaTheme.ink, fontSize: 14)),
            Text(
              p.kind == PrinterKind.rawbt ? 'via aplikasi RawBT' : p.address,
              style: const TextStyle(color: MoodaTheme.muted, fontSize: 11.5),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClayButton(
                  label: p == null ? 'Pilih printer' : 'Ganti',
                  icon: LucideIcons.bluetooth,
                  height: 48,
                  onPressed: _busy ? null : _pickPrinter,
                ),
              ),
              if (p != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: ClayButton(
                    label: 'Tes cetak',
                    icon: LucideIcons.receiptText,
                    color: MoodaTheme.bg,
                    textColor: MoodaTheme.primary,
                    height: 48,
                    loading: _busy,
                    onPressed: _busy ? null : _testPrint,
                  ),
                ),
              ],
            ],
          ),
          if (p != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _forgetPrinter,
              child: const Text(
                'Lepas printer',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: MoodaTheme.danger, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          const Text('Lebar kertas',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: MoodaTheme.ink)),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final mm in [58, 80]) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: _busy ? null : () => _saveSettings({'paper_width': mm}),
                    child: ClayBox(
                      radius: MoodaTheme.radius,
                      blur: 12,
                      color: ((_settings?['paper_width'] ?? 58) as num).toInt() == mm
                          ? MoodaTheme.primary
                          : null,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          '$mm mm',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: ((_settings?['paper_width'] ?? 58) as num).toInt() == mm
                                ? Colors.white
                                : MoodaTheme.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (mm == 58) const SizedBox(width: 10),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _storeCard() {
    return ClayBox(
      radius: MoodaTheme.radiusLg,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Identitas Toko',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800, color: MoodaTheme.ink)),
          const SizedBox(height: 12),
          _readRow('Nama toko', '${_settings?['store_name'] ?? '-'}'),
          _readRow('Alamat', '${_settings?['address'] ?? '-'}'),
          _readRow('Telepon', '${_settings?['phone'] ?? '-'}'),
          _readRow('Pajak', '${_settings?['tax_rate'] ?? 0}%'),
          const SizedBox(height: 14),
          if (_canEditStore)
            ClayButton(
              label: 'Ubah identitas & pajak',
              icon: LucideIcons.pencil,
              height: 48,
              onPressed: _busy ? null : _editStoreDialog,
            )
          else
            const Text(
              'Hanya pemilik yang boleh mengubah identitas toko & pajak.',
              style: TextStyle(color: MoodaTheme.muted, fontSize: 11.5),
            ),
        ],
      ),
    );
  }

  Future<void> _editStoreDialog() async {
    final name = TextEditingController(text: '${_settings?['store_name'] ?? ''}');
    final address = TextEditingController(text: '${_settings?['address'] ?? ''}');
    final phone = TextEditingController(text: '${_settings?['phone'] ?? ''}');
    final tax = TextEditingController(text: '${_settings?['tax_rate'] ?? 0}');

    final ok = await showClayFormDialog(
      context: context,
      title: 'Identitas toko',
      subtitle: 'Tampil di kop struk',
      fields: [
        TextField(
          controller: name,
          decoration: const InputDecoration(labelText: 'Nama toko'),
        ),
        TextField(
          controller: address,
          decoration: const InputDecoration(labelText: 'Alamat'),
        ),
        TextField(
          controller: phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Telepon'),
        ),
        TextField(
          controller: tax,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Pajak (%)'),
        ),
      ],
    );

    if (ok != true) return;

    await _saveSettings({
      'store_name': name.text.trim(),
      'address': address.text.trim(),
      'phone': phone.text.trim(),
      'tax_rate': int.tryParse(tax.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
    });
  }

  Widget _receiptCard() {
    return ClayBox(
      radius: MoodaTheme.radiusLg,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Teks Struk',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800, color: MoodaTheme.ink)),
          const SizedBox(height: 12),
          _readRow('Kop', '${_settings?['receipt_header'] ?? '-'}'),
          _readRow('Kaki', '${_settings?['receipt_footer'] ?? '-'}'),
          _readRow('Tampilkan alamat',
              _settings?['receipt_show_address'] == true ? 'Ya' : 'Tidak'),
          _readRow('Tampilkan telepon',
              _settings?['receipt_show_phone'] == true ? 'Ya' : 'Tidak'),
          const SizedBox(height: 14),
          if (_canEditStore)
            ClayButton(
              label: 'Ubah teks struk',
              icon: LucideIcons.pencil,
              height: 48,
              onPressed: _busy ? null : _editReceiptDialog,
            ),
        ],
      ),
    );
  }

  Future<void> _editReceiptDialog() async {
    final header = TextEditingController(text: '${_settings?['receipt_header'] ?? ''}');
    final footer = TextEditingController(text: '${_settings?['receipt_footer'] ?? ''}');

    final ok = await showClayFormDialog(
      context: context,
      title: 'Teks struk',
      fields: [
        TextField(
          controller: header,
          decoration: const InputDecoration(labelText: 'Kop struk'),
        ),
        TextField(
          controller: footer,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Kaki struk'),
        ),
      ],
    );

    if (ok != true) return;

    await _saveSettings({
      'receipt_header': header.text.trim(),
      'receipt_footer': footer.text.trim(),
    });
  }

  Widget _permissionCard() => ClayTappable(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PermissionsScreen()),
        ),
        padding: const EdgeInsets.all(16),
        child: const Row(
          children: [
            ClayIconBadge(
                icon: LucideIcons.shieldCheck, color: Color(0xFF64748B), size: 42),
            SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Izin Aplikasi',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: MoodaTheme.ink,
                          fontSize: 14)),
                  Text('Lokasi, kamera, media, Bluetooth',
                      style: TextStyle(color: MoodaTheme.muted, fontSize: 11.5)),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: MoodaTheme.muted, size: 20),
          ],
        ),
      );

  Widget _readRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(label,
                  style: const TextStyle(color: MoodaTheme.muted, fontSize: 12.5)),
            ),
            Expanded(
              child: Text(
                value.isEmpty ? '-' : value,
                style: const TextStyle(
                    color: MoodaTheme.ink, fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );

  String _kindLabel(PrinterKind k) => switch (k) {
        PrinterKind.classic => 'BLUETOOTH',
        PrinterKind.ble => 'BLE',
        PrinterKind.rawbt => 'RAWBT/USB',
      };
}

/// Daftar pilihan printer: Bluetooth terpasang, hasil pindai BLE, dan RawBT.
class _PrinterPicker extends StatefulWidget {
  const _PrinterPicker({required this.onPicked});

  final Future<void> Function(PrinterDevice) onPicked;

  @override
  State<_PrinterPicker> createState() => _PrinterPickerState();
}

class _PrinterPickerState extends State<_PrinterPicker> {
  List<PrinterDevice> _paired = [];
  List<PrinterDevice> _ble = [];
  bool _loading = true;
  bool _scanning = false;
  String? _scanNote;

  @override
  void initState() {
    super.initState();
    _loadPaired();
  }

  Future<void> _loadPaired() async {
    final list = await PrinterService.pairedClassic();
    if (mounted) {
      setState(() {
        _paired = list;
        _loading = false;
      });
    }
  }

  /// Pindai BLE. Izin diminta DI SINI (tepat sebelum memindai) dan setiap
  /// kegagalan dijelaskan, supaya tombol tidak pernah terasa "tidak bereaksi".
  Future<void> _scanBle() async {
    setState(() {
      _scanning = true;
      _scanNote = null;
    });

    final granted = await Permissions.request(AppPermission.bluetooth);
    if (!granted) {
      final permanent = await Permissions.isPermanentlyDenied(AppPermission.bluetooth);
      if (mounted) {
        setState(() {
          _scanning = false;
          _scanNote = permanent
              ? 'Izin Bluetooth ditolak permanen. Aktifkan dari Setelan aplikasi.'
              : 'Izin Bluetooth diperlukan untuk memindai printer.';
        });
      }

      return;
    }

    // Bluetooth mati -> minta sistem menyalakannya (Android memunculkan dialog),
    // supaya pengguna tak perlu keluar aplikasi dulu.
    if (!await PrinterService.bluetoothOn()) {
      final on = await PrinterService.enableBluetooth();
      if (!on) {
        if (mounted) {
          setState(() {
            _scanning = false;
            _scanNote = 'Bluetooth masih mati. Nyalakan Bluetooth lalu pindai lagi.';
          });
        }

        return;
      }
    }

    final res = await PrinterService.scanBle();
    if (mounted) {
      setState(() {
        _ble = res.devices;
        _scanNote = res.error;
        _scanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Bluetooth terpasang',
            style: TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w800, color: MoodaTheme.ink)),
        const SizedBox(height: 8),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text('Memuat...',
                style: TextStyle(color: MoodaTheme.muted, fontSize: 12)),
          )
        else if (_paired.isEmpty)
          const Text(
            'Belum ada printer terpasang. Pasangkan printer di Setelan Bluetooth '
            'Android, lalu buka lagi daftar ini.',
            style: TextStyle(color: MoodaTheme.muted, fontSize: 12),
          )
        else
          for (final d in _paired) _row(d),

        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(
              child: Text('Printer BLE',
                  style: TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w800, color: MoodaTheme.ink)),
            ),
            // Tombol dengan area sentuh yang layak (sebelumnya hanya selebar teks,
            // sehingga sering tidak kena saat ditekan).
            ClayTappable(
              onTap: _scanning ? null : _scanBle,
              radius: 100,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_scanning)
                    const SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: MoodaTheme.primary),
                    )
                  else
                    const Icon(LucideIcons.radar, size: 15, color: MoodaTheme.primary),
                  const SizedBox(width: 7),
                  Text(
                    _scanning ? 'Memindai...' : 'Pindai',
                    style: const TextStyle(
                        color: MoodaTheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_ble.isNotEmpty)
          for (final d in _ble) _row(d)
        else
          Text(
            _scanning
                ? 'Mencari printer di sekitar (±6 detik)...'
                : (_scanNote ??
                    'Tekan "Pindai" untuk mencari printer BLE di sekitar.'),
            style: TextStyle(
              color: _scanNote != null && !_scanning
                  ? const Color(0xFF9A6700)
                  : MoodaTheme.muted,
              fontSize: 12,
            ),
          ),
        if (_scanNote != null && !_scanning) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: Permissions.openSettings,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Buka Setelan aplikasi',
                style: TextStyle(
                    color: MoodaTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],

        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 12),
        _row(const PrinterDevice(
          name: 'Cetak lewat RawBT',
          address: 'rawbt',
          kind: PrinterKind.rawbt,
        )),
        const SizedBox(height: 6),
        const Text(
          'Pilih ini untuk printer USB/OTG atau merek yang tidak terdeteksi. '
          'Aplikasi RawBT harus terpasang.',
          style: TextStyle(color: MoodaTheme.muted, fontSize: 11),
        ),
      ],
    );
  }

  Widget _row(PrinterDevice d) {
    final icon = switch (d.kind) {
      PrinterKind.classic => LucideIcons.bluetooth,
      PrinterKind.ble => LucideIcons.radio,
      PrinterKind.rawbt => LucideIcons.usb,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClayTappable(
        onTap: () => widget.onPicked(d),
        radius: MoodaTheme.radius,
        padding: const EdgeInsets.all(13),
        child: Row(
          children: [
            Icon(icon, size: 18, color: MoodaTheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: MoodaTheme.ink,
                          fontSize: 13)),
                  if (d.kind != PrinterKind.rawbt)
                    Text(d.address,
                        style: const TextStyle(color: MoodaTheme.muted, fontSize: 10.5)),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, size: 18, color: MoodaTheme.muted),
          ],
        ),
      ),
    );
  }
}
