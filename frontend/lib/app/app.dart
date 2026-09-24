import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spend_wise/app/router.dart';
import 'package:spend_wise/app/theme.dart';
import 'package:spend_wise/core/security/app_lock.dart';
import 'package:spend_wise/core/security/biometric_service.dart';

class SpendWiseApp extends ConsumerWidget {
  const SpendWiseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'SpendWise',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      // Baseline security requirement: re-require auth after the app has
      // been backgrounded past kAppLockTimeout. Sits above the router's
      // Navigator so it covers whatever screen was last on screen.
      builder: (context, child) => _AppLockGate(child: child),
    );
  }
}

class _AppLockGate extends ConsumerWidget {
  final Widget? child;
  const _AppLockGate({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLocked = ref.watch(appLockControllerProvider);
    return Stack(
      children: [
        if (child != null) Positioned.fill(child: child!),
        if (isLocked) const Positioned.fill(child: _LockOverlay()),
      ],
    );
  }
}

class _LockOverlay extends ConsumerWidget {
  const _LockOverlay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline_rounded, size: 48, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                const Text(
                  'SpendWise is locked',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  'Unlock to see your money',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  icon: const Icon(Icons.fingerprint_rounded),
                  label: const Text('Unlock'),
                  onPressed: () async {
                    final biometrics = ref.read(biometricServiceProvider);
                    // Devices/simulators with no biometric hardware enrolled
                    // can't satisfy a biometric check at all — fail open
                    // here rather than permanently trapping the user.
                    if (!await biometrics.isAvailable) {
                      ref.read(appLockControllerProvider.notifier).unlock();
                      return;
                    }
                    final ok = await biometrics.authenticate();
                    if (ok) ref.read(appLockControllerProvider.notifier).unlock();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
