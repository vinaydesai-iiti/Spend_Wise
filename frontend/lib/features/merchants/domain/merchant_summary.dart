/// Per-merchant aggregate for the Merchants screen (F6): total spent,
/// how many visits, and the derived average spend per visit.
class MerchantSummary {
  final String merchantName;
  final String categoryId;
  final int totalPaise;
  final int visitCount;

  const MerchantSummary({
    required this.merchantName,
    required this.categoryId,
    required this.totalPaise,
    required this.visitCount,
  });

  int get averagePaise => visitCount == 0 ? 0 : (totalPaise / visitCount).round();
}
