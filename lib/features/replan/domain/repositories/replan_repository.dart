import '../entities/replan_result.dart';
import '../../../itinerary/domain/entities/itinerary.dart';

abstract interface class ReplanRepository {
  Future<ReplanResult> requestReplan({
    required String tripId,
    required int remainingBudgetInr,
  });

  Future<void> acceptReplan({
    required String tripId,
    required Itinerary newItinerary,
  });
}
