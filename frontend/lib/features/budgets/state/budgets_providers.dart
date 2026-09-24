import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spend_wise/core/errors/bank_error.dart';
import 'package:spend_wise/features/budgets/data/budget_repository.dart';
import 'package:spend_wise/features/budgets/domain/budget.dart';

/// budgetsProvider — F4. Screens watch this; the Budget edit screen reads
/// budgetActionsProvider's notifier to save, then invalidates this family
/// entry so the Budgets screen's progress bars refresh.
final budgetsProvider = FutureProvider.family<List<Budget>, String>((ref, month) async {
  final repo = ref.watch(budgetRepositoryProvider);
  return repo.getBudgets(month);
});

class BudgetActions {
  final Ref ref;
  BudgetActions(this.ref);

  Future<BankError?> save({
    required String categoryId,
    required String month,
    required int limitPaise,
  }) async {
    try {
      await ref.read(budgetRepositoryProvider).setBudget(
            categoryId: categoryId,
            month: month,
            limitPaise: limitPaise,
          );
      ref.invalidate(budgetsProvider(month));
      return null;
    } on BankError catch (e) {
      return e;
    }
  }
}

final budgetActionsProvider = Provider<BudgetActions>((ref) => BudgetActions(ref));
