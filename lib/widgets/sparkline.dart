import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Grafik garis sederhana untuk tren penjualan 7 hari.
/// Digambar sendiri (tanpa paket chart) agar ringan dan gayanya menyatu.
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    required this.labels,
    this.height = 116,
  });

  final List<double> values;
  final List<String> labels;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text('Belum ada data', style: TextStyle(color: MoodaTheme.muted, fontSize: 12)),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: height,
          child: CustomPaint(
            painter: _SparkPainter(values),
            size: Size.infinite,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final l in labels)
              Expanded(
                child: Text(
                  l,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: MoodaTheme.muted, fontSize: 10.5),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final maxV = values.reduce((a, b) => a > b ? a : b);
    // Skala: jika semua nol, garis diletakkan di dasar.
    final top = maxV <= 0 ? 1.0 : maxV * 1.15;
    final dx = values.length > 1 ? size.width / (values.length - 1) : size.width;

    final points = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(dx * i, size.height - (values[i] / top) * size.height),
    ];

    // Garis dasar (minimalis: hanya satu garis panduan).
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      Paint()..color = MoodaTheme.borderSoft..strokeWidth = 1.4,
    );

    // Area di bawah garis.
    final area = Path()..moveTo(points.first.dx, size.height);
    for (final p in points) {
      area.lineTo(p.dx, p.dy);
    }
    area
      ..lineTo(points.last.dx, size.height)
      ..close();

    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            MoodaTheme.primary.withValues(alpha: 0.28),
            MoodaTheme.primary.withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Garis tren tegas (brutalist).
    final line = Paint()
      ..color = MoodaTheme.primary
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, line);

    // Titik data: isi putih + tepi tegas.
    for (final p in points) {
      canvas.drawCircle(p, 4.2, Paint()..color = Colors.white);
      canvas.drawCircle(
        p,
        4.2,
        Paint()
          ..color = MoodaTheme.primary
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) => old.values != values;
}
