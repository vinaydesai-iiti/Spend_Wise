/// Every repository in SpendWise throws only [BankError] — screens never
/// need to know about Dio, sockets, or HTTP status codes directly.
///
/// Turning a raw DioException into a [BankError] is done by
/// `core/network/error_mapper.dart`'s `ErrorMapper`, so this file has no
/// dependency on `dio` at all.
class BankError implements Exception {
  final String message;
  final int? statusCode;
  final BankErrorType type;

  const BankError({
    required this.message,
    required this.type,
    this.statusCode,
  });

  @override
  String toString() => 'BankError($type): $message';
}

enum BankErrorType { timeout, offline, validation, unauthorized, server, unknown }
