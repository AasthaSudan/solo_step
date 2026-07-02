import '../entities/expense.dart';
import '../entities/budget_summary.dart';

abstract interface class ExpenseRepository {
  Future<void> logExpense(Expense e);
  Stream<List<Expense>> watchExpenses(String tripId);
  Future<void> syncPending(); // Mapped to Firestore, though not implemented in Fake
  Future<BudgetSummary> summaryFor(String tripId);
  Future<void> setTripBudget(String tripId, int budgetInr);
}
