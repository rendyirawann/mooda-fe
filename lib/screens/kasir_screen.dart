import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../services/kasir_service.dart';
import '../widgets/clay.dart';
import '../widgets/decor.dart';
import 'payment_sheet.dart';

/// Kasir F&B: pilih menu -> keranjang -> buat pesanan -> bayar (server-side).
class KasirScreen extends StatefulWidget {
  const KasirScreen({super.key});

  @override
  State<KasirScreen> createState() => _KasirScreenState();
}

class _KasirScreenState extends State<KasirScreen> {
  final _search = TextEditingController();
  List<MenuItem> _menus = [];
  final List<CartLine> _cart = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await KasirService.menus(query: _search.text.trim());
      if (!mounted) return;
      setState(() => _menus = list);
    } catch (e) {
      if (mounted) setState(() => _error = ApiClient.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _add(MenuItem m) {
    setState(() {
      final i = _cart.indexWhere((l) => l.menu.id == m.id && (l.note ?? '').isEmpty);
      if (i >= 0) {
        _cart[i].qty++;
      } else {
        _cart.add(CartLine(menu: m));
      }
    });
  }

  int get _itemCount => _cart.fold(0, (a, l) => a + l.qty);
  double get _previewTotal => _cart.fold(0, (a, l) => a + l.preview);

  Future<void> _openCart() async {
    if (_cart.isEmpty) return;
    final paid = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaymentSheet(cart: _cart),
    );
    if (paid == true && mounted) {
      setState(() => _cart.clear());
      _load(); // segarkan ketersediaan menu
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ClayBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              // Bar atas + pencarian.
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                child: Row(
                  children: [
                    ClayTappable(
                      onTap: () => Navigator.of(context).maybePop(),
                      radius: 100,
                      padding: const EdgeInsets.all(13),
                      child: const Icon(Icons.arrow_back_rounded,
                          size: 20, color: MoodaTheme.ink),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Kasir',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: MoodaTheme.ink,
                        ),
                      ),
                    ),
                    ClayTappable(
                      onTap: _load,
                      radius: 100,
                      padding: const EdgeInsets.all(13),
                      child: const Icon(Icons.refresh_rounded,
                          size: 20, color: MoodaTheme.ink),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _load(),
                  decoration: InputDecoration(
                    hintText: 'Cari menu...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded, color: MoodaTheme.muted),
                            onPressed: () {
                              _search.clear();
                              _load();
                            },
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(child: _body()),
              if (_cart.isNotEmpty) _cartBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset('assets/svg/illus-empty.svg', height: 130),
              const SizedBox(height: 18),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: MoodaTheme.danger, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ClayButton(label: 'Coba lagi', icon: Icons.refresh_rounded, onPressed: _load),
            ],
          ),
        ),
      );
    }
    if (_menus.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset('assets/svg/illus-empty.svg', height: 140),
            const SizedBox(height: 16),
            const Text('Belum ada menu', style: TextStyle(color: MoodaTheme.muted)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      itemCount: _menus.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final m = _menus[i];
        final inCart = _cart
            .where((l) => l.menu.id == m.id)
            .fold<int>(0, (a, l) => a + l.qty);

        return ClayTappable(
          onTap: m.available ? () => _add(m) : null,
          padding: const EdgeInsets.all(14),
          child: Opacity(
            opacity: m.available ? 1 : 0.5,
            child: Row(
              children: [
                const ClayIconBadge(
                  icon: Icons.restaurant_rounded,
                  color: MoodaTheme.primary,
                  size: 46,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: MoodaTheme.ink,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        m.available
                            ? '${m.category ?? '-'} · ${Rupiah.format(m.price)}'
                            : 'Habis',
                        style: const TextStyle(color: MoodaTheme.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (inCart > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: MoodaTheme.primary,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '$inCart',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  )
                else if (m.available)
                  const Icon(Icons.add_circle_outline_rounded,
                      color: MoodaTheme.primary, size: 26),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _cartBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      child: ClayBox(
        radius: MoodaTheme.radiusLg,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_itemCount item',
                    style: const TextStyle(color: MoodaTheme.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Rupiah.format(_previewTotal),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: MoodaTheme.ink,
                    ),
                  ),
                  const Text(
                    'pajak dihitung di server',
                    style: TextStyle(color: MoodaTheme.muted, fontSize: 10.5),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 150,
              child: ClayButton(
                label: 'Lanjut',
                icon: Icons.shopping_cart_checkout_rounded,
                onPressed: _openCart,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
