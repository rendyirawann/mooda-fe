import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/permissions.dart';
import '../core/theme.dart';
import '../widgets/clay.dart';
import '../widgets/decor.dart';

/// Layar status & permintaan izin aplikasi (lokasi, kamera, media).
class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final Map<AppPermission, bool> _granted = {};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    for (final p in AppPermission.values) {
      _granted[p] = await Permissions.isGranted(p);
    }
    if (mounted) setState(() {});
  }

  Future<void> _ask(AppPermission p) async {
    setState(() => _busy = true);
    final ok = await Permissions.request(p);
    if (!ok && await Permissions.isPermanentlyDenied(p) && mounted) {
      final go = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Izin ditolak permanen'),
          content: const Text(
            'Aktifkan izin ini dari Setelan aplikasi agar fitur bisa dipakai.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Nanti'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Buka Setelan'),
            ),
          ],
        ),
      );
      if (go == true) await Permissions.openSettings();
    }
    if (mounted) setState(() => _busy = false);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    const items = <(AppPermission, String, String, IconData, Color)>[
      (
        AppPermission.lokasi,
        'Lokasi',
        'Penandaan lokasi outlet & absensi kasir',
        LucideIcons.mapPin,
        Color(0xFF10B981),
      ),
      (
        AppPermission.kamera,
        'Kamera',
        'Ambil foto menu/produk & pemindaian',
        LucideIcons.camera,
        Color(0xFF3070F0),
      ),
      (
        AppPermission.media,
        'Media & Galeri',
        'Pilih gambar dari galeri perangkat',
        LucideIcons.images,
        Color(0xFF8B5CF6),
      ),
    ];

    return Scaffold(
      body: ClayBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 26),
            children: [
              Row(
                children: [
                  ClayTappable(
                    onTap: () => Navigator.of(context).maybePop(),
                    radius: 100,
                    padding: const EdgeInsets.all(13),
                    child: const Icon(LucideIcons.arrowLeft,
                        size: 20, color: MoodaTheme.ink),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Izin Aplikasi',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: MoodaTheme.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              for (final (perm, title, desc, icon, color) in items) ...[
                ClayBox(
                  radius: MoodaTheme.radius,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      ClayIconBadge(icon: icon, color: color, size: 46),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: MoodaTheme.ink,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              desc,
                              style: const TextStyle(
                                  color: MoodaTheme.muted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (_granted[perm] == true)
                        const Icon(LucideIcons.circleCheck,
                            color: MoodaTheme.success, size: 28)
                      else
                        ClayTappable(
                          onTap: _busy ? null : () => _ask(perm),
                          radius: 100,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          child: const Text(
                            'Izinkan',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: MoodaTheme.primary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Izin diminta hanya saat dibutuhkan. Menolak izin tidak '
                  'menghalangi pemakaian fitur kasir yang tidak memerlukannya.',
                  style: TextStyle(color: MoodaTheme.muted, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
