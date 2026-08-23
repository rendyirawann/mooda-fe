import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../services/fnb_service.dart';
import '../widgets/clay.dart';
import '../widgets/module_scaffold.dart';

/// Laporan penjualan + dashboard HPP. Semua angka datang dari server.
class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key, this.focusHpp = false});

  /// Buka langsung pada bagian HPP (dipakai tile "HPP" di dashboard).
  final bool focusHpp;

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  Map<String, dynamic>? _sales;
  Map<String, dynamic>? _hpp;
  bool _loading = true;
  String? _error;
  int _days = 0; // 0 = hari ini, 6 = 7 hari, 29 = 30 hari

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
      final now = DateTime.now();
      final from = now.subtract(Duration(days: _days));
      final f = _fmt(from);
      final t = _fmt(now);

      final sales = await FnbService.sales(from: f, to: t);
      final hpp = await FnbService.hpp(from: f, to: t);
      if (mounted) {
        setState(() {
          _sales = sales;
          _hpp = hpp;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = ApiClient.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  double _num(Map<String, dynamic>? m, String k) => ((m?[k] ?? 0) as num).toDouble();

  @override
  Widget build(BuildContext context) {
    return ModuleScaffold(
      title: widget.focusHpp ? 'HPP' : 'Laporan',
      onRefresh: _load,
      child: (_loading || _error != null)
          ? ModuleState(loading: _loading, error: _error, onRetry: _load)
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
              children: [
                _periodPicker(),
                const SizedBox(height: 16),
                _salesCard(),
                const SizedBox(height: 14),
                _hppCard(),
                const SizedBox(height: 14),
                _perMenu(),
              ],
            ),
    );
  }

  Widget _periodPicker() {
    const opts = [(0, 'Hari ini'), (6, '7 hari'), (29, '30 hari')];
    return Row(
      children: [
        for (final (d, label) in opts) ...[
          Expanded(
            child: ClayTappable(
              onTap: () {
                setState(() => _days = d);
                _load();
              },
              gradient: _days == d ? MoodaTheme.clayPrimary : null,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: _days == d ? Colors.white : MoodaTheme.ink,
                  ),
                ),
              ),
            ),
          ),
          if (d != 29) const SizedBox(width: 10),
        ],
      ],
    );
  }

  Widget _salesCard() {
    final revenue = _num(_sales, 'revenue');
    final orders = _num(_sales, 'orders').toInt();
    final voided = (_sales?['voided'] as Map?) ?? const {};
    final method = (_sales?['by_method'] as Map?) ?? const {};

    return ClayBox(
      radius: MoodaTheme.radiusLg,
      gradient: MoodaTheme.clayPrimary,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Omzet', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
          const SizedBox(height: 4),
          Text(
            Rupiah.format(revenue),
            style: const TextStyle(
                color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _mini('Transaksi', '$orders'),
              _mini('Rata-rata', Rupiah.format(_num(_sales, 'avg_ticket'))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _mini('Tunai', Rupiah.format(((method['cash'] ?? 0) as num).toDouble())),
              _mini('QRIS', Rupiah.format(((method['qris'] ?? 0) as num).toDouble())),
            ],
          ),
          if (((voided['orders'] ?? 0) as num).toInt() > 0) ...[
            const SizedBox(height: 12),
            Text(
              'Dibatalkan: ${voided['orders']} nota '
              '(${Rupiah.format(((voided['amount'] ?? 0) as num).toDouble())}) '
              '— tidak dihitung ke omzet',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _mini(String label, String value) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            Text(
              value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ],
        ),
      );

  Widget _hppCard() {
    final revenue = _num(_hpp, 'revenue');
    final hpp = _num(_hpp, 'hpp');
    final foodCost = _hpp?['food_cost_pct'];
    final margin = _hpp?['margin_pct'];

    return ClayBox(
      radius: MoodaTheme.radiusLg,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Harga Pokok Penjualan',
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: MoodaTheme.ink, fontSize: 15)),
          const SizedBox(height: 12),
          _row('Penjualan (tanpa pajak)', Rupiah.format(revenue)),
          _row('HPP bahan', Rupiah.format(hpp)),
          _row('Laba kotor', Rupiah.format(_num(_hpp, 'gross_profit')), strong: true),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _stat('Food cost',
                    foodCost == null ? '-' : '${foodCost.toString()}%', const Color(0xFFF97316)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _stat('Margin',
                    margin == null ? '-' : '${margin.toString()}%', MoodaTheme.success),
              ),
            ],
          ),
          if (hpp == 0 && revenue > 0)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'HPP masih 0 — resep menu belum diisi atau modul Inventory & HPP '
                'belum aktif pada paket toko ini.',
                style: TextStyle(color: MoodaTheme.muted, fontSize: 11.5),
              ),
            ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(MoodaTheme.radiusSm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 11.5)),
            Text(
              value,
              style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
      );

  Widget _perMenu() {
    final rows = (_hpp?['per_menu'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    if (rows.isEmpty) {
      return const ClayBox(
        child: Text(
          'Belum ada penjualan pada periode ini.',
          style: TextStyle(color: MoodaTheme.muted, fontSize: 12.5),
        ),
      );
    }

    return ClayBox(
      radius: MoodaTheme.radiusLg,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Per menu (food cost tertinggi dulu)',
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: MoodaTheme.ink, fontSize: 14)),
          const SizedBox(height: 12),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${r['menu']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: MoodaTheme.ink,
                              fontSize: 13.5),
                        ),
                        Text(
                          'terjual ${r['qty']} · HPP ${Rupiah.format(((r['hpp'] ?? 0) as num).toDouble())}',
                          style: const TextStyle(color: MoodaTheme.muted, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    r['food_cost_pct'] == null ? '-' : '${r['food_cost_pct']}%',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: MoodaTheme.ink, fontSize: 13.5),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool strong = false}) => Padding(
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
              value,
              style: TextStyle(
                color: MoodaTheme.ink,
                fontWeight: strong ? FontWeight.w800 : FontWeight.w700,
                fontSize: strong ? 15 : 13.5,
              ),
            ),
          ],
        ),
      );
}
