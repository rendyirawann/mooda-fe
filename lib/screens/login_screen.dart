import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';
import '../widgets/clay.dart';
import 'shell_screen.dart';

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
  bool _remember = true;
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
        MaterialPageRoute(builder: (_) => const ShellScreen()),
      );
    } catch (e) {
      setState(() => _error = ApiClient.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _soon(String what) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Masuk dengan $what belum tersedia.')),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Ilustrasi POS
                  SvgPicture.asset('assets/svg/illus-pos.svg', height: 210),
                  const SizedBox(height: 10),

                  // Logo + nama + badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/mooda-mark-192.png', height: 40),
                      const SizedBox(width: 8),
                      Text('Mooda', style: MoodaTheme.number(size: 32, weight: 800)),
                      const SizedBox(width: 10),
                      const ClayTag(text: 'POS', fontSize: 13),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Aplikasi Kasir Modern',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800, color: MoodaTheme.ink),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Kelola penjualan, stok, dan laporan\ndengan mudah dan cepat.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: MoodaTheme.muted, fontSize: 13, height: 1.45),
                  ),
                  const SizedBox(height: 24),

                  // Kartu form
                  ClayBox(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email / Username',
                            hintText: 'Masukkan email atau username',
                            prefixIcon: Icon(LucideIcons.user, size: 19),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _pass,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Masukkan password',
                            prefixIcon: const Icon(LucideIcons.lock, size: 19),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure ? LucideIcons.eyeOff : LucideIcons.eye,
                                size: 19,
                                color: MoodaTheme.muted,
                              ),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Password wajib diisi' : null,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            SizedBox(
                              width: 26,
                              height: 26,
                              child: Checkbox(
                                value: _remember,
                                onChanged: (v) => setState(() => _remember = v ?? true),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                side: const BorderSide(
                                    color: MoodaTheme.border, width: 1.5),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text('Ingat saya',
                                style: TextStyle(fontSize: 13, color: MoodaTheme.ink)),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => _soon('pemulihan password'),
                              child: const Text(
                                'Lupa password?',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: MoodaTheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          ClayBox(
                            radius: MoodaTheme.radiusSm,
                            color: const Color(0xFFFFECEC),
                            padding: const EdgeInsets.all(13),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.circleAlert,
                                    color: MoodaTheme.danger, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(
                                      color: MoodaTheme.danger,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        ClayButton(
                          label: 'Masuk',
                          loading: _loading,
                          onPressed: _loading ? null : _submit,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Pemisah
                  const Row(
                    children: [
                      Expanded(child: Divider(height: 1)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('atau masuk dengan',
                            style: TextStyle(color: MoodaTheme.muted, fontSize: 12)),
                      ),
                      Expanded(child: Divider(height: 1)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _social('Google', LucideIcons.globe)),
                      const SizedBox(width: 12),
                      Expanded(child: _social('Apple', LucideIcons.apple)),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Center(
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                            fontFamily: MoodaTheme.fontUi,
                            fontSize: 13,
                            color: MoodaTheme.muted),
                        children: [
                          TextSpan(text: 'Belum punya akun? '),
                          TextSpan(
                            text: 'Hubungi admin',
                            style: TextStyle(
                                color: MoodaTheme.primary, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _social(String label, IconData icon) => ClayTappable(
        onTap: () => _soon(label),
        radius: MoodaTheme.radius,
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 19, color: MoodaTheme.ink),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: MoodaTheme.ink, fontSize: 14),
            ),
          ],
        ),
      );
}
