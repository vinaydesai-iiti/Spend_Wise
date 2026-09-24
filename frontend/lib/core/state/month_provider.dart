import 'package:flutter_riverpod/flutter_riverpod.dart';

String _currentMonthKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
}

/// The month currently shown across Overview / Feed / Budgets ("YYYY-MM").
/// F8 — swiping between months just updates this single notifier; every
/// screen watching a `.family(month)` provider recomputes automatically,
/// and previously viewed months are served straight from cache (see the
/// `.family` providers, which Riverpod keeps alive per-argument).
class MonthNotifier extends StateNotifier<String> {
  MonthNotifier() : super(_currentMonthKey());

  void next() => state = _shift(1);
  void previous() => state = _shift(-1);
  void set(String month) => state = month;

  String _shift(int delta) {
    final parts = state.split('-').map(int.parse).toList();
    var y = parts[0];
    var m = parts[1] + delta;
    while (m < 1) {
      m += 12;
      y -= 1;
    }
    while (m > 12) {
      m -= 12;
      y += 1;
    }
    return '$y-${m.toString().padLeft(2, '0')}';
  }
}

final monthProvider = StateNotifierProvider<MonthNotifier, String>((ref) {
  return MonthNotifier();
});
