import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Permukaan dasar: **clay** (gempal, sudut sangat bulat) + **brutalism**
/// (garis tepi tegas, bayangan keras tanpa blur) + **minimalism** (isi lapang,
/// tanpa hiasan berlebih).
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
    this.hardBorder = true,
    this.shadow = true,
    // Diterima agar pemanggil lama tetap jalan; tak lagi memengaruhi rupa.
    this.blur = 0,
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

  /// Garis tepi & bayangan tegas (brutalist). Matikan untuk elemen sekunder.
  final bool hardBorder;
  final bool shadow;
  final double blur;
  final double spread;

  @override
  Widget build(BuildContext context) {
    final offset = pressed ? const Offset(1, 1) : MoodaTheme.shadowOffset;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 90),
      width: width,
      height: height,
      margin: margin,
      // Saat ditekan, kartu ikut bergeser ke arah bayangan -> terasa "ditekan".
      transform: pressed
          ? Matrix4.translationValues(MoodaTheme.shadowOffset.dx - 1, MoodaTheme.shadowOffset.dy - 1, 0)
          : Matrix4.identity(),
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? MoodaTheme.surface) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: hardBorder ? MoodaTheme.border : MoodaTheme.borderSoft,
          width: hardBorder ? MoodaTheme.borderWidth : 1,
        ),
        boxShadow: shadow && hardBorder ? MoodaTheme.hard(offset: offset) : null,
      ),
      child: child,
    );
  }
}

/// Kartu yang bisa ditekan: bayangan mengempis & kartu bergeser saat ditahan.
class ClayTappable extends StatefulWidget {
  const ClayTappable({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.radius = MoodaTheme.radiusLg,
    this.color,
    this.gradient,
    this.hardBorder = true,
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
      child: ClayBox(
        padding: widget.padding,
        radius: widget.radius,
        color: widget.color,
        gradient: widget.gradient,
        pressed: _down,
        hardBorder: widget.hardBorder,
        child: widget.child,
      ),
    );
  }
}

/// Tombol utama: blok ungu, garis tepi tegas, bayangan keras.
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
    this.height = 56,
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
        color: color ?? MoodaTheme.primary,
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

/// Kotak ikon: blok warna datar + garis tepi tegas (bukan gradien lembut).
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

  /// true = latar warna muda + ikon berwarna (minimalis),
  /// false = blok warna penuh + ikon putih (lebih menonjol).
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tinted ? color.withValues(alpha: 0.12) : color,
        borderRadius: BorderRadius.circular(size * 0.34),
        border: Border.all(color: MoodaTheme.border, width: 1.4),
        boxShadow: MoodaTheme.hard(offset: const Offset(2.5, 2.5)),
      ),
      child: Icon(
        icon,
        color: iconColor ?? (tinted ? color : Colors.white),
        size: size * 0.44,
      ),
    );
  }
}

/// Label kecil bergaya brutalis (dipakai untuk badge "POS", status, dsb).
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MoodaTheme.border, width: 1.3),
        boxShadow: MoodaTheme.hard(offset: const Offset(2, 2)),
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
