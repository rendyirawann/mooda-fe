import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../core/motion.dart';
import '../core/theme.dart';
import '../services/fnb_service.dart';
import '../widgets/clay.dart';
import '../widgets/clay_dialog.dart';
import '../widgets/feedback.dart';
import '../widgets/module_scaffold.dart';

/// Shift kasir: buka, pantau kas, tutup, dan **riwayat shift** (seperti web).
class ShiftScreen extends StatefulWidget {
  const ShiftScreen({super.key});

  @override
  State<ShiftScreen> createState() => _ShiftScreenState();
}

class _ShiftScreenState extends State<ShiftScreen> {
  Map<String, dynamic>? _shift;
  List<Map<String, dynamic>> _history = [];
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
      final h = await FnbService.shiftHistory();
      if (mounted) {
        setState(() {
          _shift = s;
          _history = h.where((e) => e['status'] == 'closed').toList();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = ApiClient.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double _num(Map<String, dynamic>? m, String k) => ((m?[k] ?? 0) as num).toDouble();

  /// Dialog angka (dari tengah layar) untuk buka/tutup shift.
  Future<void> _ask({
    required String title,
    required String subtitle,
    required String label,
    required String confirmLabel,
    required Future<void> Function(double) action,
    required String successMessage,
  }) async {
    final ctrl = TextEditingController();

    final ok = await showClayFormDialog(
      context: context,
      title: title,
      subtitle: subtitle,
      confirmLabel: confirmLabel,
      fields: [
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: const [RupiahInputFormatter()],
          autofocus: true,
          decoration: InputDecoration(labelText: label),
        ),
      ],
    );

    if (ok != true || !mounted) return;
    final value = double.tryParse(ctrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    setState(() => _busy = true);
    try {
      await action(value);
      if (mounted) Notify.toast(context, successMessage);
      await _load();
    } catch (e) {
      if (mounted) Notify.toast(context, ApiClient.errorMessage(e), success: false);
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
              children: [
                FadeSlideIn(child: _shift == null ? _closedCard() : _openCard()),
                const SizedBox(height: 20),
                FadeSlideIn(index: 1, child: _historySection()),
              ],
            ),
    );
  }

  Widget _closedCard() => ClayBox(
        radius: MoodaTheme.radiusLg,
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const ClayIconBadge(
                icon: LucideIcons.clock, color: MoodaTheme.primary, size: 58),
            const SizedBox(height: 16),
            const Text('Belum ada shift terbuka',
                style: TextStyle(
                    fontWeight: FontWeight.w800, color: MoodaTheme.ink, fontSize: 16)),
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
                        subtitle: 'Masukkan uang modal yang ada di laci.',
                        label: 'Modal laci (Rp)',
                        confirmLabel: 'Buka shift',
                        action: FnbService.openShift,
                        successMessage: 'Shift dibuka.',
                      ),
            ),
          ],
        ),
      );

  Widget _openCard() {
    final expected = _num(_shift, 'expected_cash');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClayBox(
          radius: MoodaTheme.radiusLg,
          gradient: MoodaTheme.primaryGradient,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Uang seharusnya di laci',
                  style: TextStyle(color: Colors.white70, fontSize: 12.5)),
              const SizedBox(height: 4),
              AnimatedNumber(
                value: expected,
                builder: (v) => Text(
                  Rupiah.format(v),
                  style: MoodaTheme.number(size: 26, color: Colors.white),
                ),
              ),
              const SizedBox(height: 6),
              const Text('modal + tunai − pengeluaran (QRIS tidak masuk laci)',
                  style: TextStyle(color: Colors.white70, fontSize: 10.5)),
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
              _row('Modal laci', _num(_shift, 'starting_cash')),
              _row('Penjualan tunai', _num(_shift, 'cash_sales')),
              _row('Penjualan QRIS', _num(_shift, 'qris_sales')),
              _row('Pengeluaran', _num(_shift, 'expense_total')),
              const Divider(height: 20),
              _row('Seharusnya', expected, strong: true),
              const SizedBox(height: 10),
              Text('Dibuka: ${_fmtTime(_shift?['start_time'])}',
                  style: const TextStyle(color: MoodaTheme.muted, fontSize: 11)),
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
                    subtitle: 'Hitung uang fisik di laci, lalu masukkan jumlahnya.',
                    label: 'Uang fisik di laci (Rp)',
                    confirmLabel: 'Tutup shift',
                    action: FnbService.closeShift,
                    successMessage: 'Shift ditutup.',
                  ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Shift tidak bisa ditutup bila masih ada pesanan belum lunas atau belum selesai.',
          textAlign: TextAlign.center,
          style: TextStyle(color: MoodaTheme.muted, fontSize: 11.5),
        ),
      ],
    );
  }

  Widget _historySection() {
    return ClayBox(
      radius: MoodaTheme.radiusLg,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Riwayat Shift',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800, color: MoodaTheme.ink)),
              ),
              ClayTag(text: '${_history.length}', fontSize: 10.5),
            ],
          ),
          const SizedBox(height: 14),
          if (_history.isEmpty)
            const Text('Belum ada shift yang ditutup.',
                style: TextStyle(color: MoodaTheme.muted, fontSize: 12.5))
          else
            for (var i = 0; i < _history.length; i++)
              FadeSlideIn(index: i, child: _historyRow(_history[i])),
        ],
      ),
    );
  }

  Widget _historyRow(Map<String, dynamic> s) {
    final diff = ((s['difference'] ?? 0) as num).toDouble();
    final (label, color) = diff == 0
        ? ('Pas', MoodaTheme.success)
        : diff > 0
            ? ('Lebih', const Color(0xFF0EA5E9))
            : ('Kurang', MoodaTheme.danger);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _showDetail(s),
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            ClayIconBadge(icon: LucideIcons.clock, color: color, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fmtTime(s['start_time']),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: MoodaTheme.ink,
                        fontSize: 12.5),
                  ),
                  Text(
                    '${s['kasir'] ?? '-'} · tunai ${Rupiah.format(((s['cash_sales'] ?? 0) as num).toDouble())}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: MoodaTheme.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(Rupiah.format(diff.abs()), style: MoodaTheme.number(size: 13)),
                Text(label,
                    style: TextStyle(
                        color: color, fontSize: 10.5, fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDetail(Map<String, dynamic> s) async {
    await showClayDialog<void>(
      context: context,
      title: 'Rincian shift',
      subtitle: '${s['kasir'] ?? '-'} · ${_fmtTime(s['start_time'])}',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _row('Modal laci', ((s['starting_cash'] ?? 0) as num).toDouble()),
          _row('Penjualan tunai', ((s['cash_sales'] ?? 0) as num).toDouble()),
          _row('Pengeluaran', ((s['expense_total'] ?? 0) as num).toDouble()),
          const Divider(height: 20),
          _row('Seharusnya', ((s['expected_cash'] ?? 0) as num).toDouble()),
          _row('Uang fisik', ((s['actual_cash'] ?? 0) as num).toDouble()),
          _row('Selisih', ((s['difference'] ?? 0) as num).toDouble(), strong: true),
          const SizedBox(height: 8),
          Text('Ditutup: ${_fmtTime(s['end_time'])}',
              style: const TextStyle(color: MoodaTheme.muted, fontSize: 11)),
        ],
      ),
    );
  }

  String _fmtTime(dynamic raw) {
    final d = DateTime.tryParse('$raw')?.toLocal();
    if (d == null) return '-';
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year} · $hh:$mi';
  }

  Widget _row(String label, double v, {bool strong = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                    color: strong ? MoodaTheme.ink : MoodaTheme.muted,
                    fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
                    fontSize: 13,
                  )),
            ),
            Text(Rupiah.format(v), style: MoodaTheme.number(size: strong ? 15.5 : 13.5)),
          ],
        ),
      );
}
