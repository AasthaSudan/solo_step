import '../entities/proposed_swap.dart';

abstract interface class ReplanRepository {
  Future<List<ProposedSwap>> requestReplan({
    required String tripId,
    required int remainingBudgetInr,
  });
}
