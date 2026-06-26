import '../../domain/entities/proposed_swap.dart';
import '../../domain/repositories/replan_repository.dart';
import '../../../budget/domain/entities/expense.dart';

class FakeReplanRepositoryImpl implements ReplanRepository {
  @override
  Future<List<ProposedSwap>> requestReplan({
    required String tripId,
    required int remainingBudgetInr,
  }) async {
    // Simulate Gemini generation delay
    await Future.delayed(const Duration(seconds: 2));

    return const [
      ProposedSwap(
        oldTitle: 'Kerala Buffet Dinner at Premium Restaurant',
        oldCost: 1200,
        newTitle: 'Kerala Street Food Walk & Cafe Dinner',
        newCost: 350,
        category: SpendCategory.food,
      ),
      ProposedSwap(
        oldTitle: 'Private Jeep Safari & Sightseeing Tour',
        oldCost: 2500,
        newTitle: 'Shared Jeep Safari & Nature Trail Walk',
        newCost: 600,
        category: SpendCategory.activity,
      ),
      ProposedSwap(
        oldTitle: 'Private AC Cab tour to Tea Gardens',
        oldCost: 1800,
        newTitle: 'Shared Auto-rickshaw & Tea Museum walk',
        newCost: 400,
        category: SpendCategory.transport,
      ),
    ];
  }
}
