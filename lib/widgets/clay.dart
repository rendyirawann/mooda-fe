import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Permukaan clay dasar: sudut sangat bulat + bayangan ganda.
class ClayBox extends StatelessWidget {
  const ClayBox({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = MoodaTheme.radius,
    this.color,
    this.gradient,
    this.blur = 18,
    this.spread = 1,
    this.pressed = false,
    this.width,
    this.height,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Gradient? gradient;
  final double blur;
  final double spread;
  final bool pressed;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? MoodaTheme.surface) : null,
        gradient: gradient ?? (color == null ? MoodaTheme.claySurface : null),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: pressed
            ? MoodaTheme.clayPressed()
            : MoodaTheme.clay(blur: blur, spread: spread),
      ),
      child: child,
    );
  }
}

/// Kartu clay yang bisa ditekan — mengecil & bayangan masuk saat ditahan.
class ClayTappable extends StatefulWidget {
  const ClayTappable({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.radius = MoodaTheme.radius,
    this.color,
    this.gradient,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Gradient? gradient;

  @override
  State<ClayTappable> createState() => _ClayTappableState();
}

class _ClayTappableState extends State<ClayTappable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 110),
        child: ClayBox(
          padding: widget.padding,
          radius: widget.radius,
          color: widget.color,
          gradient: widget.gradient,
          pressed: _down,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Tombol utama clay (gradien biru Mooda).
class ClayButton extends StatelessWidget {
  const ClayButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;

    final content = loading
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
          )
        : Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 10),
              ],
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          );

    return Opacity(
      opacity: disabled && !loading ? 0.55 : 1,
      child: ClayTappable(
        onTap: disabled ? null : onPressed,
        gradient: MoodaTheme.clayPrimary,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 22),
        child: Center(child: content),
      ),
    );
  }
}

/// Ikon clay bulat berwarna (dipakai kartu modul).
class ClayIconBadge extends StatelessWidget {
  const ClayIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 54,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, Colors.white, 0.30)!,
            Color.lerp(color, Colors.black, 0.10)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            offset: const Offset(3, 4),
            blurRadius: 10,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.9),
            offset: const Offset(-3, -3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.46),
    );
  }
}
