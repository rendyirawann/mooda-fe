import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/motion.dart';
import '../core/theme.dart';
import 'clay.dart';

/// Dialog clay yang muncul dari TENGAH layar.
///
/// Dipakai menggantikan bottom sheet untuk detail/aksi, karena panel yang
/// menempel di bawah sering tertutup tombol navigasi Android sehingga tombol
/// "Tutup" tak bisa ditekan. Dialog ini:
///  - selalu berada di tengah dan menghormati SafeArea,
///  - tingginya dibatasi (isi panjang bisa di-scroll di dalam),
///  - menyisakan ruang saat papan ketik muncul.
Future<T?> showClayDialog<T>({
  required BuildContext context,
  required String title,
  String? subtitle,
  required Widget content,
  List<Widget> actions = const [],
  bool dismissible = true,
}) {
  // Memakai showAnimatedDialog: sudah membungkus Material (mencegah teks
  // bergaris bawah kuning) dan memberi animasi mengembang + memudar.
  return showAnimatedDialog<T>(
    context: context,
    dismissible: dismissible,
    builder: (ctx) {
      final media = MediaQuery.of(ctx);
      final maxH = media.size.height -
          media.viewInsets.bottom -
          media.padding.top -
          media.padding.bottom -
          80;

      return Padding(
        // Ikut naik saat papan ketik tampil.
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom * 0.5),
        child: Center(
          child: SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 460,
                maxHeight: maxH < 260 ? 260 : maxH,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: ClayBox(
                  radius: 28,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: MoodaTheme.ink,
                                  ),
                                ),
                                if (subtitle != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    style: const TextStyle(
                                        color: MoodaTheme.muted, fontSize: 12),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Tombol tutup di pojok: selalu terjangkau.
                          GestureDetector(
                            onTap: () => Navigator.of(ctx).pop(),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: MoodaTheme.bg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(LucideIcons.x,
                                  size: 17, color: MoodaTheme.muted),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Isi bisa di-scroll agar tak pernah terpotong.
                      Flexible(
                        child: SingleChildScrollView(child: content),
                      ),
                      if (actions.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        for (var i = 0; i < actions.length; i++) ...[
                          actions[i],
                          if (i < actions.length - 1) const SizedBox(height: 10),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Dialog isi satu kolom form + tombol Simpan/Batal (dipakai stok, meja, shift).
Future<bool?> showClayFormDialog({
  required BuildContext context,
  required String title,
  String? subtitle,
  required List<Widget> fields,
  String confirmLabel = 'Simpan',
}) {
  return showClayDialog<bool>(
    context: context,
    title: title,
    subtitle: subtitle,
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < fields.length; i++) ...[
          fields[i],
          if (i < fields.length - 1) const SizedBox(height: 12),
        ],
      ],
    ),
    actions: [
      Builder(
        builder: (ctx) => ClayButton(
          label: confirmLabel,
          icon: LucideIcons.check,
          height: 50,
          onPressed: () => Navigator.of(ctx).pop(true),
        ),
      ),
      Builder(
        builder: (ctx) => ClayButton(
          label: 'Batal',
          icon: LucideIcons.x,
          color: MoodaTheme.bg,
          textColor: MoodaTheme.muted,
          height: 46,
          onPressed: () => Navigator.of(ctx).pop(false),
        ),
      ),
    ],
  );
}
