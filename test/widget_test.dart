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
    await tester.pumpWidget(const MoodaApp());

    // Selesaikan pembacaan token (async) lalu render ulang.
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Masuk ke akunmu'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
  });
}
