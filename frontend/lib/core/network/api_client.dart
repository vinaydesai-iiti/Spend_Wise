import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spend_wise/core/network/api_config.dart';
import 'package:spend_wise/core/state/session_token_provider.dart';

/// ---------------------------------------------------------------------
/// ONE Dio instance for the entire app. Every repository (Auth,
/// Transaction, Summary, Budget, Merchant) pulls this same client from
/// Riverpod instead of constructing its own — so the base URL, headers,
/// and auth all live in exactly one place.
///
/// Backend is still in progress, so every repository currently returns
/// mock data and the real `_dio.get/patch/put(...)` calls are left in
/// place but commented out, ready to switch on.
/// ---------------------------------------------------------------------
class ApiClient {
  late final Dio dio;

  ApiClient(Ref ref) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.addAll([
      _AuthInterceptor(ref),
      if (ApiConfig.enableNetworkLogs) LogInterceptor(requestBody: true, responseBody: true),
    ]);
  }
}

/// Attaches `Authorization: Bearer <jwt>` to every outgoing request once
/// the user is signed in. Reads `sessionTokenProvider` at request time
/// (not at construction time), so it always sees the latest token —
/// including the very first request made right after login.
class _AuthInterceptor extends Interceptor {
  final Ref ref;
  _AuthInterceptor(this.ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = ref.read(sessionTokenProvider);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

/// Riverpod provider — every repository reads the SAME Dio instance
/// through this provider rather than creating its own client.
final apiClientProvider = Provider<Dio>((ref) => ApiClient(ref).dio);
