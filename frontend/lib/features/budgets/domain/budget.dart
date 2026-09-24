class Budget {
  final String categoryId;
  final String month; // "YYYY-MM"
  final int limitPaise;
  final int spentPaise;

  const Budget({
    required this.categoryId,
    required this.month,
    required this.limitPaise,
    required this.spentPaise,
  });

  double get progress => limitPaise <= 0 ? 0 : (spentPaise / limitPaise).clamp(0, 2).toDouble();

  /// amber at >=80%, red at >=100%, otherwise the app's normal accent.
  BudgetRisk get risk {
    if (progress >= 1.0) return BudgetRisk.over;
    if (progress >= 0.8) return BudgetRisk.warning;
    return BudgetRisk.onTrack;
  }

  Budget copyWith({int? limitPaise, int? spentPaise}) => Budget(
        categoryId: categoryId,
        month: month,
        limitPaise: limitPaise ?? this.limitPaise,
        spentPaise: spentPaise ?? this.spentPaise,
      );

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
        categoryId: json['category'] as String,
        month: json['month'] as String,
        limitPaise: json['limitPaise'] as int,
        spentPaise: json['spentPaise'] as int,
      );

  Map<String, dynamic> toJson() => {
        'category': categoryId,
        'month': month,
        'limitPaise': limitPaise,
        'spentPaise': spentPaise,
      };
}

enum BudgetRisk { onTrack, warning, over }
