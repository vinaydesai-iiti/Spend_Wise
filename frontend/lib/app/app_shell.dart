import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spend_wise/app/routes.dart';

/// Wraps Overview / Feed / Budgets / Merchants with a persistent bottom
/// nav bar, per the spec's 6-screen presentation layer routed through
/// go_router.
class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const _tabs = [Routes.overview, Routes.transactions, Routes.budgets, Routes.merchants];

  int _indexForLocation(String location) {
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _indexForLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => context.go(_tabs[i]),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart_rounded), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Transactions'),
          BottomNavigationBarItem(icon: Icon(Icons.savings_rounded), label: 'Budgets'),
          BottomNavigationBarItem(icon: Icon(Icons.storefront_rounded), label: 'Merchants'),
        ],
      ),
    );
  }
}
