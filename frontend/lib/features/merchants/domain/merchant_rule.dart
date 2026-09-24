/// A learned "this merchant always maps to this category" rule,
/// created when the user taps "Apply to all" on F2 (recategorise).
class MerchantRule {
  final String merchantKey; // normalised merchant string
  final String categoryId;

  const MerchantRule({required this.merchantKey, required this.categoryId});

  factory MerchantRule.fromJson(Map<String, dynamic> json) => MerchantRule(
        merchantKey: json['merchantKey'] as String,
        categoryId: json['category'] as String,
      );

  Map<String, dynamic> toJson() => {
        'merchantKey': merchantKey,
        'category': categoryId,
      };
}
