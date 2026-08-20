import '../core/api_client.dart';
import '../core/session.dart';

/// Autentikasi mobile via Sanctum token (mooda-be).
class AuthService {
  AuthService._();

  static Future<void> login(String email, String password) async {
    final res = await ApiClient.dio.post('/auth/login', data: {
      'email': email,
      'password': password,
      'device_name': 'mooda-mobile',
    });
    final body = res.data is Map ? res.data as Map : {};
    final data = (body['data'] ?? body) as Map;
    final token = data['token'] ?? data['access_token'];
    if (token == null) {
      throw Exception('Respons login tidak memuat token.');
    }
    final name = (data['user'] is Map) ? data['user']['name'] : null;
    await Session.save(token: '$token', name: name?.toString());
  }

  static Future<Map<String, dynamic>> me() async {
    final res = await ApiClient.dio.get('/auth/me');
    final body = res.data is Map ? res.data as Map : {};
    return Map<String, dynamic>.from((body['data'] ?? body) as Map);
  }

  static Future<void> logout() async {
    try {
      await ApiClient.dio.post('/auth/logout');
    } catch (_) {
      /* abaikan; tetap bersihkan lokal */
    }
    await Session.clear();
  }
}
