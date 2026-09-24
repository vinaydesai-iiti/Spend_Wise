import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spend_wise/core/network/api_client.dart';
import 'package:spend_wise/core/network/error_mapper.dart';
import 'package:spend_wise/features/budgets/domain/budget.dart';

class BudgetRepository {
  final Dio _dio;
  BudgetRepository(this._dio);

  /// GET /budgets?month= — progress bars per category. F4. `spentPaise`
  /// is computed server-side from the real transactions for the month,
  /// so it always matches the Feed/Overview totals to the paise.
  Future<List<Budget>> getBudgets(String month) async {
    try {
      final res = await _dio.get('/budgets', queryParameters: {'month': month});
      return (res.data['items'] as List)
          .map((e) => Budget.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  /// PUT /budgets?month= — set a category limit. Server returns 422 with
  /// a message (surfaced via [ErrorMapper]) when the amount is invalid.
  Future<void> setBudget({
    required String categoryId,
    required String month,
    required int limitPaise,
  }) async {
    try {
      await _dio.put('/budgets', queryParameters: {'month': month}, data: {
        'category': categoryId,
        'limitPaise': limitPaise,
      });
    } on DioException catch (e) {
      throw ErrorMapper.map(e);
    }
  }
}

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(ref.watch(apiClientProvider));
});
