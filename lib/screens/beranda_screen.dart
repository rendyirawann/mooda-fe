import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../services/fnb_service.dart';
import '../widgets/clay.dart';
import '../widgets/sparkline.dart';
import 'dapur_screen.dart';
import 'kasir_screen.dart';
import 'laporan_screen.dart';
import 'meja_screen.dart';
import 'menu_screen.dart';
import 'pesanan_screen.dart';
import 'shift_screen.dart';
import 'stok_screen.dart';

/// Beranda: ringkasan hari ini, menu cepat, tren 7 hari, transaksi terbaru.
class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key});

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  Map<String, dynamic>? _data;
  String _name = 'Pengguna';
  String? _tenant;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    Session.name().then((n) {
      if (n != null && n.isNotEmpty && mounted) setState(() => _name = n);
    });
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await FnbService.dashboard();
      String? tenant;
      try {
        tenant = (await FnbService.tenant())['name']?.toString();
      } catch (_) {
        // nama toko tidak wajib untuk halaman ini
      }
      if (mounted) {
        setState(() {
          _data = d;
          _tenant = tenant;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = ApiClient.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic> get _today =>
      Map<String, dynamic>.from((_data?['today'] ?? const {}) as Map);

  double _n(Map<String, dynamic> m, String k) => ((m[k] ?? 0) as num).toDouble();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
          children: [
            _header(),
            const SizedBox(height: 18),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              ClayBox(
                color: const Color(0xFFFFECEC),
                child: Column(
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: MoodaTheme.danger, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 14),
                    ClayButton(
                        label: 'Coba lagi', icon: LucideIcons.refreshCw, onPressed: _load),
                  ],
                ),
              )
            else ...[
              _heroSales(),
              const SizedBox(height: 14),
              _statRow(),
              const SizedBox(height: 18),
              _quickMenu(),
              const SizedBox(height: 18),
              _chart(),
              const SizedBox(height: 18),
              _recent(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _header() => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, $_name 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800, color: MoodaTheme.ink),
                ),
                if (_tenant != null)
                  Text(
                    _tenant!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: MoodaTheme.muted, fontSize: 12.5),
                  ),
              ],
            ),
          ),
          ClayTappable(
            onTap: _load,
            radius: 100,
            padding: const EdgeInsets.all(12),
            child: const Icon(LucideIcons.refreshCw, size: 18, color: MoodaTheme.ink),
          ),
        ],
      );

  Widget _heroSales() {
    final revenue = _n(_today, 'revenue');
    final growth = _data?['growth_pct'];
    final yesterday = _n(
        Map<String, dynamic>.from((_data?['yesterday'] ?? const {}) as Map), 'revenue');

    return ClayBox(
      gradient: MoodaTheme.primaryGradient,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Penjualan Hari Ini',
                    style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        Rupiah.format(revenue),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MoodaTheme.number(size: 27, color: Colors.white),
                      ),
                    ),
                    if (growth != null) ...[
                      const SizedBox(width: 8),
                      _growthTag((growth as num).toDouble()),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Dibandingkan kemarin ${Rupiah.format(yesterday)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                ),
              ],
            ),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24, width: 1.4),
            ),
            child: const Icon(LucideIcons.chartNoAxesColumn, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _growthTag(double pct) {
    final up = pct >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24, width: 1.2),
      ),
      child: Row(
        children: [
          Icon(up ? LucideIcons.trendingUp : LucideIcons.trendingDown,
              size: 12, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            '${pct.abs().toStringAsFixed(1)}%',
            style: const TextStyle(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _statRow() {
    final t = _today;
    final items = [
      ('Transaksi', '${_n(t, 'orders').toInt()}'),
      ('Item terjual', '${_n(t, 'items').toInt()}'),
      ('HPP', Rupiah.format(_n(t, 'hpp'))),
      ('Laba kotor', Rupiah.format(_n(t, 'profit'))),
    ];

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(
            child: ClayBox(
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
              radius: MoodaTheme.radius,
              child: Column(
                children: [
                  Text(
                    items[i].$1,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: MoodaTheme.muted, fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    child: Text(items[i].$2, style: MoodaTheme.number(size: 15)),
                  ),
                ],
              ),
            ),
          ),
          if (i < items.length - 1) const SizedBox(width: 9),
        ],
      ],
    );
  }

  Widget _quickMenu() {
    final quick = <(String, IconData, Color, Widget Function())>[
      ('Kasir', LucideIcons.shoppingCart, MoodaTheme.primary, () => const KasirScreen()),
      ('Dapur', LucideIcons.chefHat, const Color(0xFFF97316), () => const DapurScreen()),
      ('Stok', LucideIcons.boxes, const Color(0xFF06B6D4), () => const StokScreen()),
      ('Meja', LucideIcons.armchair, const Color(0xFF16A34A), () => const MejaScreen()),
      ('Laporan', LucideIcons.chartNoAxesColumn, const Color(0xFF2563EB), () => const LaporanScreen()),
      ('Menu', LucideIcons.bookOpen, const Color(0xFF8B5CF6), () => const MenuScreen()),
      ('Riwayat', LucideIcons.history, const Color(0xFFEC4899), () => const PesananScreen()),
      ('Shift', LucideIcons.clock, const Color(0xFF0EA5E9), () => const ShiftScreen()),
    ];

    return ClayBox(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Menu Cepat',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800, color: MoodaTheme.ink)),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: quick.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (_, i) {
              final (title, icon, color, builder) = quick[i];
              return GestureDetector(
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => builder())),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  children: [
                    ClayIconBadge(icon: icon, color: color, size: 44),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 10.5, fontWeight: FontWeight.w700, color: MoodaTheme.ink),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _chart() {
    final series = (_data?['series'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    return ClayBox(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text('Ringkasan Penjualan',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800, color: MoodaTheme.ink)),
              ),
              ClayTag(text: '7 HARI', fontSize: 10),
            ],
          ),
          const SizedBox(height: 14),
          const Text('Total penjualan',
              style: TextStyle(color: MoodaTheme.muted, fontSize: 11.5)),
          Text(
            Rupiah.format(((_data?['series_total'] ?? 0) as num).toDouble()),
            style: MoodaTheme.number(size: 22),
          ),
          const SizedBox(height: 14),
          Sparkline(
            values: series.map((e) => ((e['revenue'] ?? 0) as num).toDouble()).toList(),
            labels: series.map((e) => '${e['label']}').toList(),
          ),
        ],
      ),
    );
  }

  Widget _recent() {
    final rows = (_data?['recent_orders'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    return ClayBox(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Transaksi Terbaru',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800, color: MoodaTheme.ink)),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PesananScreen()),
                ),
                child: const Text('Lihat Semua',
                    style: TextStyle(
                        color: MoodaTheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            const Text('Belum ada transaksi lunas.',
                style: TextStyle(color: MoodaTheme.muted, fontSize: 12.5))
          else
            for (final r in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const ClayIconBadge(
                      icon: LucideIcons.receiptText,
                      color: MoodaTheme.primary,
                      size: 38,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${r['invoice_no']}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: MoodaTheme.ink,
                                fontSize: 12.5),
                          ),
                          Text(
                            _time(r['created_at']),
                            style: const TextStyle(color: MoodaTheme.muted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          Rupiah.format(((r['grand_total'] ?? 0) as num).toDouble()),
                          style: MoodaTheme.number(size: 13),
                        ),
                        Text(
                          '${r['payment_method'] ?? '-'}',
                          style: const TextStyle(
                              color: MoodaTheme.success,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  String _time(dynamic iso) {
    final d = DateTime.tryParse('$iso')?.toLocal();
    if (d == null) return '-';
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year} · $hh:$mi';
  }
}
