import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../services/fnb_service.dart';
import '../widgets/clay.dart';
import '../widgets/module_scaffold.dart';

/// Bahan & stok: daftar (stok = jumlah sisa semua lot), kartu stok per bahan,
/// serta pencatatan stok masuk/keluar.
class StokScreen extends StatefulWidget {
  const StokScreen({super.key});

  @override
  State<StokScreen> createState() => _StokScreenState();
}

class _StokScreenState extends State<StokScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _onlyLow = false;
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
      final data = await FnbService.ingredients(low: _onlyLow);
      if (mounted) setState(() => _items = data);
    } catch (e) {
      if (mounted) setState(() => _error = ApiClient.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openCard(Map<String, dynamic> ing) async {
    try {
      final card = await FnbService.ingredientCard((ing['id'] as num).toInt());
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _cardSheet(card),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(ApiClient.errorMessage(e))));
    }
  }

  /// Form stok masuk/keluar. `in` butuh total pembelian (harga satuan dihitung server).
  Future<void> _movementDialog(Map<String, dynamic> ing, String type) async {
    final qty = TextEditingController();
    final total = TextEditingController();
    final reason = TextEditingController(text: 'waste');

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${type == 'in' ? 'Stok masuk' : 'Stok keluar'} — ${ing['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qty,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'Jumlah (${ing['unit']})'),
            ),
            const SizedBox(height: 10),
            if (type == 'in')
              TextField(
                controller: total,
                keyboardType: TextInputType.number,
                inputFormatters: const [RupiahInputFormatter()],
                decoration: const InputDecoration(labelText: 'Total pembelian (Rp)'),
              )
            else
              TextField(
                controller: reason,
                decoration: const InputDecoration(labelText: 'Alasan (waste/rusak/koreksi)'),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    final q = double.tryParse(qty.text.replaceAll(',', '.')) ?? 0;
    if (q <= 0) return;

    try {
      final res = await FnbService.movement(
        ingredientId: (ing['id'] as num).toInt(),
        type: type,
        quantity: q,
        buyPriceTotal:
            type == 'in' ? double.tryParse(total.text.replaceAll(RegExp(r'[^0-9]'), '')) : null,
        reason: type == 'out' ? reason.text.trim() : null,
      );

      final warnings = ((res['meta'] as Map?)?['stock_warnings'] as List?) ?? const [];
      if (mounted && warnings.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tercatat, tapi stok tidak mencukupi sebagian.')),
        );
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(ApiClient.errorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModuleScaffold(
      title: 'Bahan & Stok',
      onRefresh: _load,
      actions: [
        ClayTappable(
          onTap: () {
            setState(() => _onlyLow = !_onlyLow);
            _load();
          },
          radius: 100,
          gradient: _onlyLow ? MoodaTheme.clayPrimary : null,
          padding: const EdgeInsets.all(13),
          child: Icon(
            LucideIcons.triangleAlert,
            size: 20,
            color: _onlyLow ? Colors.white : MoodaTheme.ink,
          ),
        ),
      ],
      child: (_loading || _error != null || _items.isEmpty)
          ? ModuleState(
              loading: _loading,
              error: _error,
              emptyText: _onlyLow
                  ? 'Tidak ada bahan di bawah stok minimum'
                  : 'Belum ada bahan',
              onRetry: _load,
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final it = _items[i];
                final low = it['low'] == true;

                return ClayTappable(
                  onTap: () => _openCard(it),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      ClayIconBadge(
                        icon: low ? LucideIcons.triangleAlert : LucideIcons.boxes,
                        color: low ? const Color(0xFFF97316) : const Color(0xFF06B6D4),
                        size: 44,
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${it['name']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: MoodaTheme.ink,
                                  fontSize: 14),
                            ),
                            Text(
                              'Sisa ${it['stock']} ${it['unit']} · min ${it['minimum_stock']}',
                              style: TextStyle(
                                color: low ? const Color(0xFFF97316) : MoodaTheme.muted,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ClayTappable(
                        onTap: () => _movementDialog(it, 'in'),
                        radius: 100,
                        padding: const EdgeInsets.all(9),
                        child: const Icon(LucideIcons.plus,
                            size: 17, color: MoodaTheme.success),
                      ),
                      const SizedBox(width: 6),
                      ClayTappable(
                        onTap: () => _movementDialog(it, 'out'),
                        radius: 100,
                        padding: const EdgeInsets.all(9),
                        child: const Icon(LucideIcons.minus,
                            size: 17, color: MoodaTheme.danger),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _cardSheet(Map<String, dynamic> card) {
    final ing = Map<String, dynamic>.from(card['ingredient'] as Map);
    final batches = (card['batches'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final movements = (card['movements'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 50, 14, 14),
      child: ClayBox(
        radius: MoodaTheme.radiusLg,
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${ing['name']}',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: MoodaTheme.ink),
              ),
              Text(
                'Sisa ${ing['stock']} ${ing['unit']}',
                style: const TextStyle(color: MoodaTheme.muted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              const Text('Lot (urutan pemakaian FEFO)',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              const SizedBox(height: 8),
              if (batches.isEmpty)
                const Text('Belum ada lot.',
                    style: TextStyle(color: MoodaTheme.muted, fontSize: 12))
              else
                for (final b in batches)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Lot #${b['id']} · sisa ${b['remaining']}'
                            '${b['expiry_date'] != null ? ' · exp ${b['expiry_date']}' : ''}',
                            style: const TextStyle(fontSize: 12, color: MoodaTheme.ink),
                          ),
                        ),
                        Text(
                          Rupiah.format(((b['buy_price'] ?? 0) as num).toDouble()),
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700, color: MoodaTheme.ink),
                        ),
                      ],
                    ),
                  ),
              const Divider(height: 22),
              const Text('Kartu stok terakhir',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              const SizedBox(height: 8),
              if (movements.isEmpty)
                const Text('Belum ada gerakan.',
                    style: TextStyle(color: MoodaTheme.muted, fontSize: 12))
              else
                for (final m in movements.take(15))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      children: [
                        Icon(
                          m['type'] == 'in'
                              ? LucideIcons.arrowDown
                              : LucideIcons.arrowUp,
                          size: 14,
                          color: m['type'] == 'in' ? MoodaTheme.success : MoodaTheme.danger,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${m['quantity']} · ${m['reason'] ?? '-'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11.5, color: MoodaTheme.ink),
                          ),
                        ),
                        Text(
                          Rupiah.format(((m['cost_total'] ?? 0) as num).toDouble()),
                          style: const TextStyle(fontSize: 11.5, color: MoodaTheme.muted),
                        ),
                      ],
                    ),
                  ),
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
}
