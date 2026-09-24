

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spend_wise/core/network/api_client.dart';
import 'package:spend_wise/core/network/error_mapper.dart';
import 'package:spend_wise/features/auth/domain/auth_models.dart';

class AuthRepository {
  final Dio _dio;
  AuthRepository(this._dio);

  /// POST /auth/login — { email, password } -> { accessToken, refreshToken?, user }.
  Future<AuthResult> login({required String email, required String password}) async {
    try {
      final res = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      return AuthResult.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  /// POST /auth/register — { name, email, password } -> { accessToken, refreshToken?, user }.
  /// Not wired to a screen yet (the shipped UI only has a login screen),
  /// but exposed so a future sign-up flow has a ready-made repository call.
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
      });
      return AuthResult.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  /// POST /auth/logout — best-effort; the local session is cleared by
  /// the caller regardless of whether this succeeds. Must be called
  /// while the JWT is still set on [sessionTokenProvider], since the
  /// server needs `Authorization: Bearer <token>` to know which
  /// refresh token to invalidate.
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } on DioException {
      // Ignore — we still clear the local session.
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});
