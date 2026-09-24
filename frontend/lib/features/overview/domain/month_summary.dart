class DaySpend {
  final DateTime date;
  final int amountPaise;
  const DaySpend({required this.date, required this.amountPaise});

  factory DaySpend.fromJson(Map<String, dynamic> json) => DaySpend(
        date: DateTime.parse(json['date'] as String),
        amountPaise: json['amountPaise'] as int,
      );

  Map<String, dynamic> toJson() => {
        'date': date.toUtc().toIso8601String(),
        'amountPaise': amountPaise,
      };
}

class MonthSummary {
  final String month; // "YYYY-MM"
  final int totalPaise;
  final int lastMonthTotalPaise;
  final Map<String, int> byCategory; // categoryId -> paise
  final List<DaySpend> byDay;

  const MonthSummary({
    required this.month,
    required this.totalPaise,
    required this.lastMonthTotalPaise,
    required this.byCategory,
    required this.byDay,
  });

  /// Empty-state summary for a month with zero transactions.
  factory MonthSummary.empty(String month) => MonthSummary(
        month: month,
        totalPaise: 0,
        lastMonthTotalPaise: 0,
        byCategory: const {},
        byDay: const [],
      );

  bool get isEmpty => totalPaise == 0 && byDay.isEmpty;

  double get monthOverMonthPct {
    if (lastMonthTotalPaise == 0) return 0;
    return ((totalPaise - lastMonthTotalPaise) / lastMonthTotalPaise) * 100;
  }

  factory MonthSummary.fromJson(Map<String, dynamic> json) => MonthSummary(
        month: json['month'] as String,
        totalPaise: json['totalPaise'] as int,
        lastMonthTotalPaise: json['lastMonthTotalPaise'] as int? ?? 0,
        byCategory: Map<String, int>.from(json['byCategory'] as Map),
        byDay: (json['byDay'] as List)
            .map((e) => DaySpend.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'month': month,
        'totalPaise': totalPaise,
        'lastMonthTotalPaise': lastMonthTotalPaise,
        'byCategory': byCategory,
        'byDay': byDay.map((e) => e.toJson()).toList(),
      };
}
