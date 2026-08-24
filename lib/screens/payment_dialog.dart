import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../services/fnb_service.dart';
import '../services/kasir_service.dart';
import '../services/printer_service.dart';
import '../widgets/clay.dart';

/// Alur pembayaran: tinjau keranjang -> buat pesanan -> bayar -> struk.
///
/// Muncul dari TENGAH layar (bukan menempel di bawah) supaya tombol aksinya
/// tidak pernah tertutup tombol navigasi Android.
Future<bool?> showPaymentDialog(BuildContext context, List<CartLine> cart) {
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (_) => _PaymentDialog(cart: cart),
  );
}

enum _Step { review, pay, done }

class _PaymentDialog extends StatefulWidget {
  const _PaymentDialog({required this.cart});

  final List<CartLine> cart;

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  _Step _step = _Step.review;
  bool _busy = false;
  bool _printing = false;
  String? _error;

  final _customer = TextEditingController();
  final _cash = TextEditingController();
  String _method = 'cash';

  /// Meja DIPILIH dari daftar (sama seperti kasir web), bukan diketik.
  List<Map<String, dynamic>> _tables = [];
  String? _table;
  bool _tablesLoading = true;

  OrderResult? _order;

  late final String _txnId =
      'mob-${DateTime.now().millisecondsSinceEpoch}-${widget.cart.length}';

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  @override
  void dispose() {
    _customer.dispose();
    _cash.dispose();
    super.dispose();
  }

  Future<void> _loadTables() async {
    try {
      final t = await FnbService.tables();
      if (mounted) setState(() => _tables = t);
    } catch (_) {
      // Meja bersifat opsional — kegagalan memuatnya tidak menghalangi transaksi.
    } finally {
      if (mounted) setState(() => _tablesLoading = false);
    }
  }

  double get _preview => widget.cart.fold(0, (a, l) => a + l.preview);

  /// Buat pesanan. [payNow] false = simpan saja (belum lunas), tutup dialog.
  Future<void> _createOrder({bool payNow = true}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await KasirService.createOrder(
        cart: widget.cart,
        clientTxnId: _txnId,
        customerName: _customer.text.trim(),
        tableNo: _table,
      );
      if (!mounted) return;

      if (!payNow) {
        // Pesanan tersimpan & masuk antrean dapur; pembayaran menyusul.
        Navigator.of(context).pop(true);
        return;
      }

      setState(() {
        _order = res;
        _step = _Step.pay;
      });
    } catch (e) {
      if (mounted) setState(() => _error = ApiClient.errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pay() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await KasirService.pay(
        orderId: _order!.id,
        method: _method,
        cashReceived: _method == 'cash' ? _cashValue : null,
      );
      if (!mounted) return;
      setState(() {
        _order = res;
        _step = _Step.done;
      });
    } catch (e) {
      if (mounted) setState(() => _error = ApiClient.errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  double get _cashValue =>
      double.tryParse(_cash.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxH = media.size.height -
        media.viewInsets.bottom -
        media.padding.vertical -
        70;

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom * 0.5),
      child: Center(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 460,
                maxHeight: maxH < 300 ? 300 : maxH,
              ),
              child: ClayBox(
                radius: 28,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(),
                    const SizedBox(height: 14),
                    Flexible(
                      child: SingleChildScrollView(
                        child: switch (_step) {
                          _Step.review => _review(),
                          _Step.pay => _payStep(),
                          _Step.done => _done(),
                        },
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      _errorBox(),
                    ],
                    const SizedBox(height: 14),
                    _primaryAction(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final (title, sub) = switch (_step) {
      _Step.review => ('Keranjang', '${widget.cart.length} jenis menu'),
      _Step.pay => ('Pembayaran', 'Antrian #${_order?.queueNumber} · ${_order?.invoiceNo}'),
      _Step.done => ('Pembayaran berhasil', 'Antrian #${_order?.queueNumber}'),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800, color: MoodaTheme.ink)),
              const SizedBox(height: 2),
              Text(sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: MoodaTheme.muted, fontSize: 11.5)),
            ],
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(_step == _Step.done),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: MoodaTheme.bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.x, size: 17, color: MoodaTheme.muted),
          ),
        ),
      ],
    );
  }

  Widget _primaryAction() => switch (_step) {
        // Membuat pesanan TIDAK memaksa memilih tunai/QRIS: boleh disimpan dulu
        // (dikirim ke dapur) lalu dibayar kapan pun dari daftar Pesanan.
        _Step.review => Column(
            children: [
              ClayButton(
                label: 'Buat & bayar',
                icon: LucideIcons.creditCard,
                loading: _busy,
                onPressed: _busy || widget.cart.isEmpty ? null : _createOrder,
              ),
              const SizedBox(height: 10),
              ClayButton(
                label: 'Simpan dulu (bayar nanti)',
                icon: LucideIcons.save,
                color: MoodaTheme.bg,
                textColor: MoodaTheme.primary,
                height: 48,
                onPressed:
                    _busy || widget.cart.isEmpty ? null : () => _createOrder(payNow: false),
              ),
            ],
          ),
        _Step.pay => ClayButton(
            label: 'Bayar sekarang',
            icon: LucideIcons.check,
            loading: _busy,
            onPressed: (_busy || !_enough) ? null : _pay,
          ),
        _Step.done => Column(
            children: [
              ClayButton(
                label: 'Cetak struk',
                icon: LucideIcons.printer,
                loading: _printing,
                onPressed: _printing ? null : _printReceipt,
              ),
              const SizedBox(height: 10),
              ClayButton(
                label: 'Selesai',
                icon: LucideIcons.checkCheck,
                color: MoodaTheme.bg,
                textColor: MoodaTheme.muted,
                height: 48,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
      };

  /// Cetak struk ke printer yang dipilih di Pengaturan (Bluetooth/BLE/RawBT).
  Future<void> _printReceipt() async {
    final id = _order?.id;
    if (id == null) return;

    setState(() => _printing = true);
    try {
      final payload = await SettingsService.receipt(id);
      final bytes = await PrinterService.buildReceipt(payload);
      await PrinterService.printBytes(bytes);
      if (mounted) setState(() => _error = null);
    } on PrinterException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = ApiClient.errorMessage(e));
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  bool get _enough =>
      _method == 'qris' || _cashValue >= (_order?.grandTotal ?? double.infinity);

  Widget _errorBox() => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xFFFFECEC),
          borderRadius: BorderRadius.circular(MoodaTheme.radiusSm),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.circleAlert, color: MoodaTheme.danger, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(_error!,
                  style: const TextStyle(
                      color: MoodaTheme.danger,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  // ---------- 1. Tinjau ----------
  Widget _review() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in widget.cart) _cartRow(line),
        const SizedBox(height: 14),
        TextField(
          controller: _customer,
          decoration: const InputDecoration(labelText: 'Nama pelanggan (opsional)'),
        ),
        const SizedBox(height: 14),
        const Text('Meja',
            style: TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w700, color: MoodaTheme.ink)),
        const SizedBox(height: 8),
        _tablePicker(),
        const SizedBox(height: 16),
        _totalRow('Perkiraan', _preview, hint: 'pajak & promo dihitung server'),
      ],
    );
  }

  /// Pilih meja dari daftar `dining_tables` — meja terisi ditandai & tak bisa dipilih.
  Widget _tablePicker() {
    if (_tablesLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('Memuat meja...',
            style: TextStyle(color: MoodaTheme.muted, fontSize: 12)),
      );
    }
    if (_tables.isEmpty) {
      return const Text('Belum ada meja terdaftar (boleh dilewati).',
          style: TextStyle(color: MoodaTheme.muted, fontSize: 12));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _tableChip(label: 'Tanpa meja', value: null, busy: false),
        for (final t in _tables)
          _tableChip(
            label: '${t['name']}',
            value: '${t['name']}',
            busy: t['status'] == 'occupied',
          ),
      ],
    );
  }

  Widget _tableChip({required String label, required String? value, required bool busy}) {
    final active = _table == value;
    return GestureDetector(
      onTap: busy ? null : () => setState(() => _table = value),
      child: Opacity(
        opacity: busy ? 0.45 : 1,
        child: ClayBox(
          radius: 100,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          color: active ? MoodaTheme.primary : null,
          blur: 12,
          child: Text(
            busy ? '$label · terisi' : label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : MoodaTheme.ink,
            ),
          ),
        ),
      ),
    );
  }

  Widget _cartRow(CartLine line) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(line.menu.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: MoodaTheme.ink,
                          fontSize: 13.5)),
                  Text(Rupiah.format(line.menu.price),
                      style: const TextStyle(color: MoodaTheme.muted, fontSize: 11.5)),
                ],
              ),
            ),
            _qtyBtn(LucideIcons.minus, () {
              setState(() {
                if (line.qty > 1) {
                  line.qty--;
                } else {
                  widget.cart.remove(line);
                  if (widget.cart.isEmpty) Navigator.of(context).pop(false);
                }
              });
            }),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('${line.qty}', style: MoodaTheme.number(size: 14)),
            ),
            _qtyBtn(LucideIcons.plus, () => setState(() => line.qty++)),
          ],
        ),
      );

  Widget _qtyBtn(IconData icon, VoidCallback onTap) => ClayTappable(
        onTap: onTap,
        radius: 100,
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 15, color: MoodaTheme.ink),
      );

  // ---------- 2. Bayar ----------
  Widget _payStep() {
    final o = _order!;
    final cash = _cashValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _totalRow('Subtotal', o.subtotal),
        _totalRow('Pajak', o.tax),
        const SizedBox(height: 6),
        _totalRow('Total', o.grandTotal, strong: true),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _methodBtn('cash', 'Tunai', LucideIcons.banknote)),
            const SizedBox(width: 10),
            Expanded(child: _methodBtn('qris', 'QRIS', LucideIcons.qrCode)),
          ],
        ),
        if (_method == 'cash') ...[
          const SizedBox(height: 14),
          TextField(
            controller: _cash,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Uang diterima'),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final v in _quickCash(o.grandTotal))
                GestureDetector(
                  onTap: () => setState(() => _cash.text = v.toStringAsFixed(0)),
                  child: ClayBox(
                    radius: 100,
                    blur: 12,
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                    child: Text(Rupiah.format(v),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: MoodaTheme.primary)),
                  ),
                ),
            ],
          ),
          if (cash > 0) ...[
            const SizedBox(height: 12),
            _totalRow(_enough ? 'Kembalian' : 'Masih kurang',
                (cash - o.grandTotal).abs()),
          ],
        ],
      ],
    );
  }

  List<double> _quickCash(double total) {
    final out = <double>{total};
    for (final step in [5000, 10000, 20000, 50000, 100000]) {
      out.add((total / step).ceil() * step.toDouble());
    }
    final list = out.toList()..sort();
    return list.take(4).toList();
  }

  Widget _methodBtn(String value, String label, IconData icon) {
    final active = _method == value;
    return GestureDetector(
      onTap: () => setState(() => _method = value),
      child: ClayBox(
        radius: MoodaTheme.radius,
        color: active ? MoodaTheme.primary : null,
        padding: const EdgeInsets.symmetric(vertical: 14),
        blur: 14,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: active ? Colors.white : MoodaTheme.ink),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : MoodaTheme.ink)),
          ],
        ),
      ),
    );
  }

  // ---------- 3. Struk ----------
  Widget _done() {
    final o = _order!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              color: Color(0xFFE7F8EE),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.check, color: MoodaTheme.success, size: 32),
          ),
        ),
        const SizedBox(height: 16),
        _totalRow('Subtotal', o.subtotal),
        _totalRow('Pajak', o.tax),
        _totalRow('Total', o.grandTotal, strong: true),
        if (o.changeAmount > 0) _totalRow('Kembalian', o.changeAmount),
        if (o.stockWarnings.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E6),
              borderRadius: BorderRadius.circular(MoodaTheme.radiusSm),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Peringatan stok',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF9A6700),
                        fontSize: 12.5)),
                const SizedBox(height: 4),
                for (final w in o.stockWarnings)
                  Text('• $w',
                      style: const TextStyle(color: Color(0xFF9A6700), fontSize: 11.5)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _totalRow(String label, double value, {bool strong = false, String? hint}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                        color: strong ? MoodaTheme.ink : MoodaTheme.muted,
                        fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
                        fontSize: strong ? 14.5 : 13,
                      )),
                  if (hint != null)
                    Text(hint,
                        style: const TextStyle(color: MoodaTheme.muted, fontSize: 10.5)),
                ],
              ),
            ),
            Text(Rupiah.format(value),
                style: MoodaTheme.number(size: strong ? 18 : 14)),
          ],
        ),
      );
}
