import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../core/motion.dart';
import '../core/theme.dart';
import '../services/fnb_service.dart';
import '../services/kasir_service.dart';
import '../services/offline_queue.dart';
import '../services/printer_service.dart';
import '../widgets/clay.dart';
import '../widgets/feedback.dart';
import 'payment_dialog.dart';
import 'pengaturan_screen.dart';

/// Kasir F&B.
///
/// Tiga tab seperti kasir web: **Menu** (POS), **Diproses**, **Selesai**.
/// Tata letak:
///  - Portrait  : grid menu + keranjang MENGAPUNG.
///  - Landscape lega (tablet) : dua panel — menu kiri, nota kanan.
class KasirScreen extends StatefulWidget {
  const KasirScreen({super.key, this.embedded = false});

  /// true bila dipakai sebagai tab di ShellScreen (tanpa tombol kembali).
  final bool embedded;

  @override
  State<KasirScreen> createState() => _KasirScreenState();
}

enum _Tab { menu, proses, selesai }

class _KasirScreenState extends State<KasirScreen> {
  final _search = TextEditingController();

  _Tab _tab = _Tab.menu;
  List<MenuItem> _menus = [];
  final List<CartLine> _cart = [];
  String _category = 'Semua';
  bool _loading = true;
  String? _error;

  // Daftar nota untuk tab Diproses / Selesai.
  List<Map<String, dynamic>> _orders = [];
  bool _ordersLoading = false;

  // Printer & antrean offline.
  SavedPrinter? _printer;
  int _pending = 0;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshPrinter();
    _refreshPending();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refreshPrinter() async {
    final p = await PrinterService.saved();
    if (mounted) setState(() => _printer = p);
  }

  Future<void> _refreshPending() async {
    final n = await OfflineQueue.count();
    if (mounted) setState(() => _pending = n);
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

  Future<void> _loadOrders() async {
    setState(() => _ordersLoading = true);
    try {
      final status = _tab == _Tab.proses ? 'pending,cooking,served' : 'completed';
      final list = await FnbService.ordersByStatus(status);
      if (mounted) setState(() => _orders = list);
    } catch (e) {
      if (mounted) Notify.toast(context, ApiClient.errorMessage(e), success: false);
    } finally {
      if (mounted) setState(() => _ordersLoading = false);
    }
  }

  void _switchTab(_Tab t) {
    setState(() => _tab = t);
    if (t != _Tab.menu) _loadOrders();
  }

  // ------------------------------------------------------------------ printer
  /// Sambungkan/pilih printer langsung dari kasir (tanpa buka Pengaturan).
  Future<void> _printerAction() async {
    final p = _printer;

    if (p == null) {
      // Belum ada printer -> arahkan ke Pengaturan untuk memilih.
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PengaturanScreen()),
      );
      await _refreshPrinter();

      return;
    }

    // Sudah ada printer -> uji sambungan dengan struk tes.
    Notify.showLoader(context, 'Menyambung printer...');
    try {
      await PrinterService.printBytes(await PrinterService.buildTestReceipt());
      if (!mounted) return;
      Navigator.of(context).pop();
      Notify.toast(context, 'Printer "${p.name}" tersambung.');
    } on PrinterException catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      Notify.toast(context, e.message, success: false);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      Notify.toast(context, 'Gagal menyambung: $e', success: false);
    }
  }

  Future<void> _printOrder(int id) async {
    try {
      final payload = await SettingsService.receipt(id);
      await PrinterService.printBytes(await PrinterService.buildReceipt(payload));
      if (mounted) Notify.toast(context, 'Struk dikirim ke printer.');
    } on PrinterException catch (e) {
      if (mounted) Notify.toast(context, e.message, success: false);
    } catch (e) {
      if (mounted) Notify.toast(context, ApiClient.errorMessage(e), success: false);
    }
  }

  // ------------------------------------------------------------------ offline
  Future<void> _syncOffline() async {
    setState(() => _syncing = true);
    try {
      final r = await OfflineQueue.sync();
      if (mounted) {
        Notify.toast(
          context,
          'Sinkron selesai: ${r.saved} masuk, ${r.skipped} dilewati.',
        );
      }
      await _refreshPending();
      if (_tab != _Tab.menu) await _loadOrders();
    } catch (e) {
      if (mounted) Notify.toast(context, ApiClient.errorMessage(e), success: false);
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  // -------------------------------------------------------------------- kasir
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
    final done = await showPaymentDialog(context, _cart);
    if (done == true && mounted) {
      setState(() => _cart.clear());
      await _refreshPending();
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final landscape = size.width > size.height;

    // Dua panel hanya untuk layar lega (tablet); di ponsel rotasi dikunci potret.
    final twoPane = _tab == _Tab.menu && landscape && size.width >= 900;

    final panelWidth = size.width < 1100 ? 300.0 : 360.0;
    final gridWidth = twoPane ? size.width - panelWidth - 36 : size.width;
    final cols = (gridWidth / 190).floor().clamp(2, 6);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            if (_pending > 0) _offlineBanner(),
            _tabs(),
            if (_tab == _Tab.menu) _searchAndChips(),
            Expanded(
              child: switch (_tab) {
                _Tab.menu => twoPane
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _grid(cols: cols)),
                          SizedBox(width: panelWidth, child: _orderPanel()),
                        ],
                      )
                    : _grid(cols: cols),
                _ => _orderList(),
              },
            ),
          ],
        ),
      ),
      floatingActionButton:
          (_tab == _Tab.menu && !twoPane && _cart.isNotEmpty) ? _floatingCart() : null,
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
            _printerChip(),
            const SizedBox(width: 8),
            ClayTappable(
              onTap: _tab == _Tab.menu ? _load : _loadOrders,
              radius: 100,
              padding: const EdgeInsets.all(12),
              child: const Icon(LucideIcons.refreshCw, size: 18, color: MoodaTheme.ink),
            ),
          ],
        ),
      );

  /// Status printer + aksi sambung, langsung di layar kasir.
  Widget _printerChip() {
    final p = _printer;
    final active = p != null;

    return ClayTappable(
      onTap: _printerAction,
      radius: 100,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(
            active ? LucideIcons.printer : LucideIcons.printerCheck,
            size: 16,
            color: active ? MoodaTheme.success : MoodaTheme.muted,
          ),
          const SizedBox(width: 6),
          Text(
            active ? 'Printer' : 'Pilih printer',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: active ? MoodaTheme.success : MoodaTheme.muted,
            ),
          ),
        ],
      ),
    );
  }

  /// Pemberitahuan pesanan yang tertahan karena jaringan mati.
  Widget _offlineBanner() => Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
        child: ClayBox(
          radius: MoodaTheme.radius,
          color: const Color(0xFFFFF7E6),
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              const Icon(LucideIcons.cloudOff, size: 18, color: Color(0xFF9A6700)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$_pending pesanan menunggu sinkron',
                  style: const TextStyle(
                    color: Color(0xFF9A6700),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _syncing ? null : _syncOffline,
                child: Text(
                  _syncing ? 'Menyinkron...' : 'Sinkron',
                  style: const TextStyle(
                    color: MoodaTheme.primary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _tabs() => Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
        child: Row(
          children: [
            for (final t in _Tab.values) ...[
              Expanded(
                child: ClayTappable(
                  onTap: () => _switchTab(t),
                  radius: 100,
                  color: _tab == t ? MoodaTheme.primary : null,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Center(
                    child: Text(
                      switch (t) {
                        _Tab.menu => 'Menu',
                        _Tab.proses => 'Diproses',
                        _Tab.selesai => 'Selesai',
                      },
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: _tab == t ? Colors.white : MoodaTheme.ink,
                      ),
                    ),
                  ),
                ),
              ),
              if (t != _Tab.selesai) const SizedBox(width: 9),
            ],
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

  // ---------------------------------------------------------------- tab: menu
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
      itemBuilder: (_, i) => FadeSlideIn(index: i, child: _menuCard(items[i])),
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
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: MoodaTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
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
                  : ListView(children: [for (final l in _cart) _panelLine(l)]),
            ),
            const Divider(height: 20),
            Row(
              children: [
                const Expanded(
                  child: Text('Subtotal',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: MoodaTheme.ink,
                          fontSize: 13)),
                ),
                Text(Rupiah.format(_preview), style: MoodaTheme.number(size: 18)),
              ],
            ),
            const SizedBox(height: 2),
            const Text('pajak & promo dihitung server',
                style: TextStyle(color: MoodaTheme.muted, fontSize: 10)),
            const SizedBox(height: 14),
            ClayButton(
              label: 'Lanjut',
              icon: LucideIcons.arrowRight,
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
                  Text(line.menu.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: MoodaTheme.ink,
                          fontSize: 12.5)),
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

  // ------------------------------------------------- tab: diproses & selesai
  Widget _orderList() {
    if (_ordersLoading) return const Center(child: CircularProgressIndicator());

    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset('assets/svg/illus-empty.svg', height: 130),
            const SizedBox(height: 14),
            Text(
              _tab == _Tab.proses
                  ? 'Tidak ada pesanan yang sedang diproses'
                  : 'Belum ada pesanan selesai',
              textAlign: TextAlign.center,
              style: const TextStyle(color: MoodaTheme.muted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
      itemCount: _orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => FadeSlideIn(index: i, child: _orderCard(_orders[i])),
    );
  }

  Widget _orderCard(Map<String, dynamic> o) {
    final id = (o['id'] as num).toInt();
    final paid = o['payment_status'] == 'paid';
    final status = '${o['order_status']}';

    return ClayBox(
      radius: MoodaTheme.radiusLg,
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: (paid ? MoodaTheme.success : const Color(0xFFF97316))
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '#${o['queue_number']}',
                  style: TextStyle(
                    color: paid ? MoodaTheme.success : const Color(0xFFF97316),
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${o['customer_name'] ?? 'Pelanggan'}'
                      '${o['table_no'] != null ? ' · Meja ${o['table_no']}' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: MoodaTheme.ink,
                          fontSize: 13.5),
                    ),
                    Text(
                      '$status · ${paid ? (o['payment_method'] ?? 'lunas') : 'belum lunas'}',
                      style: const TextStyle(color: MoodaTheme.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                Rupiah.format(((o['grand_total'] ?? 0) as num).toDouble()),
                style: MoodaTheme.number(size: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (!paid)
                Expanded(
                  child: _action('Bayar', LucideIcons.creditCard, () => _payDialog(o)),
                ),
              if (paid && status != 'completed')
                Expanded(
                  child: _action('Selesaikan', LucideIcons.checkCheck, () async {
                    await _run(() => FnbService.completeOrder(id), 'Pesanan selesai.');
                  }),
                ),
              if (paid) ...[
                const SizedBox(width: 9),
                Expanded(
                  child: _action('Cetak', LucideIcons.printer, () => _printOrder(id)),
                ),
              ],
              const SizedBox(width: 9),
              _action(
                'Salah',
                LucideIcons.ban,
                () async {
                  final yes = await Notify.confirm(
                    context,
                    title: 'Tandai pesanan salah?',
                    message: 'Nota tetap tersimpan, tapi tidak dihitung ke omzet & kas.',
                    confirmLabel: 'Ya, tandai',
                    icon: LucideIcons.ban,
                    color: MoodaTheme.danger,
                  );
                  if (yes) {
                    await _run(() => FnbService.voidOrder(id), 'Pesanan ditandai salah.');
                  }
                },
                danger: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action(String label, IconData icon, VoidCallback onTap,
          {bool danger = false}) =>
      ClayTappable(
        onTap: onTap,
        radius: MoodaTheme.radius,
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 15, color: danger ? MoodaTheme.danger : MoodaTheme.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: danger ? MoodaTheme.danger : MoodaTheme.primary,
              ),
            ),
          ],
        ),
      );

  /// Bayar nota yang belum lunas dari daftar (tunai/QRIS).
  Future<void> _payDialog(Map<String, dynamic> o) async {
    final id = (o['id'] as num).toInt();
    final total = ((o['grand_total'] ?? 0) as num).toDouble();
    final cash = TextEditingController();
    var method = 'cash';

    final ok = await showAnimatedDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: ClayBox(
              radius: 26,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Bayar ${Rupiah.format(total)}',
                      style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: MoodaTheme.ink)),
                  Text('Antrian #${o['queue_number']} · ${o['invoice_no']}',
                      style: const TextStyle(color: MoodaTheme.muted, fontSize: 11.5)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      for (final m in ['cash', 'qris']) ...[
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setLocal(() => method = m),
                            child: ClayBox(
                              radius: MoodaTheme.radius,
                              blur: 12,
                              color: method == m ? MoodaTheme.primary : null,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              child: Center(
                                child: Text(
                                  m == 'cash' ? 'Tunai' : 'QRIS',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color:
                                        method == m ? Colors.white : MoodaTheme.ink,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (m == 'cash') const SizedBox(width: 10),
                      ],
                    ],
                  ),
                  if (method == 'cash') ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: cash,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Uang diterima'),
                    ),
                  ],
                  const SizedBox(height: 18),
                  ClayButton(
                    label: 'Bayar',
                    icon: LucideIcons.check,
                    height: 50,
                    onPressed: () => Navigator.of(ctx).pop(true),
                  ),
                  const SizedBox(height: 10),
                  ClayButton(
                    label: 'Batal',
                    color: MoodaTheme.bg,
                    textColor: MoodaTheme.muted,
                    height: 46,
                    onPressed: () => Navigator.of(ctx).pop(false),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (ok != true) return;

    await _run(
      () => FnbService.payOrder(
        id,
        method,
        cashReceived: method == 'cash'
            ? (double.tryParse(cash.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
            : null,
      ),
      'Pembayaran tersimpan.',
    );
  }

  /// Jalankan aksi lalu segarkan daftar; tampilkan pesan server bila gagal.
  Future<void> _run(Future<void> Function() action, String successMessage) async {
    try {
      await action();
      if (mounted) Notify.toast(context, successMessage);
      await _loadOrders();
    } catch (e) {
      if (mounted) Notify.toast(context, ApiClient.errorMessage(e), success: false);
    }
  }
}
