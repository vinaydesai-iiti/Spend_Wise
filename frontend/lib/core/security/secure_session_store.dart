import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// What comes back out of secure storage on a successful read.
/// Kept as raw JSON here (rather than an `AppUser`) so `core/` has no
/// dependency on `features/auth/` — decoding into a domain model is the
/// auth feature's job.
class StoredSession {
  final String accessToken;
  final String? refreshToken;
  final Map<String, dynamic> userJson;

  const StoredSession({
    required this.accessToken,
    this.refreshToken,
    required this.userJson,
  });
}

/// Persists the signed-in session (JWT + refresh token + user) in the
/// platform keychain/keystore — never in `shared_preferences` — since
/// this is exactly the kind of identity data FLAG_SECURE / secure
/// storage guidance calls out.
class SecureSessionStore {
  final FlutterSecureStorage _storage;

  SecureSessionStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  static const _kAccessToken = 'sw_access_token';
  static const _kRefreshToken = 'sw_refresh_token';
  static const _kUser = 'sw_user_json';

  Future<void> save({
    required String accessToken,
    String? refreshToken,
    required Map<String, dynamic> userJson,
  }) async {
    await _storage.write(key: _kAccessToken, value: accessToken);
    await _storage.write(key: _kRefreshToken, value: refreshToken);
    await _storage.write(key: _kUser, value: jsonEncode(userJson));
  }

  /// Returns null when there is no saved session, or when what's stored
  /// can no longer be parsed (in which case it's wiped so the app falls
  /// back to a clean sign-out rather than crashing on restore).
  Future<StoredSession?> read() async {
    final token = await _storage.read(key: _kAccessToken);
    final userStr = await _storage.read(key: _kUser);
    if (token == null || userStr == null) return null;
    try {
      final userJson = jsonDecode(userStr) as Map<String, dynamic>;
      final refresh = await _storage.read(key: _kRefreshToken);
      return StoredSession(accessToken: token, refreshToken: refresh, userJson: userJson);
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> clear() async {
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kRefreshToken);
    await _storage.delete(key: _kUser);
  }
}

final secureSessionStoreProvider = Provider<SecureSessionStore>((ref) => SecureSessionStore());
