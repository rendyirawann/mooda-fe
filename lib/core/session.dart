import 'package:shared_preferences/shared_preferences.dart';

/// Penyimpanan token & identitas ringan di device.
class Session {
  Session._();

  static const _kToken = 'mooda_auth_token';
  static const _kName = 'mooda_user_name';

  static Future<void> save({required String token, String? name}) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kToken, token);
    if (name != null) await p.setString(_kName, name);
  }

  static Future<String?> token() async =>
      (await SharedPreferences.getInstance()).getString(_kToken);

  static Future<String?> name() async =>
      (await SharedPreferences.getInstance()).getString(_kName);

  static Future<bool> isLoggedIn() async => (await token()) != null;

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kToken);
    await p.remove(_kName);
  }
}
