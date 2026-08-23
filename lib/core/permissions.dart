import 'package:permission_handler/permission_handler.dart';

/// Jenis izin yang dipakai aplikasi.
enum AppPermission { lokasi, kamera, media }

/// Pembungkus permission_handler.
///
/// Deklarasi di AndroidManifest saja tidak cukup: sejak Android 6 izin
/// lokasi/kamera/media harus diminta saat berjalan. Untuk media, Android 13+
/// memakai izin `photos`, sedangkan versi lama memakai `storage` — [request]
/// mencoba keduanya agar aman di semua versi.
class Permissions {
  Permissions._();

  static Future<bool> isGranted(AppPermission p) async {
    switch (p) {
      case AppPermission.lokasi:
        return Permission.locationWhenInUse.isGranted;
      case AppPermission.kamera:
        return Permission.camera.isGranted;
      case AppPermission.media:
        return await Permission.photos.isGranted ||
            await Permission.storage.isGranted;
    }
  }

  static Future<bool> request(AppPermission p) async {
    switch (p) {
      case AppPermission.lokasi:
        return (await Permission.locationWhenInUse.request()).isGranted;
      case AppPermission.kamera:
        return (await Permission.camera.request()).isGranted;
      case AppPermission.media:
        // Android 13+ : READ_MEDIA_IMAGES -> Permission.photos
        final photos = await Permission.photos.request();
        if (photos.isGranted) return true;
        // Android 12 ke bawah : READ_EXTERNAL_STORAGE -> Permission.storage
        return (await Permission.storage.request()).isGranted;
    }
  }

  /// Izin ditolak permanen -> hanya bisa diaktifkan dari Setelan sistem.
  static Future<bool> isPermanentlyDenied(AppPermission p) async {
    switch (p) {
      case AppPermission.lokasi:
        return Permission.locationWhenInUse.isPermanentlyDenied;
      case AppPermission.kamera:
        return Permission.camera.isPermanentlyDenied;
      case AppPermission.media:
        return await Permission.photos.isPermanentlyDenied &&
            await Permission.storage.isPermanentlyDenied;
    }
  }

  static Future<void> openSettings() => openAppSettings();
}
