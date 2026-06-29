import '../entities/debrief_card.dart';
import '../../../budget/domain/entities/budget_summary.dart';
import '../../../budget/domain/entities/expense.dart';

abstract interface class DebriefRepository {
  Future<DebriefCard> generateAndSaveDebrief({
    required String tripId,
    required BudgetSummary summary,
    required List<Expense> expenses,
  });
}
