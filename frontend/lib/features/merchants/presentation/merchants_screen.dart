import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spend_wise/core/state/month_provider.dart';
import 'package:spend_wise/core/utils/date_format.dart';
import 'package:spend_wise/core/utils/money.dart';
import 'package:spend_wise/features/merchants/domain/merchant_summary.dart';
import 'package:spend_wise/features/merchants/state/merchant_providers.dart';
import 'package:spend_wise/mock/mock_data.dart';

class MerchantsScreen extends ConsumerWidget {
  const MerchantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(monthProvider);
    final merchantsAsync = ref.watch(merchantsProvider(month));

    return Scaffold(
      appBar: AppBar(title: Text('Merchants · ${DateFmt.monthLabel(month)}')),
      body: merchantsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (merchants) {
          if (merchants.isEmpty) {
            return const Center(child: Text('No merchants this month'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: merchants.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) => _MerchantRow(
              m: merchants[i],
              onTap: () => context.push('/merchants/${Uri.encodeComponent(merchants[i].merchantName)}', extra: month),
            ),
          );
        },
      ),
    );
  }
}

class _MerchantRow extends StatelessWidget {
  final MerchantSummary m;
  final VoidCallback onTap;
  const _MerchantRow({required this.m, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final category = MockData.instance.categoryById(m.categoryId);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: category.color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(13)),
              child: Icon(category.icon, color: category.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.merchantName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text('${m.visitCount} visits · avg ${Money.rupees(m.averagePaise)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Text(Money.rupees(m.totalPaise), style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
