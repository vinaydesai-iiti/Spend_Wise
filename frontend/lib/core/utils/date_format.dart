import 'package:intl/intl.dart';

class DateFmt {
  static String dayHeader(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(d.year, d.month, d.day);
    if (that == today) return 'Today';
    if (that == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('EEEE, d MMM').format(d);
  }

  static String time(DateTime d) => DateFormat('h:mm a').format(d);

  static String monthLabel(String monthKey) {
    final parts = monthKey.split('-').map(int.parse).toList();
    return DateFormat('MMMM yyyy').format(DateTime(parts[0], parts[1]));
  }
}
