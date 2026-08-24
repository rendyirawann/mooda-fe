import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Permukaan dasar: **claymorphism** (empuk, sudut besar, bayangan lembut ganda)
/// + **minimalism** (tanpa garis tepi tegas, isi lapang).
class ClayBox extends StatelessWidget {
  const ClayBox({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = MoodaTheme.radiusLg,
    this.color,
    this.gradient,
    this.pressed = false,
    this.width,
    this.height,
    this.margin,
    this.shadow = true,
    // Diterima agar pemanggil lama tetap jalan.
    this.hardBorder = false,
    this.blur = 22,
    this.spread = 1,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Gradient? gradient;
  final bool pressed;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;
  final bool shadow;
  final bool hardBorder;
  final double blur;
  final double spread;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 110),
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? MoodaTheme.surface) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow
            ? (pressed ? MoodaTheme.clayPressed() : MoodaTheme.soft(blur: blur, y: 8 * spread))
            : null,
      ),
      child: child,
    );
  }
}

/// Kartu yang bisa ditekan: mengecil sedikit & bayangan mengempis saat ditahan.
class ClayTappable extends StatefulWidget {
  const ClayTappable({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.radius = MoodaTheme.radiusLg,
    this.color,
    this.gradient,
    this.hardBorder = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Gradient? gradient;
  final bool hardBorder;

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
        scale: _down ? 0.975 : 1,
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

/// Tombol utama clay.
class ClayButton extends StatelessWidget {
  const ClayButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.expand = true,
    this.color,
    this.textColor = Colors.white,
    this.height = 50,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final bool expand;
  final Color? color;
  final Color textColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;

    return Opacity(
      opacity: disabled && !loading ? 0.5 : 1,
      child: ClayTappable(
        onTap: disabled ? null : onPressed,
        gradient: (color == null) ? MoodaTheme.primaryGradient : null,
        color: color,
        radius: MoodaTheme.radius,
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: height,
          child: Center(
            child: loading
                ? SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: textColor),
                  )
                : Row(
                    mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: textColor, size: 19),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        label,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Ikon clay: bantalan warna muda yang empuk, tanpa garis tegas.
class ClayIconBadge extends StatelessWidget {
  const ClayIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 48,
    this.iconColor,
    this.tinted = true,
  });

  final IconData icon;
  final Color color;
  final double size;
  final Color? iconColor;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tinted ? color.withValues(alpha: 0.13) : color,
        borderRadius: BorderRadius.circular(size * 0.34),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: tinted ? 0.16 : 0.3),
            blurRadius: 12,
            offset: const Offset(2, 4),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.85),
            blurRadius: 8,
            offset: const Offset(-2, -3),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: iconColor ?? (tinted ? color : Colors.white),
        size: size * 0.44,
      ),
    );
  }
}

/// Label kecil (badge "POS", status, dsb) — datar & minimalis.
class ClayTag extends StatelessWidget {
  const ClayTag({
    super.key,
    required this.text,
    this.color = MoodaTheme.primary,
    this.textColor = Colors.white,
    this.fontSize = 12,
  });

  final String text;
  final Color color;
  final Color textColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(9),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.28),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
