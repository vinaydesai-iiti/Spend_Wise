import 'package:intl/intl.dart';

/// All money fields in the domain are integer paise (per the API contract).
class Money {
  static String rupees(int paise, {bool showSign = false}) {
    final format = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final rupeeValue = paise / 100;
    final formatted = format.format(rupeeValue.abs());
    if (!showSign) return formatted;
    return paise < 0 ? '-$formatted' : '+$formatted';
  }
}
