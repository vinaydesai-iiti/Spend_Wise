import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The current JWT access token, or null when signed out.
///
/// This lives in `core/` (not in `features/auth/`) on purpose: the auth
/// interceptor in `core/network/api_client.dart` needs to read the token
/// for every request, and `core/` must never depend on `features/`.
/// `features/auth/state/auth_provider.dart` is the single writer — it
/// updates this provider on login, on session restore, and on logout.
final sessionTokenProvider = StateProvider<String?>((ref) => null);
