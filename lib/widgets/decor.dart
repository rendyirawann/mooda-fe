import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/theme.dart';

/// Latar bergaya clay: gumpalan (blob) SVG lembut + pola titik tipis,
/// supaya halaman tidak terasa polos/kaku.
class ClayBackdrop extends StatelessWidget {
  const ClayBackdrop({super.key, required this.child, this.showPattern = true});

  final Widget child;
  final bool showPattern;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MoodaTheme.bg,
      child: Stack(
        children: [
          // Pola titik halus (digambar langsung; selalu tajam di semua dpi).
          if (showPattern)
            const Positioned.fill(
              child: CustomPaint(painter: _DotPatternPainter()),
            ),
          // Blob kanan-atas.
          Positioned(
            top: -110,
            right: -120,
            child: SvgPicture.asset('assets/svg/blob-hero.svg', width: 340),
          ),
          // Blob kiri-bawah (diputar agar tidak kembar).
          Positioned(
            bottom: -140,
            left: -130,
            child: Transform.rotate(
              angle: 2.4,
              child: SvgPicture.asset('assets/svg/blob-hero.svg', width: 320),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Grid titik dua-nada, meniru `pattern-dots.svg`.
class _DotPatternPainter extends CustomPainter {
  const _DotPatternPainter();

  static const double _step = 22;

  @override
  void paint(Canvas canvas, Size size) {
    final big = Paint()..color = MoodaTheme.primary.withValues(alpha: 0.07);
    final small = Paint()..color = MoodaTheme.ink.withValues(alpha: 0.045);

    for (double y = 0; y < size.height + _step; y += _step) {
      for (double x = 0; x < size.width + _step; x += _step) {
        canvas.drawCircle(Offset(x, y), 2.1, big);
        canvas.drawCircle(Offset(x + _step / 2, y + _step / 2), 1.4, small);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
