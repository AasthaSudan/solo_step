import 'proposed_swap.dart';
import '../../../itinerary/domain/entities/itinerary.dart';

class ReplanResult {
  final List<ProposedSwap> swaps;
  final Itinerary newItinerary;

  const ReplanResult({
    required this.swaps,
    required this.newItinerary,
  });
}
