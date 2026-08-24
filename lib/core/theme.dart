import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Tema Mooda Mobile.
///
/// Tipografi: **Plus Jakarta Sans** untuk hampir seluruh UI, **Manrope** (bold)
/// khusus angka besar & headline utama — lihat [number].
class MoodaTheme {
  MoodaTheme._();

  // ---- Warna ----
  static const Color primary = Color(0xFF5B2EE5); // ungu utama
  static const Color primaryDark = Color(0xFF4A1FD0);
  static const Color primaryLight = Color(0xFF8B6BF2);
  static const Color accent = Color(0xFF7C3AED);
  static const Color ink = Color(0xFF15161C);
  static const Color muted = Color(0xFF7C8398);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  /// Latar aplikasi: putih kebiruan sangat lembut (seperti rancangan).
  static const Color bg = Color(0xFFF6F6FB);
  static const Color surface = Colors.white;
  static const Color line = Color(0xFFECEDF5);
  static const Color fieldBg = Color(0xFFFAFAFE);

  // ---- Bentuk ----
  static const double radius = 18;
  static const double radiusSm = 12;
  static const double radiusLg = 24;

  static const String fontUi = 'PlusJakartaSans';
  static const String fontNumber = 'Manrope';

  /// Gaya angka besar / headline (Manrope, tebal).
  ///
  /// Manrope di-bundle sebagai variable font, jadi ketebalan diatur lewat
  /// `FontVariation('wght')` — `fontWeight` saja tidak mengubah rupanya.
  static TextStyle number({
    double size = 26,
    Color color = ink,
    double weight = 800,
    double? height,
    double letterSpacing = -0.5,
  }) =>
      TextStyle(
        fontFamily: fontNumber,
        fontSize: size,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        fontWeight: FontWeight.w800,
        fontVariations: [FontVariation('wght', weight)],
      );

  // ---- Gaya: claymorphism + minimalism ----
  //
  // clay      : permukaan gempal & empuk, sudut besar, bayangan LEMBUT ganda
  //             (gelap di kanan-bawah + sorot putih di kiri-atas)
  // minimalism: tanpa garis tepi tegas, palet terkunci, banyak ruang kosong

  /// Garis tepi sangat halus — hanya untuk memisahkan, bukan menegaskan.
  static const Color border = Color(0xFFE8E7F2);
  static const Color borderSoft = Color(0xFFF0EFF8);
  static const double borderWidth = 1;

  /// Warna bayangan clay (nada ungu redup, bukan hitam).
  static const Color clayShade = Color(0xFFCFCADF);

  /// Bayangan clay: gelap di kanan-bawah + sorot putih di kiri-atas.
  static List<BoxShadow> soft({double blur = 22, double y = 8, double alpha = 0.55}) => [
        BoxShadow(
          color: clayShade.withValues(alpha: alpha),
          blurRadius: blur,
          offset: Offset(y * 0.5, y),
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.9),
          blurRadius: blur * 0.7,
          offset: Offset(-y * 0.4, -y * 0.5),
        ),
      ];

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6B3AF2), Color(0xFF4A1FD0)],
  );

  static List<BoxShadow> clay({double blur = 22, double spread = 1}) =>
      soft(blur: blur, y: 8 * spread);

  /// Keadaan tertekan: bayangan mengempis (kesan permukaan clay ditekan).
  static List<BoxShadow> clayPressed() => [
        BoxShadow(
          color: clayShade.withValues(alpha: 0.5),
          blurRadius: 6,
          offset: const Offset(1, 2),
        ),
      ];

  static const LinearGradient claySurface = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.white, Colors.white],
  );

  static LinearGradient get clayPrimary => primaryGradient;

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: accent,
      surface: surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      fontFamily: fontUi,
      // Transisi geser + GESTURE SLIDE BACK dari tepi layar (juga di Android).
      // Menggeser dari sisi kiri akan kembali ke halaman sebelumnya; di halaman
      // pertama, tombol/gestur kembali menutup aplikasi seperti biasa.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.fuchsia: CupertinoPageTransitionsBuilder(),
        },
      ),
      dividerTheme: const DividerThemeData(color: line, thickness: 1, space: 24),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontUi,
          color: ink,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: ink, fontWeight: FontWeight.w800),
        titleMedium: TextStyle(color: ink, fontWeight: FontWeight.w700),
        bodyMedium: TextStyle(color: ink),
        bodySmall: TextStyle(color: muted),
      ),
      iconTheme: const IconThemeData(color: ink),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
          textStyle: const TextStyle(
            fontFamily: fontUi,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      // Field bergaya rancangan: latar sangat terang, garis tipis, label ungu.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        hintStyle: const TextStyle(color: muted, fontWeight: FontWeight.w400),
        labelStyle: const TextStyle(color: primary, fontWeight: FontWeight.w600, fontSize: 13),
        floatingLabelStyle: const TextStyle(
            color: primary, fontWeight: FontWeight.w700, fontSize: 13),
        prefixIconColor: muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: danger, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: const TextStyle(color: Colors.white, fontFamily: fontUi),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }
}
