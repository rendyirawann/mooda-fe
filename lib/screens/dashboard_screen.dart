import 'package:flutter/material.dart';

import '../core/session.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';
import '../widgets/clay.dart';
import '../widgets/decor.dart';
import 'dapur_screen.dart';
import 'kasir_screen.dart';
import 'laporan_screen.dart';
import 'login_screen.dart';
import 'meja_screen.dart';
import 'menu_screen.dart';
import 'module_placeholder.dart';
import 'permissions_screen.dart';
import 'pesanan_screen.dart';
import 'shift_screen.dart';
import 'stok_screen.dart';

/// Modul disamakan dengan web stakko-pos (F&B), tata letak grid clay untuk mobile.
class _Module {
  final String title;
  final IconData icon;
  final Color color;
  final String endpointHint;
  const _Module(this.title, this.icon, this.color, this.endpointHint);
}

const _modules = <_Module>[
  _Module('Kasir', Icons.point_of_sale_rounded, Color(0xFF3070F0), 'POST /fnb/orders'),
  _Module('Dapur', Icons.soup_kitchen_rounded, Color(0xFFF97316), 'GET /fnb/kitchen/orders'),
  _Module('Pesanan', Icons.receipt_long_rounded, Color(0xFF0EA5E9), 'GET /fnb/orders'),
  _Module('Meja', Icons.table_restaurant_rounded, Color(0xFF10B981), 'GET /fnb/tables'),
  _Module('Menu', Icons.restaurant_menu_rounded, Color(0xFF8B5CF6), 'GET /fnb/menus'),
  _Module('Stok', Icons.inventory_2_rounded, Color(0xFF06B6D4), 'GET /fnb/inventory/ingredients'),
  _Module('Resep', Icons.menu_book_rounded, Color(0xFFF59E0B), 'GET /fnb/recipes/{id}'),
  _Module('Laporan', Icons.bar_chart_rounded, Color(0xFF2563EB), 'GET /fnb/reports/sales'),
  _Module('HPP', Icons.calculate_rounded, Color(0xFFA855F7), 'GET /fnb/reports/hpp'),
  _Module('Shift', Icons.schedule_rounded, Color(0xFF059669), 'GET /shifts/current'),
  _Module('Langganan', Icons.workspace_premium_rounded, Color(0xFFEC4899), 'GET /account/plan'),
  _Module('Izin & Setelan', Icons.settings_rounded, Color(0xFF64748B), 'GET /config'),
];

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _name = 'Pengguna';

  @override
  void initState() {
    super.initState();
    Session.name().then((n) {
      if (n != null && n.isNotEmpty && mounted) setState(() => _name = n);
    });
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ClayBackdrop(
        child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 26),
          children: [
            // Bar atas: logo + tombol keluar (keduanya clay).
            Row(
              children: [
                ClayBox(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  radius: MoodaTheme.radiusSm,
                  blur: 12,
                  child: Image.asset(
                    'assets/images/mooda-logo.png',
                    height: 26,
                    fit: BoxFit.contain,
                  ),
                ),
                const Spacer(),
                ClayTappable(
                  onTap: _logout,
                  radius: 100,
                  padding: const EdgeInsets.all(13),
                  child: const Icon(Icons.logout_rounded,
                      size: 20, color: MoodaTheme.ink),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Sapaan (clay berwarna brand).
            ClayBox(
              radius: MoodaTheme.radiusLg,
              padding: const EdgeInsets.all(22),
              gradient: MoodaTheme.clayPrimary,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Selamat datang,',
                            style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          _name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/mooda-mark-192.png',
                        height: 30,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Padding(
              padding: EdgeInsets.only(left: 6, bottom: 12),
              child: Text(
                'Modul',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: MoodaTheme.ink,
                ),
              ),
            ),
            LayoutBuilder(
              builder: (context, c) {
                final cross = c.maxWidth > 520 ? 4 : 3;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _modules.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cross,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.88,
                  ),
                  itemBuilder: (_, i) => _ModuleTile(module: _modules[i]),
                );
              },
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({required this.module});
  final _Module module;

  @override
  Widget build(BuildContext context) {
    return ClayTappable(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => switch (module.title) {
            // Semua modul F&B sudah tersambung ke API.
            'Kasir' => const KasirScreen(),
            'Dapur' => const DapurScreen(),
            'Pesanan' => const PesananScreen(),
            'Meja' => const MejaScreen(),
            'Menu' => const MenuScreen(),
            'Resep' => const MenuScreen(),
            'Stok' => const StokScreen(),
            'Laporan' => const LaporanScreen(),
            'HPP' => const LaporanScreen(focusHpp: true),
            'Shift' => const ShiftScreen(),
            'Izin & Setelan' => const PermissionsScreen(),
            // Sisanya (mis. Langganan) belum punya layar sendiri.
            _ => ModulePlaceholder(
                title: module.title,
                endpointHint: module.endpointHint,
                color: module.color,
                icon: module.icon,
              ),
          },
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClayIconBadge(icon: module.icon, color: module.color),
          const SizedBox(height: 10),
          Text(
            module.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: MoodaTheme.ink,
            ),
          ),
        ],
      ),
    );
  }
}
