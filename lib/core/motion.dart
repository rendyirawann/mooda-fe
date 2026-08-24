import 'package:flutter/material.dart';

/// Kumpulan animasi ringan yang dipakai seluruh aplikasi.
///
/// Prinsip: pakai animasi bawaan Flutter (implicit animation) tanpa paket
/// tambahan, supaya tetap ringan dan tidak mengganggu scroll di HP kelas bawah.
class Motion {
  Motion._();

  static const Duration fast = Duration(milliseconds: 160);
  static const Duration normal = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 420);

  static const Curve enter = Curves.easeOutCubic;
}

/// Muncul dengan naik-halus + memudar. Dipakai untuk kartu & baris daftar.
///
/// [index] membuat efek berurutan (staggered) tanpa AnimationController manual:
/// tiap item menunda mulainya sedikit, dibatasi [maxStaggerSteps] agar daftar
/// panjang tidak terasa lambat.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.offsetY = 14,
    this.duration = Motion.normal,
    this.stagger = const Duration(milliseconds: 45),
    this.maxStaggerSteps = 8,
  });

  final Widget child;
  final int index;
  final double offsetY;
  final Duration duration;
  final Duration stagger;
  final int maxStaggerSteps;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _a =
      CurvedAnimation(parent: _c, curve: Motion.enter);

  @override
  void initState() {
    super.initState();
    final steps = widget.index.clamp(0, widget.maxStaggerSteps);
    final delay = widget.stagger * steps;
    if (delay == Duration.zero) {
      _c.forward();
    } else {
      Future<void>.delayed(delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, child) => Opacity(
        opacity: _a.value,
        child: Transform.translate(
          offset: Offset(0, widget.offsetY * (1 - _a.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Angka yang berjalan naik ke nilainya (dipakai untuk omzet & statistik).
class AnimatedNumber extends StatelessWidget {
  const AnimatedNumber({
    super.key,
    required this.value,
    required this.builder,
    this.duration = Motion.slow,
  });

  final double value;
  final Widget Function(double value) builder;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: Motion.enter,
      builder: (_, v, __) => builder(v),
    );
  }
}

/// Menampilkan dialog dengan animasi mengembang + memudar dari TENGAH layar.
Future<T?> showAnimatedDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool dismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    barrierLabel: 'tutup',
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: Motion.normal,
    // WAJIB dibungkus Material: tanpa ancestor Material, Flutter menggambar teks
    // dengan gaya cadangan — muncul garis bawah kuning ganda pada semua tulisan.
    pageBuilder: (ctx, _, __) => Material(
      type: MaterialType.transparency,
      child: builder(ctx),
    ),
    transitionBuilder: (_, anim, __, child) {
      final curved = CurvedAnimation(parent: anim, curve: Motion.enter);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}
