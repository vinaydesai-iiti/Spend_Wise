import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spend_wise/core/state/month_provider.dart';
import 'package:spend_wise/core/utils/date_format.dart';
import 'package:spend_wise/features/budgets/state/budgets_providers.dart';
import 'package:spend_wise/mock/mock_data.dart';

class BudgetEditScreen extends ConsumerStatefulWidget {
  final String categoryId;
  const BudgetEditScreen({super.key, required this.categoryId});

  @override
  ConsumerState<BudgetEditScreen> createState() => _BudgetEditScreenState();
}

class _BudgetEditScreenState extends ConsumerState<BudgetEditScreen> {
  late final TextEditingController _controller;
  String? error;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final month = ref.read(monthProvider);
    final budgets = ref.read(budgetsProvider(month)).valueOrNull ?? [];
    final existing = budgets.where((b) => b?.categoryId == widget.categoryId);
    final startValue = existing.isNotEmpty ? existing.first.limitPaise ~/ 100 : 0;
    _controller = TextEditingController(text: startValue == 0 ? '' : startValue.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final category = MockData.instance.categoryById(widget.categoryId);
    final month = ref.watch(monthProvider);

    return Scaffold(
      appBar: AppBar(title: Text('${category.name} budget')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: category.color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
                  child: Icon(category.icon, color: category.color),
                ),
                const SizedBox(width: 12),
                Text('Monthly limit for ${DateFmt.monthLabel(month)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.black87),
                errorText: error,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: saving ? null : () => _save(month),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save budget'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(String month) async {
    final rupees = int.tryParse(_controller.text.trim());
    if (rupees == null || rupees <= 0) {
      setState(() => error = 'Enter an amount greater than ₹0');
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    final result = await ref.read(budgetActionsProvider).save(
          categoryId: widget.categoryId,
          month: month,
          limitPaise: rupees * 100,
        );
    if (!mounted) return;
    if (result != null) {
      setState(() {
        saving = false;
        error = result.message;
      });
      return;
    }
    Navigator.of(context).pop();
  }
}
