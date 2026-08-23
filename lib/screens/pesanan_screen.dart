import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../services/fnb_service.dart';
import '../widgets/clay.dart';
import '../widgets/module_scaffold.dart';

/// Riwayat pesanan + detail nota.
class PesananScreen extends StatefulWidget {
  const PesananScreen({super.key});

  @override
  State<PesananScreen> createState() => _PesananScreenState();
}

class _PesananScreenState extends State<PesananScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String? _error;
  String? _filter; // null = semua

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
      final data = await FnbService.orders(paymentStatus: _filter);
      if (mounted) setState(() => _orders = data);
    } catch (e) {
      if (mounted) setState(() => _error = ApiClient.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openDetail(int id) async {
    try {
      final o = await FnbService.order(id);
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _detailSheet(o),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(ApiClient.errorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModuleScaffold(
      title: 'Pesanan',
      onRefresh: _load,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                for (final (v, label) in [
                  (null, 'Semua'),
                  ('unpaid', 'Belum lunas'),
                  ('paid', 'Lunas'),
                ]) ...[
                  Expanded(
                    child: ClayTappable(
                      onTap: () {
                        setState(() => _filter = v);
                        _load();
                      },
                      gradient: _filter == v ? MoodaTheme.clayPrimary : null,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _filter == v ? Colors.white : MoodaTheme.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (label != 'Lunas') const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: (_loading || _error != null || _orders.isEmpty)
                ? ModuleState(
                    loading: _loading,
                    error: _error,
                    emptyText: 'Belum ada pesanan',
                    onRetry: _load,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                    itemCount: _orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _card(_orders[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _card(Map<String, dynamic> o) {
    final paid = o['payment_status'] == 'paid';

    return ClayTappable(
      onTap: () => _openDetail((o['id'] as num).toInt()),
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: (paid ? MoodaTheme.success : const Color(0xFFF97316))
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              '#${o['queue_number']}',
              style: TextStyle(
                color: paid ? MoodaTheme.success : const Color(0xFFF97316),
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${o['customer_name'] ?? 'Pelanggan'}'
                  '${o['table_no'] != null ? ' · ${o['table_no']}' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: MoodaTheme.ink, fontSize: 14),
                ),
                Text(
                  '${o['invoice_no']} · ${paid ? (o['payment_method'] ?? 'lunas') : 'belum lunas'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: MoodaTheme.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            Rupiah.format(((o['grand_total'] ?? 0) as num).toDouble()),
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: MoodaTheme.ink, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _detailSheet(Map<String, dynamic> o) {
    final items = (o['items'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 60, 14, 14),
      child: ClayBox(
        radius: MoodaTheme.radiusLg,
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Antrian #${o['queue_number']}',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: MoodaTheme.ink),
              ),
              Text(
                '${o['invoice_no']}',
                style: const TextStyle(color: MoodaTheme.muted, fontSize: 11.5),
              ),
              const SizedBox(height: 16),
              for (final it in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${it['qty']}x ${it['menu'] ?? '-'}',
                          style: const TextStyle(fontSize: 13, color: MoodaTheme.ink),
                        ),
                      ),
                      Text(
                        Rupiah.format(((it['subtotal'] ?? 0) as num).toDouble()),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600, color: MoodaTheme.ink),
                      ),
                    ],
                  ),
                ),
              const Divider(height: 22),
              _row('Subtotal', ((o['subtotal'] ?? 0) as num).toDouble()),
              _row('Pajak', ((o['tax'] ?? 0) as num).toDouble()),
              _row('Total', ((o['grand_total'] ?? 0) as num).toDouble(), strong: true),
              const SizedBox(height: 18),
              ClayButton(
                label: 'Tutup',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, double v, {bool strong = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: strong ? MoodaTheme.ink : MoodaTheme.muted,
                  fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              Rupiah.format(v),
              style: TextStyle(
                color: MoodaTheme.ink,
                fontWeight: strong ? FontWeight.w800 : FontWeight.w700,
                fontSize: strong ? 15.5 : 13.5,
              ),
            ),
          ],
        ),
      );
}
