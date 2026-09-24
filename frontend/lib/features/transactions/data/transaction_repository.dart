import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spend_wise/core/network/error_mapper.dart';
import 'package:spend_wise/core/network/api_client.dart';
import 'package:spend_wise/features/transactions/domain/transaction.dart';

class TransactionRepository {
  final Dio _dio;
  TransactionRepository(this._dio);

  /// GET /transactions?month=&category=&q=&cursor=
  /// Paged, filterable feed. F1 / F7. Response is `{ items, nextCursor }`;
  /// [getFeedPage] exposes both, while [getFeed] (kept for the existing
  /// FutureProvider.family callers) returns just the items of one page.
  Future<({List<Txn> items, String? nextCursor})> getFeedPage({
    required String month,
    String? category,
    String? query,
    String? cursor,
  }) async {
    try {
      final res = await _dio.get('/transactions', queryParameters: {
        'month': month,
        if (category != null) 'category': category,
        if (query != null && query.isNotEmpty) 'q': query,
        if (cursor != null) 'cursor': cursor,
      });
      final data = res.data as Map<String, dynamic>;
      final items = (data['items'] as List)
          .map((e) => Txn.fromJson(e as Map<String, dynamic>))
          .toList();
      return (items: items, nextCursor: data['nextCursor'] as String?);
    } on DioException catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  /// Convenience wrapper over [getFeedPage] for callers (like
  /// `feedProvider`) that only need the first page's items today.
  Future<List<Txn>> getFeed({
    required String month,
    String? category,
    String? query,
    String? cursor,
  }) async {
    final page = await getFeedPage(month: month, category: category, query: query, cursor: cursor);
    return page.items;
  }

  /// PATCH /transactions/{id} — change category, optionally applyToMerchant.
  /// F2. The server also updates every past/future transaction from the
  /// same normalised merchant when [applyToAllMerchant] is true, and
  /// returns which budget alert thresholds (80/100) were newly crossed —
  /// exposed here in case a caller wants to show them.
  Future<List<int>> recategorise({
    required String txnId,
    required String month,
    required String newCategoryId,
    required bool applyToAllMerchant,
  }) async {
    try {
      final res = await _dio.patch('/transactions/$txnId', data: {
        'category': newCategoryId,
        'applyToMerchant': applyToAllMerchant,
      });
      final data = res.data as Map<String, dynamic>;
      return List<int>.from(data['alerts'] as List? ?? const []);
    } on DioException catch (e) {
      throw ErrorMapper.map(e);
    }
  }
}

/// Every repository is built on the SAME shared Dio instance.
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(apiClientProvider));
});
