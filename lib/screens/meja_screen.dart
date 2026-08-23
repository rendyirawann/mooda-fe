import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../services/fnb_service.dart';
import '../widgets/clay.dart';
import '../widgets/module_scaffold.dart';

/// Meja + status terisi (dihitung server dari pesanan aktif).
class MejaScreen extends StatefulWidget {
  const MejaScreen({super.key});

  @override
  State<MejaScreen> createState() => _MejaScreenState();
}

class _MejaScreenState extends State<MejaScreen> {
  List<Map<String, dynamic>> _tables = [];
  bool _loading = true;
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
      final data = await FnbService.tables();
      if (mounted) setState(() => _tables = data);
    } catch (e) {
      if (mounted) setState(() => _error = ApiClient.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addDialog() async {
    final name = TextEditingController();
    final area = TextEditingController();
    final cap = TextEditingController(text: '4');

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tambah meja'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nama meja (mis. A4)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: area,
              decoration: const InputDecoration(labelText: 'Area (opsional)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: cap,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Kapasitas'),
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

    if (ok != true || name.text.trim().isEmpty) return;

    try {
      await FnbService.addTable(
        name.text.trim(),
        area: area.text.trim(),
        capacity: int.tryParse(cap.text),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(ApiClient.errorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final occupied = _tables.where((t) => t['status'] == 'occupied').length;

    return ModuleScaffold(
      title: 'Meja',
      onRefresh: _load,
      actions: [
        ClayTappable(
          onTap: _addDialog,
          radius: 100,
          padding: const EdgeInsets.all(13),
          child: const Icon(Icons.add_rounded, size: 20, color: MoodaTheme.ink),
        ),
      ],
      child: (_loading || _error != null || _tables.isEmpty)
          ? ModuleState(
              loading: _loading,
              error: _error,
              emptyText: 'Belum ada meja. Tambah dengan tombol +',
              onRetry: _load,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
              children: [
                ClayBox(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$occupied dari ${_tables.length} meja terisi',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, color: MoodaTheme.ink),
                        ),
                      ),
                      const Icon(Icons.table_restaurant_rounded,
                          color: MoodaTheme.primary),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _tables.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (_, i) {
                    final t = _tables[i];
                    final busy = t['status'] == 'occupied';
                    final color = busy ? const Color(0xFFF97316) : MoodaTheme.success;

                    return ClayBox(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClayIconBadge(
                            icon: busy
                                ? Icons.no_food_rounded
                                : Icons.table_restaurant_rounded,
                            color: color,
                            size: 42,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${t['name']}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: MoodaTheme.ink,
                                fontSize: 13),
                          ),
                          Text(
                            busy ? 'Terisi' : 'Kosong',
                            style: TextStyle(color: color, fontSize: 11),
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
}
