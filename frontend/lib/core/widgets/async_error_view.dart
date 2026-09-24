import 'package:flutter/material.dart';

/// Shared "something went wrong" card used wherever a screen watches a
/// `FutureProvider`/`AsyncValue` and needs to render its `error` case.
class AsyncErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AsyncErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFE0526A)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
            if (onRetry != null) ...[
              const SizedBox(height: 10),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
