import 'itinerary_day.dart';

/// Domain entity representing a complete multi-day travel itinerary.
class Itinerary {
  final List<ItineraryDay> days;

  const Itinerary({
    required this.days,
  });

  Map<String, dynamic> toMap() {
    return {
      'days': days.map((x) => x.toMap()).toList(),
    };
  }

  factory Itinerary.fromMap(Map<String, dynamic> map) {
    return Itinerary(
      days: List<ItineraryDay>.from(
        (map['days'] as List<dynamic>? ?? []).map<ItineraryDay>(
          (x) => ItineraryDay.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }
}
