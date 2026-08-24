import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/config.dart';
import 'core/session.dart';
import 'core/theme.dart';
import 'screens/login_screen.dart';
import 'screens/shell_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MoodaApp());
}

class MoodaApp extends StatelessWidget {
  const MoodaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: MoodaTheme.light(),
      // Bahasa Indonesia untuk pemilih tanggal/rentang tanggal di Laporan.
      locale: const Locale('id'),
      supportedLocales: const [Locale('id'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => _OrientationLock(child: child ?? const SizedBox()),
      home: const _Gate(),
    );
  }
}

/// Kunci rotasi sesuai ukuran perangkat:
///  - **Ponsel** (sisi terpendek < 600dp): dikunci POTRET. Landscape di ponsel
///    membuat grid menu kasir terlalu sempit dan sulit dipakai.
///  - **Tablet/pad** (>= 600dp): bebas berotasi, sehingga kasir bisa memakai
///    tata letak dua panel seperti versi web.
class _OrientationLock extends StatefulWidget {
  const _OrientationLock({required this.child});

  final Widget child;

  @override
  State<_OrientationLock> createState() => _OrientationLockState();
}

class _OrientationLockState extends State<_OrientationLock> {
  bool? _tablet;

  @override
  Widget build(BuildContext context) {
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    final isTablet = shortest >= 600;

    if (_tablet != isTablet) {
      _tablet = isTablet;
      SystemChrome.setPreferredOrientations(
        isTablet
            ? const [
                DeviceOrientation.portraitUp,
                DeviceOrientation.landscapeLeft,
                DeviceOrientation.landscapeRight,
              ]
            : const [DeviceOrientation.portraitUp],
      );
    }

    return widget.child;
  }
}

/// Tentukan layar awal berdasarkan token tersimpan.
class _Gate extends StatefulWidget {
  const _Gate();

  @override
  State<_Gate> createState() => _GateState();
}

class _GateState extends State<_Gate> {
  bool? _authed;

  @override
  void initState() {
    super.initState();
    Session.isLoggedIn().then((v) {
      if (mounted) setState(() => _authed = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_authed == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _authed! ? const ShellScreen() : const LoginScreen();
  }
}
