import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../services/fnb_service.dart';
import '../widgets/clay.dart';
import '../widgets/module_scaffold.dart';

/// Daftar menu; ketuk untuk melihat resep + estimasi HPP/margin dari server.
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<Map<String, dynamic>> _menus = [];
  bool _loading = true;
  String? _error;

  // Paginasi daftar menu.
  int _page = 1;
  bool _hasMore = false;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 1;
      _hasMore = false;
    });
    try {
      final r = await FnbService.menusPage(page: 1);
      if (mounted) {
        setState(() {
          _menus = r.items;
          _hasMore = r.hasMore;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = ApiClient.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Halaman menu berikutnya (dipanggil saat gulir mendekati bawah).
  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final r = await FnbService.menusPage(page: _page + 1);
      if (mounted) {
        setState(() {
          _menus = [..._menus, ...r.items];
          _page += 1;
          _hasMore = r.hasMore;
        });
      }
    } catch (_) {
      // gagal memuat tambahan tak perlu mengganggu daftar yang sudah tampil
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _openRecipe(Map<String, dynamic> m) async {
    try {
      final r = await FnbService.recipe((m['id'] as num).toInt());
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _recipeSheet(r),
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
      title: 'Menu & Resep',
      onRefresh: _load,
      child: (_loading || _error != null || _menus.isEmpty)
          ? ModuleState(
              loading: _loading,
              error: _error,
              emptyText: 'Belum ada menu',
              onRetry: _load,
            )
          : NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.metrics.pixels >= n.metrics.maxScrollExtent - 300) _loadMore();

                return false;
              },
              child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
              itemCount: _menus.length + (_loadingMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                if (i >= _menus.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2)),
                    ),
                  );
                }
                final m = _menus[i];
                final available = m['available'] == true;

                return ClayTappable(
                  onTap: () => _openRecipe(m),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const ClayIconBadge(
                        icon: LucideIcons.bookOpen,
                        color: Color(0xFF8B5CF6),
                        size: 44,
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${m['name']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: MoodaTheme.ink,
                                  fontSize: 14),
                            ),
                            Text(
                              '${m['category'] ?? '-'} · '
                              '${Rupiah.format(((m['final_price'] ?? m['price'] ?? 0) as num).toDouble())}'
                              '${available ? '' : ' · habis'}',
                              style: const TextStyle(color: MoodaTheme.muted, fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                      const Icon(LucideIcons.chevronRight, color: MoodaTheme.muted),
                    ],
                  ),
                );
              },
              ),
            ),
    );
  }

  Widget _recipeSheet(Map<String, dynamic> r) {
    final items = (r['ingredients'] as List? ?? const [])
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
                '${r['menu']}',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: MoodaTheme.ink),
              ),
              Text(
                'Harga jual ${Rupiah.format(((r['price'] ?? 0) as num).toDouble())}',
                style: const TextStyle(color: MoodaTheme.muted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                const Text(
                  'Resep belum diisi. Tanpa resep, HPP menu ini tidak bisa dihitung '
                  'dan stok bahan tidak berkurang saat terjual.',
                  style: TextStyle(color: MoodaTheme.muted, fontSize: 12.5),
                )
              else ...[
                const Text('Bahan per porsi',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                const SizedBox(height: 8),
                for (final it in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${it['name']} — ${it['quantity']} ${it['unit'] ?? ''}',
                            style: const TextStyle(fontSize: 12.5, color: MoodaTheme.ink),
                          ),
                        ),
                        Text(
                          Rupiah.format(((it['cost'] ?? 0) as num).toDouble()),
                          style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: MoodaTheme.ink),
                        ),
                      ],
                    ),
                  ),
                const Divider(height: 22),
                _row('Estimasi HPP', Rupiah.format(((r['hpp_estimate'] ?? 0) as num).toDouble())),
                _row('Margin', Rupiah.format(((r['margin'] ?? 0) as num).toDouble()),
                    strong: true),
                _row('Food cost',
                    r['food_cost_pct'] == null ? '-' : '${r['food_cost_pct']}%'),
                const SizedBox(height: 8),
                const Text(
                  'Estimasi memakai harga lot yang akan dipakai berikutnya (FEFO). '
                  'HPP penjualan yang tercatat memakai harga lot sesungguhnya.',
                  style: TextStyle(color: MoodaTheme.muted, fontSize: 10.5),
                ),
              ],
              const SizedBox(height: 18),
              ClayButton(
                  label: 'Tutup',
                  icon: LucideIcons.x,
                  onPressed: () => Navigator.of(context).pop()),
            ],
          ),
        ),
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
