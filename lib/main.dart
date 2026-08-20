import 'package:flutter/material.dart';

import 'core/config.dart';
import 'core/session.dart';
import 'core/theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';

void main() => runApp(const MoodaApp());

class MoodaApp extends StatelessWidget {
  const MoodaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: MoodaTheme.light(),
      home: const _Gate(),
    );
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _authed! ? const DashboardScreen() : const LoginScreen();
  }
}
