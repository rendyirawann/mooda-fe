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
