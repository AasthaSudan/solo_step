import 'itinerary_day.dart';

/// Domain entity representing a complete multi-day travel itinerary.
class Itinerary {
  final List<ItineraryDay> days;

  const Itinerary({
    required this.days,
  });
}
