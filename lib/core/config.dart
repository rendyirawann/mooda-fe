/// Konfigurasi global Mooda FE.
///
/// Base URL API di-inject saat build (tidak hardcode ke server):
///   Dev  : default 127.0.0.1 (mooda-be `php artisan serve --port=8080`)
///   Prod : flutter build apk --dart-define=API_BASE=https://api.mooda.id/api/v1
class AppConfig {
  AppConfig._();

  /// Endpoint API mooda-be. Semua request FE mengarah ke sini.
  static const String apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://127.0.0.1:8080/api/v1',
  );

  /// Vertical aktif build ini (fnb / laundry). Default dine.
  static const String vertical = String.fromEnvironment(
    'VERTICAL',
    defaultValue: 'fnb',
  );

  static const String appName = 'Mooda';
  static const String tagline = 'Kelola bisnismu dari genggaman';
}
