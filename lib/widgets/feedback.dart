import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/motion.dart';
import '../core/theme.dart';
import 'clay.dart';

/// Umpan balik seragam: preloader menutupi layar, notifikasi berhasil/gagal,
/// dan dialog konfirmasi. Semuanya muncul dari tengah & beranimasi halus.
class Notify {
  Notify._();

  /// Preloader mengambang. Tutup dengan `Navigator.pop(context)`.
  static Future<void> showLoader(BuildContext context, String message) {
    return showAnimatedDialog<void>(
      context: context,
      dismissible: false,
      builder: (_) => Center(
        child: ClayBox(
          radius: 24,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                height: 34,
                width: 34,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: 14),
              Text(
                message,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: MoodaTheme.ink, fontSize: 13.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Notifikasi singkat bergaya clay (bukan SnackBar polos).
  static void toast(
    BuildContext context,
    String message, {
    bool success = true,
  }) {
    final color = success ? MoodaTheme.success : MoodaTheme.danger;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 2200),
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          padding: EdgeInsets.zero,
          content: ClayBox(
            radius: 18,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    success ? LucideIcons.check : LucideIcons.circleAlert,
                    color: color,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: MoodaTheme.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  /// Dialog konfirmasi (mis. sebelum keluar akun).
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Ya, lanjutkan',
    String cancelLabel = 'Batal',
    IconData icon = LucideIcons.circleHelp,
    Color color = MoodaTheme.primary,
  }) async {
    final res = await showAnimatedDialog<bool>(
      context: context,
      builder: (ctx) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ClayBox(
              radius: 26,
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: ClayIconBadge(icon: icon, color: color, size: 56)),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 16.5, fontWeight: FontWeight.w800, color: MoodaTheme.ink),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: MoodaTheme.muted, fontSize: 12.5, height: 1.45),
                  ),
                  const SizedBox(height: 20),
                  ClayButton(
                    label: confirmLabel,
                    icon: LucideIcons.check,
                    color: color,
                    height: 48,
                    onPressed: () => Navigator.of(ctx).pop(true),
                  ),
                  const SizedBox(height: 10),
                  ClayButton(
                    label: cancelLabel,
                    icon: LucideIcons.x,
                    color: MoodaTheme.bg,
                    textColor: MoodaTheme.muted,
                    height: 44,
                    onPressed: () => Navigator.of(ctx).pop(false),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return res ?? false;
  }
}
