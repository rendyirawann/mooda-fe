import 'package:flutter/material.dart';

import '../core/session.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'module_placeholder.dart';

/// Modul disamakan dengan web stakko-pos (F&B), tapi tata letak grid mobile.
class _Module {
  final String title;
  final IconData icon;
  final Color color;
  final String endpointHint;
  const _Module(this.title, this.icon, this.color, this.endpointHint);
}

const _modules = <_Module>[
  _Module('Kasir', Icons.point_of_sale, Color(0xFF4F46E5), 'POST /orders'),
  _Module('Dapur (KDS)', Icons.soup_kitchen, Color(0xFFEA580C), 'GET /kitchen/orders'),
  _Module('Pesanan', Icons.receipt_long, Color(0xFF0EA5E9), 'GET /orders'),
  _Module('Meja', Icons.table_restaurant, Color(0xFF16A34A), 'GET /tables'),
  _Module('Menu', Icons.restaurant_menu, Color(0xFF7C3AED), 'GET /menus'),
  _Module('Bahan & Stok', Icons.inventory_2, Color(0xFF0891B2), 'GET /inventory/ingredients'),
  _Module('Resep', Icons.menu_book, Color(0xFFD97706), 'GET /recipes'),
  _Module('Laporan', Icons.bar_chart, Color(0xFF2563EB), 'GET /reports/sales'),
  _Module('HPP', Icons.calculate, Color(0xFF9333EA), 'GET /reports/hpp'),
  _Module('Shift', Icons.schedule, Color(0xFF059669), 'GET /shifts/current'),
  _Module('Langganan', Icons.workspace_premium, Color(0xFFDB2777), 'GET /billing/plan'),
  _Module('Pengaturan', Icons.settings, Color(0xFF475569), 'GET /settings'),
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
      if (n != null && mounted) setState(() => _name = n);
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
      appBar: AppBar(
        title: const Text('Mooda'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [MoodaTheme.primary, MoodaTheme.accent],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Selamat datang,',
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 2),
                  Text(
                    _name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Modul',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, c) {
                final cross = c.maxWidth > 520 ? 4 : 3;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _modules.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cross,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.95,
                  ),
                  itemBuilder: (_, i) => _ModuleCard(module: _modules[i]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module});
  final _Module module;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ModulePlaceholder(
            title: module.title,
            endpointHint: module.endpointHint,
            color: module.color,
            icon: module.icon,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MoodaTheme.line),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: module.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(module.icon, color: module.color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              module.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: MoodaTheme.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
