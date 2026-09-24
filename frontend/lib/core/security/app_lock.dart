import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How long the app can sit in the background before the next resume
/// requires re-authentication — a baseline security requirement, since
/// money and identity screens must not be left exposed indefinitely.
const Duration kAppLockTimeout = Duration(seconds: 30);

/// State is `true` while the app should show the lock screen over
/// everything else. Uses the `WidgetsBindingObserver` mixin (not
/// `implements`) so it only needs to override the two lifecycle hooks it
/// actually cares about; every other observer callback is a no-op.
class AppLockController extends StateNotifier<bool> with WidgetsBindingObserver {
  DateTime? _backgroundedAt;

  AppLockController() : super(false) {
    WidgetsBinding.instance.addObserver(this);
  }

  bool get isLocked => state;

  void unlock() => state = false;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.paused ||
        lifecycleState == AppLifecycleState.inactive) {
      _backgroundedAt ??= DateTime.now();
    } else if (lifecycleState == AppLifecycleState.resumed) {
      final backgroundedAt = _backgroundedAt;
      if (backgroundedAt != null &&
          DateTime.now().difference(backgroundedAt) >= kAppLockTimeout) {
        state = true;
      }
      _backgroundedAt = null;
    }
  }
}

final appLockControllerProvider = StateNotifierProvider<AppLockController, bool>((ref) {
  return AppLockController();
});
