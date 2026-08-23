import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../services/kasir_service.dart';
import '../widgets/clay.dart';
import 'payment_sheet.dart';

/// Kasir F&B.
///
/// Dua tata letak:
///  - **Portrait**  : grid menu + keranjang MENGAPUNG di bawah (hemat ruang).
///  - **Landscape** : dua panel seperti kasir web — menu di kiri, nota di kanan.
class KasirScreen extends StatefulWidget {
  const KasirScreen({super.key, this.embedded = false});

  /// true bila dipakai sebagai tab di dalam ShellScreen (tanpa tombol kembali).
  final bool embedded;

  @override
  State<KasirScreen> createState() => _KasirScreenState();
}

class _KasirScreenState extends State<KasirScreen> {
  final _search = TextEditingController();
  List<MenuItem> _menus = [];
  final List<CartLine> _cart = [];
  String _category = 'Semua';
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
      if (mounted) setState(() => _menus = list);
    } catch (e) {
      if (mounted) setState(() => _error = ApiClient.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> get _categories {
    final set = <String>{'Semua'};
    for (final m in _menus) {
      if ((m.category ?? '').isNotEmpty) set.add(m.category!);
    }
    return set.toList();
  }

  List<MenuItem> get _visible => _category == 'Semua'
      ? _menus
      : _menus.where((m) => m.category == _category).toList();

  int get _itemCount => _cart.fold(0, (a, l) => a + l.qty);
  double get _preview => _cart.fold(0, (a, l) => a + l.preview);

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

  void _dec(CartLine line) {
    setState(() {
      if (line.qty > 1) {
        line.qty--;
      } else {
        _cart.remove(line);
      }
    });
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty) return;
    final paid = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaymentSheet(cart: _cart),
    );
    if (paid == true && mounted) {
      setState(() => _cart.clear());
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final landscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            _searchAndChips(),
            Expanded(
              child: landscape
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 3, child: _grid(cols: 3)),
                        // Panel nota menetap (tidak mengapung) di mode landscape.
                        SizedBox(width: 320, child: _orderPanel()),
                      ],
                    )
                  : _grid(cols: 2),
            ),
          ],
        ),
      ),
      // Portrait: keranjang mengapung.
      floatingActionButton:
          (!landscape && _cart.isNotEmpty) ? _floatingCart() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _topBar() => Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
        child: Row(
          children: [
            if (!widget.embedded) ...[
              ClayTappable(
                onTap: () => Navigator.of(context).maybePop(),
                radius: 100,
                padding: const EdgeInsets.all(12),
                child: const Icon(LucideIcons.arrowLeft, size: 19, color: MoodaTheme.ink),
              ),
              const SizedBox(width: 12),
            ],
            const Expanded(
              child: Text('Kasir',
                  style: TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w800, color: MoodaTheme.ink)),
            ),
            ClayTappable(
              onTap: _load,
              radius: 100,
              padding: const EdgeInsets.all(12),
              child: const Icon(LucideIcons.refreshCw, size: 18, color: MoodaTheme.ink),
            ),
          ],
        ),
      );

  Widget _searchAndChips() => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'Cari menu...',
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(LucideIcons.x, size: 17, color: MoodaTheme.muted),
                        onPressed: () {
                          _search.clear();
                          _load();
                        },
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              children: [
                for (final c in _categories) ...[
                  ClayTappable(
                    onTap: () => setState(() => _category = c),
                    radius: 100,
                    color: _category == c ? MoodaTheme.primary : null,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      c,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: _category == c ? Colors.white : MoodaTheme.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
      );

  Widget _grid({required int cols}) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset('assets/svg/illus-empty.svg', height: 120),
              const SizedBox(height: 16),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: MoodaTheme.danger, fontSize: 13)),
              const SizedBox(height: 14),
              SizedBox(
                width: 180,
                child: ClayButton(
                    label: 'Coba lagi', icon: LucideIcons.refreshCw, onPressed: _load),
              ),
            ],
          ),
        ),
      );
    }

    final items = _visible;
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset('assets/svg/illus-empty.svg', height: 130),
            const SizedBox(height: 14),
            const Text('Menu tidak ditemukan',
                style: TextStyle(color: MoodaTheme.muted, fontSize: 13)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(18, 0, 18, _cart.isEmpty ? 20 : 92),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (_, i) => _menuCard(items[i]),
    );
  }

  Widget _menuCard(MenuItem m) {
    final inCart = _cart.where((l) => l.menu.id == m.id).fold<int>(0, (a, l) => a + l.qty);

    return ClayTappable(
      onTap: m.available ? () => _add(m) : null,
      padding: const EdgeInsets.all(12),
      child: Opacity(
        opacity: m.available ? 1 : 0.45,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kotak gambar (placeholder ikon bila menu belum berfoto).
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: MoodaTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: MoodaTheme.borderSoft),
                ),
                child: const Icon(LucideIcons.utensils,
                    color: MoodaTheme.primary, size: 26),
              ),
            ),
            const SizedBox(height: 9),
            Text(
              m.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: MoodaTheme.ink, fontSize: 13),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Expanded(
                  child: Text(
                    m.available ? Rupiah.format(m.price) : 'Habis',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MoodaTheme.number(size: 13, color: MoodaTheme.primary),
                  ),
                ),
                if (inCart > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: MoodaTheme.primary,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: MoodaTheme.border, width: 1.2),
                    ),
                    child: Text('$inCart',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                  )
                else if (m.available)
                  const Icon(LucideIcons.plus, size: 17, color: MoodaTheme.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Keranjang mengapung (portrait).
  Widget _floatingCart() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: ClayTappable(
          onTap: _checkout,
          color: MoodaTheme.primary,
          radius: MoodaTheme.radius,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white30, width: 1.2),
                ),
                child: Text('$_itemCount item',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  Rupiah.format(_preview),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MoodaTheme.number(size: 17, color: Colors.white),
                ),
              ),
              const Icon(LucideIcons.arrowRight, color: Colors.white, size: 19),
            ],
          ),
        ),
      );

  /// Panel nota (landscape) — mirip kasir web.
  Widget _orderPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 18, 18),
      child: ClayBox(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Daftar Pesanan (${_cart.length})',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800, color: MoodaTheme.ink)),
                ),
                if (_cart.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(_cart.clear),
                    child: const Text('Bersihkan',
                        style: TextStyle(
                            color: MoodaTheme.danger,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _cart.isEmpty
                  ? const Center(
                      child: Text('Belum ada item',
                          style: TextStyle(color: MoodaTheme.muted, fontSize: 12.5)),
                    )
                  : ListView(
                      children: [
                        for (final line in _cart) _panelLine(line),
                      ],
                    ),
            ),
            const Divider(height: 20),
            _totalRow('Subtotal', _preview),
            const SizedBox(height: 2),
            const Text('pajak & promo dihitung server',
                style: TextStyle(color: MoodaTheme.muted, fontSize: 10)),
            const SizedBox(height: 14),
            ClayButton(
              label: 'Bayar',
              icon: LucideIcons.creditCard,
              height: 50,
              onPressed: _cart.isEmpty ? null : _checkout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _panelLine(CartLine line) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.menu.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: MoodaTheme.ink, fontSize: 12.5),
                  ),
                  Text(Rupiah.format(line.menu.price),
                      style: const TextStyle(color: MoodaTheme.muted, fontSize: 11)),
                ],
              ),
            ),
            _qtyBtn(LucideIcons.minus, () => _dec(line)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9),
              child: Text('${line.qty}', style: MoodaTheme.number(size: 13)),
            ),
            _qtyBtn(LucideIcons.plus, () => setState(() => line.qty++)),
          ],
        ),
      );

  Widget _qtyBtn(IconData icon, VoidCallback onTap) => ClayTappable(
        onTap: onTap,
        radius: 100,
        padding: const EdgeInsets.all(7),
        child: Icon(icon, size: 14, color: MoodaTheme.ink),
      );

  Widget _totalRow(String label, double value) => Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: MoodaTheme.ink, fontSize: 13)),
          ),
          Text(Rupiah.format(value), style: MoodaTheme.number(size: 18)),
        ],
      );
}
