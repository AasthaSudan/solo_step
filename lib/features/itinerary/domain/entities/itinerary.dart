import 'itinerary_day.dart';
import 'booking_option.dart';

/// Domain entity representing a complete multi-day travel itinerary.
class Itinerary {
  final List<ItineraryDay> days;
  final List<BookingOption> accommodations;
  final List<BookingOption> foodOptions;

  const Itinerary({
    required this.days,
    this.accommodations = const [],
    this.foodOptions = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'days': days.map((x) => x.toMap()).toList(),
      'accommodations': accommodations.map((x) => x.toMap()).toList(),
      'foodOptions': foodOptions.map((x) => x.toMap()).toList(),
    };
  }

  factory Itinerary.fromMap(Map<String, dynamic> map) {
    return Itinerary(
      days: List<ItineraryDay>.from(
        (map['days'] as List<dynamic>? ?? []).map<ItineraryDay>(
          (x) => ItineraryDay.fromMap(x as Map<String, dynamic>),
        ),
      ),
      accommodations: List<BookingOption>.from(
        (map['accommodations'] as List<dynamic>? ?? []).map<BookingOption>(
          (x) => BookingOption.fromMap(x as Map<String, dynamic>),
        ),
      ),
      foodOptions: List<BookingOption>.from(
        (map['foodOptions'] as List<dynamic>? ?? []).map<BookingOption>(
          (x) => BookingOption.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }
}
