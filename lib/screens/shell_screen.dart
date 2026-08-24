import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme.dart';
import '../services/auth_service.dart';
import '../widgets/clay.dart';
import '../widgets/feedback.dart';
import 'beranda_screen.dart';
import 'kasir_screen.dart';
import 'laporan_screen.dart';
import 'login_screen.dart';
import 'meja_screen.dart';
import 'menu_screen.dart';
import 'dapur_screen.dart';
import 'pengaturan_screen.dart';
import 'pesanan_screen.dart';
import 'shift_screen.dart';
import 'stok_screen.dart';

/// Satu entri menu pada panel "Lainnya".
class MenuEntry {
  const MenuEntry(this.title, this.icon, this.color, this.builder);
  final String title;
  final IconData icon;
  final Color color;
  final Widget Function() builder;
}

/// Kerangka utama: 4 tab bawah + tombol "Lainnya" yang membuka panel dari bawah
/// (tanpa sidebar).
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _tab = 0;

  static const _tabs = <(String, IconData)>[
    ('Beranda', LucideIcons.house),
    ('Kasir', LucideIcons.shoppingCart),
    ('Pesanan', LucideIcons.receiptText),
    ('Laporan', LucideIcons.chartNoAxesColumn),
  ];

  /// Menu lain yang muncul di panel bawah.
  static final _more = <MenuEntry>[
    MenuEntry('Dapur', LucideIcons.chefHat, const Color(0xFFF97316), () => const DapurScreen()),
    MenuEntry('Meja', LucideIcons.armchair, const Color(0xFF16A34A), () => const MejaScreen()),
    MenuEntry('Menu & Resep', LucideIcons.bookOpen, const Color(0xFF8B5CF6), () => const MenuScreen()),
    MenuEntry('Bahan & Stok', LucideIcons.boxes, const Color(0xFF06B6D4), () => const StokScreen()),
    MenuEntry('HPP', LucideIcons.calculator, const Color(0xFFA855F7), () => const LaporanScreen(focusHpp: true)),
    MenuEntry('Shift', LucideIcons.clock, const Color(0xFF0EA5E9), () => const ShiftScreen()),
    MenuEntry('Pengaturan', LucideIcons.settings, const Color(0xFF64748B), () => const PengaturanScreen()),
  ];

  Widget _page() => switch (_tab) {
        1 => const KasirScreen(embedded: true),
        2 => const PesananScreen(embedded: true),
        3 => const LaporanScreen(embedded: true),
        _ => const BerandaScreen(),
      };

  Future<void> _openMore() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MorePanel(entries: _more, onLogout: _logout),
    );
  }

  /// Keluar akun: konfirmasi -> preloader -> notifikasi -> balik ke Login.
  Future<void> _logout() async {
    final yes = await Notify.confirm(
      context,
      title: 'Keluar dari akun?',
      message: 'Kamu perlu masuk kembali untuk memakai aplikasi.',
      confirmLabel: 'Ya, keluar',
      icon: LucideIcons.logOut,
      color: MoodaTheme.danger,
    );
    if (!yes || !mounted) return;

    Notify.showLoader(context, 'Keluar...');
    await AuthService.logout();
    if (!mounted) return;

    Navigator.of(context).pop(); // tutup preloader
    Notify.toast(context, 'Berhasil keluar.');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _page(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: MoodaTheme.border, width: 1)),
        ),
        padding: const EdgeInsets.only(top: 8, bottom: 10, left: 6, right: 6),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              for (var i = 0; i < _tabs.length; i++)
                Expanded(child: _tabItem(i, _tabs[i].$1, _tabs[i].$2)),
              Expanded(child: _moreItem()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabItem(int i, String label, IconData icon) {
    final active = _tab == i;
    return GestureDetector(
      onTap: () => setState(() => _tab = i),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 21, color: active ? MoodaTheme.primary : MoodaTheme.muted),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: active ? FontWeight.w800 : FontWeight.w500,
              color: active ? MoodaTheme.primary : MoodaTheme.muted,
            ),
          ),
        ],
      ),
    );
  }

  /// Tombol "Lainnya": bantalan clay ungu, membuka panel dari bawah.
  Widget _moreItem() {
    return GestureDetector(
      onTap: _openMore,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 26,
            decoration: BoxDecoration(
              gradient: MoodaTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: MoodaTheme.primary.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(LucideIcons.layoutGrid, size: 15, color: Colors.white),
          ),
          const SizedBox(height: 4),
          const Text(
            'Lainnya',
            style: TextStyle(
                fontSize: 10.5, fontWeight: FontWeight.w800, color: MoodaTheme.primary),
          ),
        ],
      ),
    );
  }
}

/// Panel bawah berisi menu-menu lain.
class _MorePanel extends StatelessWidget {
  const _MorePanel({required this.entries, required this.onLogout});

  final List<MenuEntry> entries;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: ClayBox(
        radius: 28,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: MoodaTheme.borderSoft,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Menu lainnya',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800, color: MoodaTheme.ink)),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entries.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.82,
                ),
                itemBuilder: (_, i) {
                  final e = entries[i];
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => e.builder()),
                      );
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      children: [
                        ClayIconBadge(icon: e.icon, color: e.color, size: 46),
                        const SizedBox(height: 7),
                        Text(
                          e.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: MoodaTheme.ink,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              ClayButton(
                label: 'Keluar',
                icon: LucideIcons.logOut,
                color: const Color(0xFFFFECEC),
                textColor: MoodaTheme.danger,
                height: 50,
                onPressed: () {
                  Navigator.of(context).pop();
                  onLogout();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
