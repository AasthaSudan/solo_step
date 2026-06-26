import 'itinerary_activity.dart';

/// Domain entity representing a single day within an itinerary.
class ItineraryDay {
  final int dayNumber;
  final List<ItineraryActivity> activities;
  final String stayName;
  final double stayCost;
  final List<String> foodSuggestions;

  const ItineraryDay({
    required this.dayNumber,
    required this.activities,
    required this.stayName,
    required this.stayCost,
    required this.foodSuggestions,
  });
}
