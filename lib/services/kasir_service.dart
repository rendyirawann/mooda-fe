import '../core/api_client.dart';

/// Menu dari API (harga akhir dihitung server).
class MenuItem {
  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.available,
    this.category,
  });

  final int id;
  final String name;
  final double price;
  final bool available;
  final String? category;

  factory MenuItem.fromJson(Map<String, dynamic> j) => MenuItem(
        id: (j['id'] as num).toInt(),
        name: '${j['name']}',
        // Server mengirim final_price (setelah diskon) bila ada.
        price: ((j['final_price'] ?? j['price']) as num).toDouble(),
        available: j['available'] == true,
        category: j['category']?.toString(),
      );
}

/// Satu baris keranjang. Total TIDAK dihitung di sini untuk pembayaran —
/// server yang berwenang; angka lokal hanya untuk pratinjau.
class CartLine {
  CartLine({required this.menu, this.qty = 1, this.note});

  final MenuItem menu;
  int qty;
  String? note;

  double get preview => menu.price * qty;
}

/// Hasil pesanan/pembayaran dari server.
class OrderResult {
  OrderResult({
    required this.id,
    required this.invoiceNo,
    required this.queueNumber,
    required this.subtotal,
    required this.tax,
    required this.grandTotal,
    required this.paymentStatus,
    this.changeAmount = 0,
    this.stockWarnings = const [],
  });

  final int id;
  final String invoiceNo;
  final int queueNumber;
  final double subtotal;
  final double tax;
  final double grandTotal;
  final String paymentStatus;
  final double changeAmount;
  final List<String> stockWarnings;

  factory OrderResult.fromJson(Map<String, dynamic> body) {
    final d = (body['data'] ?? {}) as Map;
    final meta = (body['meta'] ?? {}) as Map;
    final warnings = <String>[];
    for (final w in (meta['stock_warnings'] as List? ?? const [])) {
      if (w is Map) warnings.add('${w['ingredient']} kurang ${w['short']}');
    }
    return OrderResult(
      id: (d['id'] as num).toInt(),
      invoiceNo: '${d['invoice_no'] ?? '-'}',
      queueNumber: (d['queue_number'] as num?)?.toInt() ?? 0,
      subtotal: ((d['subtotal'] ?? 0) as num).toDouble(),
      tax: ((d['tax'] ?? 0) as num).toDouble(),
      grandTotal: ((d['grand_total'] ?? 0) as num).toDouble(),
      paymentStatus: '${d['payment_status'] ?? 'unpaid'}',
      changeAmount: ((d['change_amount'] ?? 0) as num).toDouble(),
      stockWarnings: warnings,
    );
  }
}

class KasirService {
  KasirService._();

  /// Daftar menu BERHALAMAN. `hasMore` dipakai untuk memuat halaman berikutnya
  /// saat pengguna menggulir sampai bawah.
  static Future<({List<MenuItem> items, bool hasMore, int page, int total})> menusPage({
    String? query,
    int page = 1,
    int perPage = 30,
  }) async {
    final res = await ApiClient.dio.get('/fnb/menus', queryParameters: {
      if (query != null && query.isNotEmpty) 'q': query,
      'page': page,
      'per_page': perPage,
    });

    final list = (res.data['data'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => MenuItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final meta = Map<String, dynamic>.from((res.data['meta'] ?? const {}) as Map);

    return (
      items: list,
      // Server lama (belum berhalaman) tak mengirim meta -> anggap selesai.
      hasMore: meta['has_more'] == true,
      page: ((meta['page'] ?? page) as num).toInt(),
      total: ((meta['total'] ?? list.length) as num).toInt(),
    );
  }

  /// Halaman pertama saja (dipakai tempat yang tak butuh gulir tanpa batas).
  static Future<List<MenuItem>> menus({String? query}) async =>
      (await menusPage(query: query)).items;

  /// Buat pesanan. [clientTxnId] membuat percobaan ulang aman (idempoten).
  static Future<OrderResult> createOrder({
    required List<CartLine> cart,
    required String clientTxnId,
    String? customerName,
    String? tableNo,
  }) async {
    final res = await ApiClient.dio.post('/fnb/orders', data: {
      'cart': cart
          .map((l) => {
                'menu_id': l.menu.id,
                'qty': l.qty,
                if (l.note != null && l.note!.isNotEmpty) 'note': l.note,
              })
          .toList(),
      if (customerName != null && customerName.isNotEmpty) 'customer_name': customerName,
      if (tableNo != null && tableNo.isNotEmpty) 'table_no': tableNo,
      'client_txn_id': clientTxnId,
    });
    return OrderResult.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  /// Bayar pesanan. Server memvalidasi tunai >= total & memotong stok (FEFO).
  static Future<OrderResult> pay({
    required int orderId,
    required String method, // cash | qris
    double? cashReceived,
  }) async {
    final res = await ApiClient.dio.post('/fnb/orders/$orderId/pay', data: {
      'payment_method': method,
      if (method == 'cash') 'cash_received': cashReceived,
    });
    return OrderResult.fromJson(Map<String, dynamic>.from(res.data as Map));
  }
}
