import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../services/fnb_service.dart';
import '../widgets/clay.dart';
import '../widgets/module_scaffold.dart';

/// Kitchen Display System: antrean pesanan + naikkan status item/pesanan.
class DapurScreen extends StatefulWidget {
  const DapurScreen({super.key});

  @override
  State<DapurScreen> createState() => _DapurScreenState();
}

class _DapurScreenState extends State<DapurScreen> {
  List<Map<String, dynamic>> _orders = [];
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
      final data = await FnbService.kitchenQueue();
      if (mounted) setState(() => _orders = data);
    } catch (e) {
      if (mounted) setState(() => _error = ApiClient.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.errorMessage(e))),
      );
    }
  }

  /// pending -> cooking -> done
  String _next(String status) => switch (status) {
        'pending' => 'cooking',
        'cooking' => 'done',
        _ => 'done',
      };

  Color _statusColor(String s) => switch (s) {
        'done' => MoodaTheme.success,
        'cooking' => const Color(0xFFF97316),
        _ => MoodaTheme.muted,
      };

  @override
  Widget build(BuildContext context) {
    return ModuleScaffold(
      title: 'Dapur',
      onRefresh: _load,
      child: (_loading || _error != null || _orders.isEmpty)
          ? ModuleState(
              loading: _loading,
              error: _error,
              emptyText: 'Tidak ada pesanan yang perlu dimasak',
              onRetry: _load,
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
              itemCount: _orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (_, i) => _orderCard(_orders[i]),
            ),
    );
  }

  Widget _orderCard(Map<String, dynamic> o) {
    final items = (o['items'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final orderId = (o['id'] as num).toInt();

    return ClayBox(
      radius: MoodaTheme.radiusLg,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  gradient: MoodaTheme.clayPrimary,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '#${o['queue_number']}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${o['customer_name'] ?? 'Pelanggan'}'
                      '${o['table_no'] != null ? ' · Meja ${o['table_no']}' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: MoodaTheme.ink, fontSize: 14),
                    ),
                    Text(
                      '${o['order_status']} · ${o['payment_status']}',
                      style: const TextStyle(color: MoodaTheme.muted, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final it in items) _itemRow(it),
          const SizedBox(height: 12),
          ClayButton(
            label: 'Semua siap disajikan',
            icon: Icons.room_service_rounded,
            onPressed: () => _run(() => FnbService.orderStatus(orderId, 'served')),
          ),
        ],
      ),
    );
  }

  Widget _itemRow(Map<String, dynamic> it) {
    final status = '${it['status']}';
    final id = (it['id'] as num).toInt();
    final done = status == 'done';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: _statusColor(status), shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${it['qty']}x ${it['menu'] ?? '-'}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    color: done ? MoodaTheme.muted : MoodaTheme.ink,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
                if ((it['notes'] ?? '').toString().isNotEmpty)
                  Text(
                    '“${it['notes']}”',
                    style: const TextStyle(color: Color(0xFFF97316), fontSize: 11.5),
                  ),
              ],
            ),
          ),
          if (!done)
            ClayTappable(
              onTap: () => _run(() => FnbService.itemStatus(id, _next(status))),
              radius: 100,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              child: Text(
                status == 'pending' ? 'Masak' : 'Selesai',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: MoodaTheme.primary),
              ),
            )
          else
            const Icon(Icons.check_circle_rounded, color: MoodaTheme.success, size: 22),
        ],
      ),
    );
  }
}
