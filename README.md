# Mooda FE — Mobile (F&B / Dine)

Frontend **Flutter** untuk Mooda. **Ringan & only-hit-API** — semua data diambil dari
`mooda-be` (Swagger di `api.mooda.id`). Repo ini **khusus mobile & build APK**, tidak
di-deploy ke server.

## Konsep
- Tidak ada logika bisnis di sini. FE hanya memanggil endpoint mooda-be.
- Tema & modul disamakan dengan web stakko-pos, tapi tata letak mobile.
- Base URL API di-inject saat build (tidak hardcode ke server).

## Prasyarat
- Flutter SDK 3.3+ (`flutter --version`).

## Setup pertama (generate folder platform)
Repo ini hanya berisi `lib/`, `pubspec.yaml`, dst. Generate folder platform:

```bash
cd mooda-fe
flutter create . --org id.mooda --project-name mooda_fe --platforms=android,web
flutter pub get
```

## Menjalankan (debug)

Web (dipakai .bat dev):
```bash
flutter run -d web-server --web-hostname=127.0.0.1 --web-port=8090 \
  --dart-define=API_BASE=http://127.0.0.1:8080/api/v1
```

Android (device/emulator):
```bash
flutter run --dart-define=API_BASE=http://10.0.2.2:8080/api/v1
```
> Emulator Android memakai `10.0.2.2` untuk menjangkau `127.0.0.1` host.

## Build APK (produksi → api.mooda.id)
```bash
flutter build apk --release \
  --dart-define=API_BASE=https://api.mooda.id/api/v1 \
  --dart-define=VERTICAL=fnb
```

## Struktur
```
lib/
  core/      config, theme (warna Mooda), api_client (dio), session (token), format (Rupiah)
  services/  auth_service (login/me/logout via Sanctum token)
  screens/   login, dashboard (grid modul), module_placeholder
  main.dart  gate token -> Login / Dashboard
```

## Menambah modul
1. Buat `screens/<modul>_screen.dart`.
2. Panggil `ApiClient.dio.get('/endpoint')` (token otomatis dilampirkan).
3. Tambahkan kartu di `dashboard_screen.dart`.
