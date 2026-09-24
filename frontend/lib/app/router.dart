import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spend_wise/app/app_shell.dart';
import 'package:spend_wise/app/routes.dart';
import 'package:spend_wise/core/state/month_provider.dart';
import 'package:spend_wise/features/auth/presentation/login_screen.dart';
import 'package:spend_wise/features/auth/state/auth_provider.dart';
import 'package:spend_wise/features/budgets/presentation/budget_edit_screen.dart';
import 'package:spend_wise/features/budgets/presentation/budgets_screen.dart';
import 'package:spend_wise/features/merchants/presentation/merchant_detail_screen.dart';
import 'package:spend_wise/features/merchants/presentation/merchants_screen.dart';
import 'package:spend_wise/features/overview/presentation/overview_screen.dart';
import 'package:spend_wise/features/transactions/presentation/feed_screen.dart';
import 'package:spend_wise/features/transactions/presentation/transaction_detail_screen.dart';

/// Session guard: while a saved session is still being restored, every
/// route stays on `/splash`; once restore finishes, unauthenticated users
/// are bounced to `/login` and authenticated users are bounced away from
/// `/login`/`/splash` into the app shell.
final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _GoRouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loc = state.matchedLocation;

      if (auth.status == AuthStatus.unknown) {
        return loc == Routes.splash ? null : Routes.splash;
      }
      if (auth.status == AuthStatus.unauthenticated) {
        return loc == Routes.login ? null : Routes.login;
      }
      // authenticated
      if (loc == Routes.login || loc == Routes.splash) return Routes.overview;
      return null;
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (context, state) => const _SplashScreen()),
      GoRoute(path: Routes.login, builder: (context, state) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: Routes.overview,
            builder: (context, state) => const OverviewScreen(),
          ),
          GoRoute(
            path: Routes.transactions,
            builder: (context, state) => const FeedScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  final month = state.extra as String? ?? _fallbackMonth(ref);
                  return TransactionDetailScreen(txnId: id, month: month);
                },
              ),
            ],
          ),
          GoRoute(
            path: Routes.budgets,
            builder: (context, state) => const BudgetsScreen(),
            routes: [
              GoRoute(
                path: ':category',
                builder: (context, state) {
                  final category = state.pathParameters['category']!;
                  return BudgetEditScreen(categoryId: category);
                },
              ),
            ],
          ),
          GoRoute(
            path: Routes.merchants,
            builder: (context, state) => const MerchantsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final name = Uri.decodeComponent(state.pathParameters['id']!);
                  final month = state.extra as String? ?? _fallbackMonth(ref);
                  return MerchantDetailScreen(merchantName: name, month: month);
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

String _fallbackMonth(Ref ref) => ref.read(monthProvider);

/// Bridges `authProvider` (a Riverpod StateNotifier) to go_router's
/// `Listenable`-based `refreshListenable`, so a login/logout re-runs the
/// redirect above even when it happens without a navigation call.
class _GoRouterRefreshNotifier extends ChangeNotifier {
  _GoRouterRefreshNotifier(Ref ref) {
    ref.listen(authProvider, (previous, next) {
      if (previous?.status != next.status) notifyListeners();
    });
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
