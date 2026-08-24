import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';

/// Antrean pesanan yang dibuat saat jaringan mati.
///
/// Kasir tidak boleh berhenti hanya karena internet putus: pesanan disimpan di
/// perangkat, lalu dikirim ke `POST /fnb/orders/sync-offline` begitu jaringan
/// pulih. Setiap pesanan membawa `client_txn_id` sendiri, sehingga sinkron
/// berulang tidak pernah membuat nota dobel.
class OfflineQueue {
  OfflineQueue._();

  static const _key = 'mooda_offline_orders';

  static Future<List<Map<String, dynamic>>> all() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_key) ?? const [];

    return raw
        .map((s) {
          try {
            return Map<String, dynamic>.from(jsonDecode(s) as Map);
          } catch (_) {
            return <String, dynamic>{};
          }
        })
        .where((m) => m.isNotEmpty)
        .toList();
  }

  static Future<int> count() async => (await all()).length;

  static Future<void> add(Map<String, dynamic> order) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_key) ?? <String>[];
    raw.add(jsonEncode(order));
    await p.setStringList(_key, raw);
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }

  /// Buang pesanan tertentu (dipakai bila pengguna menghapusnya dari antrean).
  static Future<void> remove(String clientTxnId) async {
    final p = await SharedPreferences.getInstance();
    final rest = (await all())
        .where((o) => o['client_txn_id'] != clientTxnId)
        .map(jsonEncode)
        .toList();
    await p.setStringList(_key, rest);
  }

  /// Kirim seluruh antrean. Mengembalikan jumlah yang masuk & dilewati.
  ///
  /// Antrean hanya dibersihkan bila server menjawab sukses — kalau gagal
  /// (mis. saldo deposit kurang), data tetap tersimpan agar tidak hilang.
  static Future<({int saved, int skipped})> sync() async {
    final pending = await all();
    if (pending.isEmpty) return (saved: 0, skipped: 0);

    final res = await ApiClient.dio.post(
      '/fnb/orders/sync-offline',
      data: {'orders': pending},
    );

    final data = Map<String, dynamic>.from((res.data['data'] ?? const {}) as Map);
    await clear();

    return (
      saved: ((data['saved'] ?? 0) as num).toInt(),
      skipped: ((data['skipped'] ?? 0) as num).toInt(),
    );
  }
}
