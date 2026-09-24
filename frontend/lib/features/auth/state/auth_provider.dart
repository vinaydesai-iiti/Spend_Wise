import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spend_wise/core/errors/bank_error.dart';
import 'package:spend_wise/core/security/secure_session_store.dart';
import 'package:spend_wise/core/state/session_token_provider.dart';
import 'package:spend_wise/features/auth/data/auth_repository.dart';
import 'package:spend_wise/features/auth/domain/auth_models.dart';
enum AuthStatus {
  /// Still restoring a saved session — the router shows a splash screen.
  unknown,
  authenticated,
  unauthenticated,
}

class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final String? accessToken;
  final bool isSubmitting;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.accessToken,
    this.isSubmitting = false,
    this.error,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated && accessToken != null;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? accessToken,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Owns the session for the whole app.
///
/// - Screens read [authProvider] for state: signed in?, current user,
///   whether a login is in flight.
/// - `core/network/api_client.dart`'s interceptor reads the JWT — via
///   `sessionTokenProvider`, which this class keeps in sync — to attach
///   `Authorization: Bearer <token>` to every other API call.
/// - The JWT is persisted through [SecureSessionStore] so a relaunch
///   restores the session instead of bouncing back to `/login`.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  final SecureSessionStore _store;
  final Ref _ref;

  AuthNotifier(this._repo, this._store, this._ref) : super(const AuthState()) {
    _restore();
  }

  Future<void> _restore() async {
    final saved = await _store.read();
    if (saved == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    _ref.read(sessionTokenProvider.notifier).state = saved.accessToken;
    state = AuthState(
      status: AuthStatus.authenticated,
      user: AppUser.fromJson(saved.userJson),
      accessToken: saved.accessToken,
    );
  }

  /// Signs in, persists the JWT, and makes it available to every other
  /// repository via [sessionTokenProvider]. Returns null on success, or
  /// the [BankError] to show on failure.
  Future<BankError?> login({required String email, required String password}) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final result = await _repo.login(email: email, password: password);
      await _store.save(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        userJson: result.user.toJson(),
      );
      _ref.read(sessionTokenProvider.notifier).state = result.accessToken;
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result.user,
        accessToken: result.accessToken,
      );
      return null;
    } on BankError catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.message);
      return e;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    await _store.clear();
    _ref.read(sessionTokenProvider.notifier).state = null;
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(secureSessionStoreProvider),
    ref,
  );
});
