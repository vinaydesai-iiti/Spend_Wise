import 'package:dio/dio.dart';
import 'package:spend_wise/core/errors/bank_error.dart';

/// Maps a low-level [DioException] (or anything else) into a [BankError].
/// Every repository calls `ErrorMapper.map(e)` inside its `on DioException`
/// handler once the real API calls are switched back on.
class ErrorMapper {
  const ErrorMapper._();

  static BankError map(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const BankError(
          message: 'The request timed out. Please check your connection.',
          type: BankErrorType.timeout,
        );
      case DioExceptionType.connectionError:
        return const BankError(
          message: 'You appear to be offline.',
          type: BankErrorType.offline,
        );
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 401) {
          return const BankError(
            message: 'Your session has expired. Please sign in again.',
            type: BankErrorType.unauthorized,
            statusCode: 401,
          );
        }
        if (code == 422) {
          return BankError(
            message: e.response?.data is Map
                ? (e.response?.data['message'] as String? ?? 'That value is invalid.')
                : 'That value is invalid.',
            type: BankErrorType.validation,
            statusCode: 422,
          );
        }
        return BankError(
          message: 'Something went wrong on our end (code $code).',
          type: BankErrorType.server,
          statusCode: code,
        );
      default:
        return const BankError(
          message: 'Something unexpected happened.',
          type: BankErrorType.unknown,
        );
    }
  }
}
