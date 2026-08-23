import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../services/kasir_service.dart';
import '../widgets/clay.dart';

/// Alur: tinjau keranjang -> buat pesanan (server hitung total) -> bayar -> struk.
class PaymentSheet extends StatefulWidget {
  const PaymentSheet({super.key, required this.cart});

  final List<CartLine> cart;

  @override
  State<PaymentSheet> createState() => _PaymentSheetState();
}

enum _Step { review, pay, done }

class _PaymentSheetState extends State<PaymentSheet> {
  _Step _step = _Step.review;
  bool _busy = false;
  String? _error;

  final _customer = TextEditingController();
  final _table = TextEditingController();
  final _cash = TextEditingController();
  String _method = 'cash';

  OrderResult? _order;

  /// Kunci idempotensi: satu checkout = satu kunci, aman diulang saat jaringan putus.
  late final String _txnId =
      'mob-${DateTime.now().millisecondsSinceEpoch}-${widget.cart.length}';

  @override
  void dispose() {
    _customer.dispose();
    _table.dispose();
    _cash.dispose();
    super.dispose();
  }

  double get _preview => widget.cart.fold(0, (a, l) => a + l.preview);

  Future<void> _createOrder() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await KasirService.createOrder(
        cart: widget.cart,
        clientTxnId: _txnId,
        customerName: _customer.text.trim(),
        tableNo: _table.text.trim(),
      );
      if (!mounted) return;
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
    final order = _order!;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await KasirService.pay(
        orderId: order.id,
        method: _method,
        cashReceived: _method == 'cash'
            ? double.tryParse(_cash.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0
            : null,
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 14,
        right: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 14,
        top: 40,
      ),
      child: ClayBox(
        radius: MoodaTheme.radiusLg,
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(
          child: switch (_step) {
            _Step.review => _review(),
            _Step.pay => _payStep(),
            _Step.done => _done(),
          },
        ),
      ),
    );
  }

  Widget _header(String title, String subtitle) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: MoodaTheme.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: MoodaTheme.muted, fontSize: 12)),
          const SizedBox(height: 16),
        ],
      );

  Widget _errorBox() {
    if (_error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: ClayBox(
        radius: MoodaTheme.radiusSm,
        color: const Color(0xFFFDECEC),
        blur: 10,
        padding: const EdgeInsets.all(13),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: MoodaTheme.danger, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _error!,
                style: const TextStyle(
                    color: MoodaTheme.danger, fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- 1. Tinjau keranjang ----------
  Widget _review() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header('Keranjang', '${widget.cart.length} jenis menu'),
        for (final line in widget.cart) _cartRow(line),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customer,
                decoration: const InputDecoration(labelText: 'Nama pelanggan (opsional)'),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 110,
              child: TextField(
                controller: _table,
                decoration: const InputDecoration(labelText: 'Meja'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _totalRow('Perkiraan', _preview, hint: 'total pasti dihitung server'),
        _errorBox(),
        const SizedBox(height: 18),
        ClayButton(
          label: 'Buat pesanan',
          icon: Icons.receipt_long_rounded,
          loading: _busy,
          onPressed: _busy ? null : _createOrder,
        ),
      ],
    );
  }

  Widget _cartRow(CartLine line) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.menu.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: MoodaTheme.ink, fontSize: 14),
                ),
                Text(
                  Rupiah.format(line.menu.price),
                  style: const TextStyle(color: MoodaTheme.muted, fontSize: 11.5),
                ),
              ],
            ),
          ),
          _qtyBtn(Icons.remove_rounded, () {
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
            child: Text(
              '${line.qty}',
              style: const TextStyle(fontWeight: FontWeight.w800, color: MoodaTheme.ink),
            ),
          ),
          _qtyBtn(Icons.add_rounded, () => setState(() => line.qty++)),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) => ClayTappable(
        onTap: onTap,
        radius: 100,
        padding: const EdgeInsets.all(9),
        child: Icon(icon, size: 17, color: MoodaTheme.ink),
      );

  // ---------- 2. Bayar ----------
  Widget _payStep() {
    final o = _order!;
    final cash = double.tryParse(_cash.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final enough = _method == 'qris' || cash >= o.grandTotal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header('Pembayaran', 'Antrian #${o.queueNumber} · ${o.invoiceNo}'),
        _totalRow('Subtotal', o.subtotal),
        _totalRow('Pajak', o.tax),
        const SizedBox(height: 6),
        _totalRow('Total', o.grandTotal, strong: true),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: _methodBtn('cash', 'Tunai', Icons.payments_rounded)),
            const SizedBox(width: 10),
            Expanded(child: _methodBtn('qris', 'QRIS', Icons.qr_code_rounded)),
          ],
        ),
        if (_method == 'cash') ...[
          const SizedBox(height: 16),
          TextField(
            controller: _cash,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Uang diterima',
              prefixIcon: Icon(Icons.attach_money_rounded),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final v in _quickCash(o.grandTotal))
                ClayTappable(
                  onTap: () => setState(() => _cash.text = v.toStringAsFixed(0)),
                  radius: 100,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  child: Text(
                    Rupiah.format(v),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: MoodaTheme.primary),
                  ),
                ),
            ],
          ),
          if (cash > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _totalRow(
                enough ? 'Kembalian' : 'Kurang',
                (cash - o.grandTotal).abs(),
              ),
            ),
        ],
        _errorBox(),
        const SizedBox(height: 18),
        ClayButton(
          label: 'Bayar sekarang',
          icon: Icons.check_rounded,
          loading: _busy,
          onPressed: (_busy || !enough) ? null : _pay,
        ),
      ],
    );
  }

  /// Nominal cepat: pembulatan ke atas yang lazim dipakai kasir.
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
    return ClayTappable(
      onTap: () => setState(() => _method = value),
      gradient: active ? MoodaTheme.clayPrimary : null,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: active ? Colors.white : MoodaTheme.ink),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : MoodaTheme.ink,
            ),
          ),
        ],
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
            width: 66,
            height: 66,
            decoration: const BoxDecoration(
              color: Color(0xFFE7F8F1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: MoodaTheme.success, size: 36),
          ),
        ),
        const SizedBox(height: 14),
        const Center(
          child: Text(
            'Pembayaran berhasil',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: MoodaTheme.ink),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'Antrian #${o.queueNumber} · ${o.invoiceNo}',
            style: const TextStyle(color: MoodaTheme.muted, fontSize: 12),
          ),
        ),
        const SizedBox(height: 18),
        _totalRow('Subtotal', o.subtotal),
        _totalRow('Pajak', o.tax),
        _totalRow('Total', o.grandTotal, strong: true),
        if (o.changeAmount > 0) _totalRow('Kembalian', o.changeAmount),
        if (o.stockWarnings.isNotEmpty) ...[
          const SizedBox(height: 14),
          ClayBox(
            radius: MoodaTheme.radiusSm,
            color: const Color(0xFFFFF6E5),
            blur: 10,
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Peringatan stok',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: Color(0xFF9A6700), fontSize: 13),
                ),
                const SizedBox(height: 4),
                for (final w in o.stockWarnings)
                  Text('• $w',
                      style: const TextStyle(color: Color(0xFF9A6700), fontSize: 12)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        ClayButton(
          label: 'Selesai',
          icon: Icons.done_all_rounded,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }

  Widget _totalRow(String label, double value, {bool strong = false, String? hint}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: strong ? MoodaTheme.ink : MoodaTheme.muted,
                    fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
                    fontSize: strong ? 15 : 13,
                  ),
                ),
                if (hint != null)
                  Text(hint,
                      style: const TextStyle(color: MoodaTheme.muted, fontSize: 10.5)),
              ],
            ),
          ),
          Text(
            Rupiah.format(value),
            style: TextStyle(
              color: MoodaTheme.ink,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w700,
              fontSize: strong ? 17 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
