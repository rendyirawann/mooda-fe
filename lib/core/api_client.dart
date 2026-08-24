import 'package:dio/dio.dart';

import 'config.dart';
import 'session.dart';

/// Satu-satunya pintu keluar HTTP. FE hanya "hit API" ke mooda-be.
class ApiClient {
  ApiClient._();

  static final Dio dio = _build();

  static Dio _build() {
    final d = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBase,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Accept': 'application/json',
          'X-Vertical': AppConfig.vertical,
        },
      ),
    );

    d.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final t = await Session.token();
          if (t != null && t.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $t';
          }
          handler.next(options);
        },
        onError: (e, handler) async {
          // Token kedaluwarsa / tidak valid -> paksa logout lokal.
          if (e.response?.statusCode == 401) {
            await Session.clear();
          }
          handler.next(e);
        },
      ),
    );

    return d;
  }

  /// Kode status HTTP dari sebuah error (null bila gagal sebelum ada respons).
  static int? statusCode(Object e) => e is DioException ? e.response?.statusCode : null;

  /// true bila kegagalan terjadi SEBELUM server menjawab (jaringan mati/putus).
  /// Dipakai kasir untuk menyimpan pesanan ke antrean offline.
  static bool isOffline(Object e) {
    if (e is! DioException) return false;

    return e.response == null &&
        (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.unknown);
  }

  /// Ambil pesan error yang manusiawi dari respons API.
  static String errorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) return '${data['message']}';
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return 'Gagal terhubung ke server. Periksa koneksi / API_BASE.';
      }
      return e.message ?? 'Terjadi kesalahan jaringan.';
    }
    return e.toString();
  }
}
