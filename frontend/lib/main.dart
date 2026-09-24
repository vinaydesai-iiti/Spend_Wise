import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spend_wise/app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Session restore happens inside features/auth/state/auth_provider.dart:
  // AuthNotifier reads the saved JWT (if any) from SecureSessionStore the
  // moment it's first created — which app/router.dart triggers on its
  // very first redirect check, right as the app starts.
  runApp(const ProviderScope(child: SpendWiseApp()));
}
