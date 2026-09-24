import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spend_wise/core/utils/money.dart';
import 'package:spend_wise/features/merchants/state/merchant_providers.dart';
import 'package:spend_wise/features/transactions/widgets/transaction_tile.dart';

class MerchantDetailScreen extends ConsumerWidget {
  final String merchantName;
  final String month;
  const MerchantDetailScreen({super.key, required this.merchantName, required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(merchantHistoryProvider((month: month, merchant: merchantName)));

    return Scaffold(
      appBar: AppBar(title: Text(merchantName)),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (txns) {
          if (txns.isEmpty) return const Center(child: Text('No history found'));
          final total = txns.fold<int>(0, (s, t) => s - t.amountPaise);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total spent', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          Text(Money.rupees(total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Visits', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          Text('${txns.length}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...txns.map((t) => TransactionTile(txn: t)),
            ],
          );
        },
      ),
    );
  }
}
