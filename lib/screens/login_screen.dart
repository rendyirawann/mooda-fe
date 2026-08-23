import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/api_client.dart';
import '../core/config.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';
import '../widgets/clay.dart';
import '../widgets/decor.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.login(_email.text.trim(), _pass.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } catch (e) {
      setState(() => _error = ApiClient.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ClayBackdrop(
        child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo Mooda di atas bantalan clay.
                    Center(
                      child: ClayBox(
                        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
                        radius: MoodaTheme.radiusLg,
                        child: Image.asset(
                          'assets/images/mooda-logo.png',
                          height: 92,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Ilustrasi kasir (SVG) — memberi konteks & tak terasa polos.
                    Center(
                      child: SvgPicture.asset(
                        'assets/svg/illus-kasir.svg',
                        height: 132,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Masuk ke akunmu',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: MoodaTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      AppConfig.tagline,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: MoodaTheme.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 26),

                    // Kartu form clay.
                    ClayBox(
                      padding: const EdgeInsets.all(20),
                      radius: MoodaTheme.radiusLg,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.mail_outline_rounded),
                            ),
                            validator: (v) => (v == null || !v.contains('@'))
                                ? 'Email tidak valid'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _pass,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: 'Kata sandi',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: MoodaTheme.muted,
                                ),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Kata sandi wajib diisi'
                                : null,
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            ClayBox(
                              padding: const EdgeInsets.all(14),
                              radius: MoodaTheme.radiusSm,
                              color: const Color(0xFFFDECEC),
                              blur: 10,
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded,
                                      color: MoodaTheme.danger, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: const TextStyle(
                                        color: MoodaTheme.danger,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 22),
                          ClayButton(
                            label: 'Masuk',
                            icon: Icons.arrow_forward_rounded,
                            loading: _loading,
                            onPressed: _loading ? null : _submit,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      AppConfig.apiBase,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: MoodaTheme.muted, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
