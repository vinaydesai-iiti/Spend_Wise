import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spend_wise/features/overview/data/summary_repository.dart';
import 'package:spend_wise/features/overview/domain/month_summary.dart';

/// summary.family(month) — Overview screen watches this. Riverpod caches
/// each month's result, so switching back to a previously viewed month
/// is instant (F8's "load instantly from cache").
final summaryProvider = FutureProvider.family<MonthSummary, String>((ref, month) async {
  final repo = ref.watch(summaryRepositoryProvider);
  return repo.getSummary(month);
});

final insightsProvider = FutureProvider.family<List<String>, String>((ref, month) async {
  final repo = ref.watch(summaryRepositoryProvider);
  return repo.getInsights(month);
});
