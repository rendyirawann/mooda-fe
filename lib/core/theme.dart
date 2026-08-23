import 'package:flutter/material.dart';

/// Tema Mooda Mobile — gaya **claymorphism**:
/// permukaan empuk, sudut sangat bulat, bayangan ganda (gelap di kanan-bawah +
/// sorot putih di kiri-atas), tanpa garis tepi tajam.
///
/// Warna diambil dari logo Mooda: biru #3070F0 + navy #102030.
class MoodaTheme {
  MoodaTheme._();

  // ---- Warna brand (dari logo) ----
  static const Color primary = Color(0xFF3070F0); // biru Mooda
  static const Color primaryDark = Color(0xFF2358D0);
  static const Color primaryLight = Color(0xFF6E9BFF);
  static const Color ink = Color(0xFF102030); // navy wordmark
  static const Color accent = Color(0xFF5B8DEF);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color muted = Color(0xFF7A8699);

  // ---- Permukaan clay ----
  /// Latar utama: sedikit kebiruan agar clay "menyatu".
  static const Color bg = Color(0xFFE9EDF7);

  /// Permukaan kartu clay (sedikit lebih terang dari bg).
  static const Color surface = Color(0xFFF2F5FC);

  /// Sorot (highlight) kiri-atas.
  static const Color clayLight = Color(0xFFFFFFFF);

  /// Bayangan kanan-bawah (nada navy, bukan hitam abu).
  static const Color clayShadow = Color(0xFFC3CCE0);

  // ---- Token bentuk ----
  static const double radius = 26;
  static const double radiusSm = 18;
  static const double radiusLg = 34;

  /// Bayangan clay standar (menonjol / "puffy").
  static List<BoxShadow> clay({double blur = 18, double spread = 1}) => [
        BoxShadow(
          color: clayShadow.withValues(alpha: 0.85),
          offset: Offset(spread * 6, spread * 6),
          blurRadius: blur,
        ),
        BoxShadow(
          color: clayLight.withValues(alpha: 0.95),
          offset: Offset(-spread * 5, -spread * 5),
          blurRadius: blur,
        ),
      ];

  /// Bayangan clay "tertekan" (pressed / inset semu).
  static List<BoxShadow> clayPressed() => [
        BoxShadow(
          color: clayShadow.withValues(alpha: 0.9),
          offset: const Offset(2, 2),
          blurRadius: 6,
          spreadRadius: -2,
        ),
        BoxShadow(
          color: clayLight.withValues(alpha: 0.7),
          offset: const Offset(-2, -2),
          blurRadius: 6,
          spreadRadius: -2,
        ),
      ];

  /// Gradien lembut untuk memberi kesan permukaan melengkung.
  static const LinearGradient claySurface = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFAFBFF), Color(0xFFE8ECF8)],
  );

  /// Gradien clay berwarna (tombol utama / header).
  static const LinearGradient clayPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4B85FF), Color(0xFF2358D0)],
  );

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
      fontFamily: 'Roboto',
      // Clay tidak memakai garis pemisah tajam.
      dividerTheme: const DividerThemeData(color: Colors.transparent, space: 0),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: ink, fontWeight: FontWeight.w800),
        titleMedium: TextStyle(color: ink, fontWeight: FontWeight.w700),
        bodyMedium: TextStyle(color: ink),
        bodySmall: TextStyle(color: muted),
      ),
      iconTheme: const IconThemeData(color: ink),
      // Input clay: "cekung" tanpa border, radius besar.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFE4E9F5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: const TextStyle(color: muted),
        labelStyle: const TextStyle(color: muted),
        prefixIconColor: muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: danger, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: danger, width: 1.8),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
      ),
    );
  }
}
