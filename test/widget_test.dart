// Smoke test Mooda FE: pastikan aplikasi bisa dibangun dan layar login tampil
// (tanpa token tersimpan) beserta elemen kuncinya.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mooda_fe/main.dart';
import 'package:mooda_fe/screens/login_screen.dart';

void main() {
  setUp(() {
    // Tanpa token -> aplikasi harus membuka layar Login.
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('menampilkan layar login saat belum ada token', (tester) async {
    // Layar login cukup tinggi; pakai kanvas besar agar tidak overflow saat uji.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MoodaApp());
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Aplikasi Kasir Modern'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Email / Username'), findsOneWidget);
    expect(find.text('Masuk'), findsWidgets);
  });
}
