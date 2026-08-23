import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/theme.dart';
import 'clay.dart';
import 'decor.dart';

/// Kerangka seragam untuk layar modul: latar clay, judul, tombol muat ulang,
/// serta keadaan memuat / gagal / kosong yang konsisten.
class ModuleScaffold extends StatelessWidget {
  const ModuleScaffold({
    super.key,
    required this.title,
    required this.child,
    this.onRefresh,
    this.actions = const [],
    this.floating,
    this.showBack = true,
  });

  final String title;
  final Widget child;
  final Future<void> Function()? onRefresh;
  final List<Widget> actions;
  final Widget? floating;

  /// false bila layar dipakai sebagai tab di ShellScreen (tak perlu tombol kembali).
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: floating,
      body: ClayBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                child: Row(
                  children: [
                    if (showBack) ...[
                      ClayTappable(
                        onTap: () => Navigator.of(context).maybePop(),
                        radius: 100,
                        padding: const EdgeInsets.all(12),
                        child: const Icon(LucideIcons.arrowLeft,
                            size: 19, color: MoodaTheme.ink),
                      ),
                      const SizedBox(width: 14),
                    ],
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: MoodaTheme.ink,
                        ),
                      ),
                    ),
                    ...actions,
                    if (onRefresh != null) ...[
                      const SizedBox(width: 8),
                      ClayTappable(
                        onTap: onRefresh,
                        radius: 100,
                        padding: const EdgeInsets.all(13),
                        child: const Icon(LucideIcons.refreshCw,
                            size: 20, color: MoodaTheme.ink),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tampilan keadaan (memuat / gagal / kosong) yang dipakai semua modul.
class ModuleState extends StatelessWidget {
  const ModuleState({
    super.key,
    this.loading = false,
    this.error,
    this.emptyText,
    this.onRetry,
  });

  final bool loading;
  final String? error;
  final String? emptyText;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset('assets/svg/illus-empty.svg', height: 130),
            const SizedBox(height: 18),
            Text(
              error ?? emptyText ?? 'Belum ada data',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: error != null ? MoodaTheme.danger : MoodaTheme.muted,
                fontSize: 13,
                fontWeight: error != null ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (error != null && onRetry != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: 180,
                child: ClayButton(
                  label: 'Coba lagi',
                  icon: LucideIcons.refreshCw,
                  onPressed: onRetry,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
