import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spend_wise/features/merchants/data/merchant_repository.dart';
import 'package:spend_wise/features/merchants/domain/merchant_summary.dart';
import 'package:spend_wise/features/transactions/domain/transaction.dart';

/// Merchants screen — sorted by total by default (F6).
final merchantsProvider = FutureProvider.family<List<MerchantSummary>, String>((ref, month) async {
  final repo = ref.watch(merchantRepositoryProvider);
  return repo.getMerchants(month);
});

final merchantHistoryProvider =
    FutureProvider.family<List<Txn>, ({String month, String merchant})>((ref, args) async {
  final repo = ref.watch(merchantRepositoryProvider);
  return repo.getMerchantHistory(args.month, args.merchant);
});

// Note: the "apply to all" learned mappings from F2 (MerchantRule) are now
// tracked server-side (see backend/src/models/MerchantRule.js) rather than
// in a local list, and no shipped screen currently reads them directly —
// the effect is simply that matching merchants are already recategorised
// when their transactions/history are fetched. A `merchantRulesProvider`
// backed by a `GET /merchants/rules` endpoint would be the way to surface
// them explicitly (e.g. "auto-categorised as X") if a screen needs to.
