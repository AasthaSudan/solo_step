import 'dart:async';
import '../../domain/entities/expense.dart';
import '../../domain/entities/budget_summary.dart';
import '../../domain/repositories/expense_repository.dart';

class FakeExpenseRepositoryImpl implements ExpenseRepository {
  // Hardcoded mock values that mimic the previous UI state
  static const int _totalBudget = 18000;
  static const int _dailyTarget = 6000;
  static const int _estimatedToDate = 3600;

  int _replanSavings = 0;

  final List<Expense> _expenses = [
    Expense(
      id: 'e1',
      tripId: 'mock_trip_1',
      day: 2,
      category: SpendCategory.food,
      label: 'Dinner at spice garden',
      amountInr: 620,
      spentAt: DateTime.now().subtract(const Duration(hours: 4)),
      synced: true,
    ),
    Expense(
      id: 'e2',
      tripId: 'mock_trip_1',
      day: 2,
      category: SpendCategory.transport,
      label: 'Auto-rickshaw to hotel',
      amountInr: 180,
      spentAt: DateTime.now().subtract(const Duration(hours: 2)),
      synced: true,
    ),
    Expense(
      id: 'e3',
      tripId: 'mock_trip_1',
      day: 2,
      category: SpendCategory.activity,
      label: 'Elephant sanctuary entry',
      amountInr: 350,
      spentAt: DateTime.now().subtract(const Duration(hours: 1)),
      synced: true,
    ),
    // Padding out the rest of the 4200 "normal" spend so we match the previous _normalSpent = 4200
    Expense(
      id: 'e4',
      tripId: 'mock_trip_1',
      day: 1,
      category: SpendCategory.stay,
      label: 'Hotel booking',
      amountInr: 3050,
      spentAt: DateTime.now().subtract(const Duration(days: 1)),
      synced: true,
    ),
  ];

  final StreamController<List<Expense>> _expensesController =
      StreamController<List<Expense>>.broadcast();

  FakeExpenseRepositoryImpl() {
    _expensesController.add(List.unmodifiable(_expenses));
  }

  @override
  Future<void> logExpense(Expense e) async {
    // Simulate slight local DB delay
    await Future.delayed(const Duration(milliseconds: 100));
    _expenses.insert(0, e);
    _expensesController.add(List.unmodifiable(_expenses));
  }

  @override
  Stream<List<Expense>> watchExpenses(String tripId) {
    return _expensesController.stream;
  }

  @override
  Future<void> syncPending() async {
    // Fake implementation does nothing
  }

  @override
  Future<BudgetSummary> summaryFor(String tripId) async {
    // Simulate slight DB read
    await Future.delayed(const Duration(milliseconds: 100));
    
    int totalSpent = 0;
    for (var e in _expenses) {
      if (e.tripId == tripId) {
        totalSpent += e.amountInr;
      }
    }

    return BudgetSummary(
      totalBudgetInr: _totalBudget,
      dailyTargetInr: _dailyTarget,
      spentInr: totalSpent,
      estimatedToDateInr: _estimatedToDate + _replanSavings, // artificially increase estimate to fix pacing bar
    );
  }

  // Backdoor for mocking replan success
  void applyReplanSavings(int savings) {
    _replanSavings += savings;
    _expensesController.add(List.unmodifiable(_expenses)); // trigger UI update
  }

  void dispose() {
    _expensesController.close();
  }
}
