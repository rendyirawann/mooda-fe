import '../core/api_client.dart';

/// Semua panggilan API modul F&B selain kasir (lihat [KasirService] untuk kasir).
/// Sengaja mengembalikan Map/List apa adanya: layar hanya menampilkan, tak
/// menghitung ulang apa pun (perhitungan milik server).
class FnbService {
  FnbService._();

  static List<Map<String, dynamic>> _list(dynamic data) =>
      (data as List? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

  // ---------------- Dapur ----------------
  static Future<List<Map<String, dynamic>>> kitchenQueue() async {
    final r = await ApiClient.dio.get('/fnb/kitchen/orders');
    return _list(r.data['data']);
  }

  static Future<void> itemStatus(int itemId, String status) =>
      ApiClient.dio.post('/fnb/kitchen/items/$itemId/status', data: {'status': status});

  static Future<void> orderStatus(int orderId, String status) =>
      ApiClient.dio.post('/fnb/kitchen/orders/$orderId/status', data: {'status': status});

  // ---------------- Pesanan ----------------
  static Future<List<Map<String, dynamic>>> orders({String? paymentStatus}) async {
    final r = await ApiClient.dio.get('/fnb/orders', queryParameters: {
      if (paymentStatus != null) 'payment_status': paymentStatus,
    });
    return _list(r.data['data']);
  }

  static Future<Map<String, dynamic>> order(int id) async {
    final r = await ApiClient.dio.get('/fnb/orders/$id');
    return Map<String, dynamic>.from(r.data['data'] as Map);
  }

  // ---------------- Meja ----------------
  static Future<List<Map<String, dynamic>>> tables() async {
    final r = await ApiClient.dio.get('/fnb/tables');
    return _list(r.data['data']);
  }

  static Future<void> addTable(String name, {String? area, int? capacity}) =>
      ApiClient.dio.post('/fnb/tables', data: {
        'name': name,
        if (area != null && area.isNotEmpty) 'area': area,
        if (capacity != null) 'capacity': capacity,
      });

  // ---------------- Inventory ----------------
  static Future<List<Map<String, dynamic>>> ingredients({String? q, bool low = false}) async {
    final r = await ApiClient.dio.get('/fnb/inventory/ingredients', queryParameters: {
      if (q != null && q.isNotEmpty) 'q': q,
      if (low) 'low': true,
    });
    return _list(r.data['data']);
  }

  static Future<Map<String, dynamic>> ingredientCard(int id) async {
    final r = await ApiClient.dio.get('/fnb/inventory/ingredients/$id/card');
    return Map<String, dynamic>.from(r.data['data'] as Map);
  }

  static Future<void> addIngredient(String name, String unit, double min) =>
      ApiClient.dio.post('/fnb/inventory/ingredients',
          data: {'name': name, 'unit': unit, 'minimum_stock': min});

  /// Stok masuk (butuh total pembelian) atau keluar (waste/rusak/koreksi).
  static Future<Map<String, dynamic>> movement({
    required int ingredientId,
    required String type,
    required double quantity,
    double? buyPriceTotal,
    String? reason,
    String? expiryDate,
  }) async {
    final r = await ApiClient.dio.post('/fnb/inventory/movements', data: {
      'ingredient_id': ingredientId,
      'type': type,
      'quantity': quantity,
      if (type == 'in') 'buy_price_total': buyPriceTotal,
      if (type == 'out' && reason != null) 'reason': reason,
      if (expiryDate != null && expiryDate.isNotEmpty) 'expiry_date': expiryDate,
    });
    return Map<String, dynamic>.from(r.data as Map);
  }

  // ---------------- Menu & Resep ----------------
  static Future<List<Map<String, dynamic>>> menus() async {
    final r = await ApiClient.dio.get('/fnb/menus');
    return _list(r.data['data']);
  }

  static Future<Map<String, dynamic>> recipe(int menuId) async {
    final r = await ApiClient.dio.get('/fnb/recipes/$menuId');
    return Map<String, dynamic>.from(r.data['data'] as Map);
  }

  // ---------------- Beranda / Akun ----------------
  /// Ringkasan beranda: hari ini vs kemarin, tren 7 hari, transaksi terbaru.
  static Future<Map<String, dynamic>> dashboard() async {
    final r = await ApiClient.dio.get('/fnb/reports/dashboard');
    return Map<String, dynamic>.from(r.data['data'] as Map);
  }

  static Future<Map<String, dynamic>> tenant() async {
    final r = await ApiClient.dio.get('/account/tenant');
    return Map<String, dynamic>.from(r.data['data'] as Map);
  }

  // ---------------- Laporan ----------------
  static Future<Map<String, dynamic>> sales({String? from, String? to}) async {
    final r = await ApiClient.dio.get('/fnb/reports/sales', queryParameters: {
      if (from != null) 'from': from,
      if (to != null) 'to': to,
    });
    return Map<String, dynamic>.from(r.data['data'] as Map);
  }

  static Future<Map<String, dynamic>> hpp({String? from, String? to}) async {
    final r = await ApiClient.dio.get('/fnb/reports/hpp', queryParameters: {
      if (from != null) 'from': from,
      if (to != null) 'to': to,
    });
    return Map<String, dynamic>.from(r.data['data'] as Map);
  }

  // ---------------- Shift ----------------
  /// null bila belum ada shift terbuka (server balas 404).
  static Future<Map<String, dynamic>?> currentShift() async {
    try {
      final r = await ApiClient.dio.get('/shifts/current');
      return Map<String, dynamic>.from(r.data['data'] as Map);
    } catch (e) {
      if (ApiClient.statusCode(e) == 404) return null;
      rethrow;
    }
  }

  static Future<void> openShift(double startingCash) =>
      ApiClient.dio.post('/shifts/open', data: {'starting_cash': startingCash});

  static Future<void> closeShift(double actualCash) =>
      ApiClient.dio.post('/shifts/close', data: {'actual_cash': actualCash});
}
