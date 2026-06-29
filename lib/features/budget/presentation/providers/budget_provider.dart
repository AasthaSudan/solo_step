import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/budget_summary.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../data/repositories/firestore_expense_repository_impl.dart';

// 1. Repository Provider
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return FirestoreExpenseRepositoryImpl(); 
});

// 2. State object holding both expenses and the summary
class BudgetState {
  final BudgetSummary summary;
  final List<Expense> expenses;

  const BudgetState({
    required this.summary,
    required this.expenses,
  });
}

// 3. The Budget Provider
final budgetProvider = AsyncNotifierProvider.family<BudgetNotifier, BudgetState, String>(BudgetNotifier.new);

class BudgetNotifier extends FamilyAsyncNotifier<BudgetState, String> {
  StreamSubscription<List<Expense>>? _subscription;

  @override
  Future<BudgetState> build(String arg) async {
    final repo = ref.watch(expenseRepositoryProvider);
    
    // Listen to the stream of expenses
    _subscription?.cancel();
    _subscription = repo.watchExpenses(arg).listen((expenses) async {
      final summary = await repo.summaryFor(arg);
      state = AsyncData(BudgetState(summary: summary, expenses: expenses));
    });

    // Initial load
    final initialSummary = await repo.summaryFor(arg);
    
    // The stream will yield the initial list immediately in our Fake implementation,
    // but just to be safe, we'll initialize with an empty list until the stream fires.
    // In a real app we might await the first stream element.
    return BudgetState(summary: initialSummary, expenses: []);
  }

  Future<void> logSpend(SpendCategory category, int amountInr) async {
    final repo = ref.read(expenseRepositoryProvider);
    final expense = Expense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tripId: arg, // arg is the tripId
      day: 2, // Hardcoded for demo
      category: category,
      label: 'Manual entry', // Generic label for manual entries
      amountInr: amountInr,
      spentAt: DateTime.now(),
      synced: false,
    );

    // Optimistically log it
    await repo.logExpense(expense);
  }

  void applyReplanSavings(int savings) {
    // No-op for now, would typically apply savings
    print('Applied savings of ₹$savings');
  }
}
