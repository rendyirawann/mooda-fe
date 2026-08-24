import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme.dart';
import 'clay.dart';

/// Kaki daftar berhalaman: keterangan jumlah + tombol muat halaman berikutnya.
///
/// Daftar tetap memuat otomatis saat digulir ke bawah, tapi kontrol ini dibuat
/// TERLIHAT supaya pengguna tahu masih ada data lain dan bisa memuatnya sendiri
/// (mis. ketika daftar belum cukup panjang untuk digulir).
class PagingFooter extends StatelessWidget {
  const PagingFooter({
    super.key,
    required this.shown,
    required this.total,
    required this.hasMore,
    required this.loading,
    required this.onLoadMore,
  });

  /// Jumlah item yang sedang tampil.
  final int shown;

  /// Total item menurut server (0 bila server belum mengirimnya).
  final int total;

  final bool hasMore;
  final bool loading;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    // Tak ada halaman lain & jumlahnya sedikit -> tak perlu menampilkan apa pun.
    if (!hasMore && !loading && (total == 0 || shown >= total) && shown < 10) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
      child: Column(
        children: [
          Text(
            total > 0 ? 'Menampilkan $shown dari $total' : 'Menampilkan $shown',
            style: const TextStyle(
                color: MoodaTheme.muted, fontSize: 11.5, fontWeight: FontWeight.w600),
          ),
          if (hasMore) ...[
            const SizedBox(height: 10),
            ClayButton(
              label: loading ? 'Memuat...' : 'Muat lebih banyak',
              icon: LucideIcons.chevronDown,
              height: 44,
              color: MoodaTheme.bg,
              textColor: MoodaTheme.primary,
              loading: loading,
              onPressed: loading ? null : onLoadMore,
            ),
          ],
        ],
      ),
    );
  }
}
