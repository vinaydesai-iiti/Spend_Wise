import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spend_wise/core/network/error_mapper.dart';
import 'package:spend_wise/core/network/api_client.dart';
import 'package:spend_wise/features/overview/domain/month_summary.dart';

class SummaryRepository {
  final Dio _dio;
  SummaryRepository(this._dio);

  /// GET /summary?month= — totals, category breakdown, daily series. F3.
  Future<MonthSummary> getSummary(String month) async {
    try {
      final res = await _dio.get('/summary', queryParameters: {'month': month});
      return MonthSummary.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  /// GET /insights?month= — server-generated insight cards. F10.
  Future<List<String>> getInsights(String month) async {
    try {
      final res = await _dio.get('/insights', queryParameters: {'month': month});
      return List<String>.from(res.data['cards'] as List);
    } on DioException catch (e) {
      throw ErrorMapper.map(e);
    }
  }
}

final summaryRepositoryProvider = Provider<SummaryRepository>((ref) {
  return SummaryRepository(ref.watch(apiClientProvider));
});
