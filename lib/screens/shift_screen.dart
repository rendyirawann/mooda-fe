import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../services/fnb_service.dart';
import '../widgets/clay.dart';
import '../widgets/module_scaffold.dart';

/// Shift kasir: buka, pantau kas, tutup (rekonsiliasi laci).
class ShiftScreen extends StatefulWidget {
  const ShiftScreen({super.key});

  @override
  State<ShiftScreen> createState() => _ShiftScreenState();
}

class _ShiftScreenState extends State<ShiftScreen> {
  Map<String, dynamic>? _shift;
  bool _loading = true;
  String? _error;
  bool _busy = false;

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
      final s = await FnbService.currentShift();
      if (mounted) setState(() => _shift = s);
    } catch (e) {
      if (mounted) setState(() => _error = ApiClient.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double _num(String k) => ((_shift?[k] ?? 0) as num).toDouble();

  Future<void> _ask({
    required String title,
    required String label,
    required Future<void> Function(double) action,
  }) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lanjut'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    final value = double.tryParse(ctrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    setState(() => _busy = true);
    try {
      await action(value);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(ApiClient.errorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModuleScaffold(
      title: 'Shift',
      onRefresh: _load,
      child: _loading || _error != null
          ? ModuleState(loading: _loading, error: _error, onRetry: _load)
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
              children: _shift == null ? _closed() : _open(),
            ),
    );
  }

  List<Widget> _closed() => [
        ClayBox(
          radius: MoodaTheme.radiusLg,
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              const ClayIconBadge(
                icon: LucideIcons.clock,
                color: MoodaTheme.primary,
                size: 60,
              ),
              const SizedBox(height: 16),
              const Text(
                'Belum ada shift terbuka',
                style: TextStyle(
                    fontWeight: FontWeight.w800, color: MoodaTheme.ink, fontSize: 16),
              ),
              const SizedBox(height: 6),
              const Text(
                'Buka shift dulu agar penjualan tercatat ke laci kasir.',
                textAlign: TextAlign.center,
                style: TextStyle(color: MoodaTheme.muted, fontSize: 12.5),
              ),
              const SizedBox(height: 20),
              ClayButton(
                label: 'Buka shift',
                icon: LucideIcons.lockOpen,
                loading: _busy,
                onPressed: _busy
                    ? null
                    : () => _ask(
                          title: 'Buka shift',
                          label: 'Modal laci (Rp)',
                          action: FnbService.openShift,
                        ),
              ),
            ],
          ),
        ),
      ];

  List<Widget> _open() {
    final expected = _num('expected_cash');

    return [
      ClayBox(
        radius: MoodaTheme.radiusLg,
        gradient: MoodaTheme.clayPrimary,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Uang seharusnya di laci',
                style: TextStyle(color: Colors.white70, fontSize: 12.5)),
            const SizedBox(height: 4),
            Text(
              Rupiah.format(expected),
              style: const TextStyle(
                  color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'modal + tunai − pengeluaran (QRIS tidak masuk laci)',
              style: TextStyle(color: Colors.white70, fontSize: 10.5),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      ClayBox(
        radius: MoodaTheme.radiusLg,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _row('Modal laci', _num('starting_cash')),
            _row('Penjualan tunai', _num('cash_sales')),
            _row('Penjualan QRIS', _num('qris_sales')),
            _row('Pengeluaran', _num('expense_total')),
            const Divider(height: 22),
            _row('Seharusnya', expected, strong: true),
            const SizedBox(height: 10),
            Text(
              'Dibuka: ${_shift?['start_time'] ?? '-'}',
              style: const TextStyle(color: MoodaTheme.muted, fontSize: 11),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      ClayButton(
        label: 'Tutup shift',
        icon: LucideIcons.lock,
        loading: _busy,
        onPressed: _busy
            ? null
            : () => _ask(
                  title: 'Tutup shift',
                  label: 'Uang fisik di laci (Rp)',
                  action: FnbService.closeShift,
                ),
      ),
      const SizedBox(height: 10),
      const Text(
        'Shift tidak bisa ditutup bila masih ada pesanan belum lunas atau belum selesai.',
        textAlign: TextAlign.center,
        style: TextStyle(color: MoodaTheme.muted, fontSize: 11.5),
      ),
    ];
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
