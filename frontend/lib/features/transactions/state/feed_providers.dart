import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spend_wise/features/transactions/domain/transaction.dart';
import 'package:spend_wise/features/transactions/data/transaction_repository.dart';
import 'package:spend_wise/features/transactions/state/filter_providers.dart';

/// feed.family(month) — combines the current month with whatever is in
/// filterStateNotifier (search / category / amount / date), so F3's
/// "tapping a donut slice filters the feed" is just a category filter
/// update; this provider recomputes and the Feed screen re-renders.
final feedProvider = FutureProvider.family<List<Txn>, String>((ref, month) async {
  final repo = ref.watch(transactionRepositoryProvider);
  final filters = ref.watch(filterStateNotifierProvider);

  var txns = await repo.getFeed(
    month: month,
    category: filters.categoryId,
    query: filters.query,
  );

  if (filters.minAmountPaise != null) {
    txns = txns.where((t) => -t.amountPaise >= filters.minAmountPaise!).toList();
  }
  if (filters.maxAmountPaise != null) {
    txns = txns.where((t) => -t.amountPaise <= filters.maxAmountPaise!).toList();
  }
  final range = filters.dateRange;
  if (range != null) {
    txns = txns.where((t) => !t.at.isBefore(range.start) && !t.at.isAfter(range.end)).toList();
  }
  return txns;
});

/// Transactions grouped by day, for the sticky day-header list (F1).
final feedGroupedProvider = FutureProvider.family<Map<String, List<Txn>>, String>((ref, month) async {
  final txns = await ref.watch(feedProvider(month).future);
  final grouped = <String, List<Txn>>{};
  for (final t in txns) {
    final key = '${t.at.year}-${t.at.month.toString().padLeft(2, '0')}-${t.at.day.toString().padLeft(2, '0')}';
    grouped.putIfAbsent(key, () => []).add(t);
  }
  return grouped;
});
