import 'package:flutter/services.dart';

import 'package:intl/intl.dart';

/// Util format Rupiah / angka untuk seluruh UI.
class Rupiah {
  Rupiah._();
  static final _f = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  static String format(num v) => _f.format(v);
}

/// Pemformat input uang: menambahkan titik ribuan OTOMATIS saat mengetik.
///
/// Nilai yang dipakai program tetap angka murni — pakai [digits] untuk
/// mengambilnya kembali dari teks yang sudah bertitik.
class RupiahInputFormatter extends TextInputFormatter {
  const RupiahInputFormatter();

  /// Ambil angka murni dari teks bertitik ("1.500.000" -> 1500000).
  static double digits(String text) =>
      double.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  /// Ubah angka menjadi teks bertitik ("1500000" -> "1.500.000").
  static String group(String raw) {
    final s = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (s.isEmpty) return '';

    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }

    return buf.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = group(newValue.text);

    // Kursor selalu di akhir: paling wajar untuk input nominal.
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
