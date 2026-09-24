import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spend_wise/core/state/month_provider.dart';
import 'package:spend_wise/core/utils/date_format.dart';
import 'package:spend_wise/core/utils/money.dart';
import 'package:spend_wise/features/budgets/domain/budget.dart';
import 'package:spend_wise/features/budgets/state/budgets_providers.dart';
import 'package:spend_wise/mock/mock_data.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(monthProvider);
    final budgetsAsync = ref.watch(budgetsProvider(month));

    return Scaffold(
      appBar: AppBar(title: Text('Budgets · ${DateFmt.monthLabel(month)}')),
      body: budgetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (budgets) {
          if (budgets.isEmpty) {
            return const Center(child: Text('No budgets set yet'));
          }
          final sorted = [...budgets]..sort((a, b) => b.progress.compareTo(a.progress));
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _BudgetCard(
              budget: sorted[i],
              onTap: () => context.push('/budgets/${sorted[i].categoryId}'),
            ),
          );
        },
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final Budget budget;
  final VoidCallback onTap;
  const _BudgetCard({required this.budget, required this.onTap});

  Color get _riskColor {
    switch (budget.risk) {
      case BudgetRisk.over:
        return const Color(0xFFE0526A);
      case BudgetRisk.warning:
        return const Color(0xFFF2A93B);
      case BudgetRisk.onTrack:
        return const Color(0xFF2FB380);
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = MockData.instance.categoryById(budget.categoryId);
    final progress = budget.progress.clamp(0, 1).toDouble();

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: category.color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
                    child: Icon(category.icon, color: category.color, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
                  Text(
                    '${(budget.progress * 100).clamp(0, 999).toStringAsFixed(0)}%',
                    style: TextStyle(fontWeight: FontWeight.w700, color: _riskColor, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(_riskColor),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${Money.rupees(budget.spentPaise)} spent', style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
                  Text('of ${Money.rupees(budget.limitPaise)}', style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
