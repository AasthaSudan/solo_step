import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/budget_summary.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../data/repositories/fake_expense_repository_impl.dart';

// 1. Repository Provider
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return FakeExpenseRepositoryImpl(); // Fake implementation for now
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
final budgetProvider = AsyncNotifierProvider<BudgetNotifier, BudgetState>(BudgetNotifier.new);

class BudgetNotifier extends AsyncNotifier<BudgetState> {
  // Hardcoded trip ID for the demo since we aren't managing auth/trips strictly yet
  static const String _activeTripId = 'mock_trip_1';

  StreamSubscription<List<Expense>>? _subscription;

  @override
  Future<BudgetState> build() async {
    final repo = ref.watch(expenseRepositoryProvider);
    
    // Listen to the stream of expenses
    _subscription?.cancel();
    _subscription = repo.watchExpenses(_activeTripId).listen((expenses) async {
      final summary = await repo.summaryFor(_activeTripId);
      state = AsyncData(BudgetState(summary: summary, expenses: expenses));
    });

    // Initial load
    final initialSummary = await repo.summaryFor(_activeTripId);
    
    // The stream will yield the initial list immediately in our Fake implementation,
    // but just to be safe, we'll initialize with an empty list until the stream fires.
    // In a real app we might await the first stream element.
    return BudgetState(summary: initialSummary, expenses: []);
  }

  Future<void> logSpend(SpendCategory category, int amountInr) async {
    final repo = ref.read(expenseRepositoryProvider);
    final expense = Expense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tripId: _activeTripId,
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
    final repo = ref.read(expenseRepositoryProvider);
    if (repo is FakeExpenseRepositoryImpl) {
      repo.applyReplanSavings(savings);
    }
  }
}
