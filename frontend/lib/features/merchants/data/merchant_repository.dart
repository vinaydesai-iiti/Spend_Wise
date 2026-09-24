import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spend_wise/core/network/api_client.dart';
import 'package:spend_wise/core/network/error_mapper.dart';
import 'package:spend_wise/features/merchants/domain/merchant_summary.dart';
import 'package:spend_wise/features/transactions/domain/transaction.dart';

class MerchantRepository {
  final Dio _dio;
  MerchantRepository(this._dio);

  /// GET /merchants?month= — per-merchant totals, visits, average. F6.
  /// Sorted by total descending server-side (the default per P05 §4).
  Future<List<MerchantSummary>> getMerchants(String month) async {
    try {
      final res = await _dio.get('/merchants', queryParameters: {'month': month});
      return (res.data['items'] as List)
          .map((e) => MerchantSummary(
                merchantName: e['merchantName'] as String,
                categoryId: e['category'] as String,
                totalPaise: e['totalPaise'] as int,
                visitCount: e['visitCount'] as int,
              ))
          .toList();
    } on DioException catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  /// GET /merchants/{merchantName}/history?month= — a merchant's
  /// transactions for the month, backing the Merchant detail screen.
  Future<List<Txn>> getMerchantHistory(String month, String merchantName) async {
    try {
      final res = await _dio.get(
        '/merchants/${Uri.encodeComponent(merchantName)}/history',
        queryParameters: {'month': month},
      );
      final items = (res.data as Map<String, dynamic>)['items'] as List;
      return items.map((e) => Txn.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ErrorMapper.map(e);
    }
  }
}

final merchantRepositoryProvider = Provider<MerchantRepository>((ref) {
  return MerchantRepository(ref.watch(apiClientProvider));
});
