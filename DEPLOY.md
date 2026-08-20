# Distribusi mooda-fe (APK)

mooda-fe **tidak** dideploy ke server. Ia dibuild jadi **APK** yang menembak
**`https://api.mooda.id/api/v1`**, lalu dibagikan ke pengguna.

## 1. Setup sekali (mesin build)
```bash
cd mooda-fe
flutter create . --org id.mooda --project-name mooda_fe --platforms=android,web
flutter pub get
```

## 2. Signing (rilis) — JANGAN commit keystore
```bash
keytool -genkey -v -keystore mooda-release.jks -keyalg RSA -keysize 2048 \
        -validity 10000 -alias mooda
```
Buat `android/key.properties` (sudah di-`.gitignore`):
```properties
storePassword=****
keyPassword=****
keyAlias=mooda
storeFile=/path/absolut/mooda-release.jks
```
Sambungkan di `android/app/build.gradle` (blok `signingConfigs.release` → `buildTypes.release`).

## 3. Build APK produksi (arah ke api.mooda.id)
```bash
flutter build apk --release \
  --dart-define=API_BASE=https://api.mooda.id/api/v1 \
  --dart-define=VERTICAL=fnb
# hasil: build/app/outputs/flutter-apk/app-release.apk
```
> App Bundle utk Play Store: `flutter build appbundle --release --dart-define=...`

## 4. Distribusi (pilih)
- **Unduh langsung**: taruh APK di stakko-pos `public/downloads/` (mis. `mooda-dine.apk`)
  → tautan `https://mooda.id/downloads/mooda-dine.apk`. (Pola yang sama dgn `mooda-pos.apk`.)
- **Google Play**: unggah `.aab` ke Play Console.

## Catatan
- Ganti `API_BASE` hanya via `--dart-define` saat build — tidak ada URL server yang
  di-hardcode di kode. Debug lokal otomatis `http://127.0.0.1:8080/api/v1`.
- Autentikasi pakai **Bearer token** (bukan cookie), jadi tak ada isu CORS/domain untuk APK.
