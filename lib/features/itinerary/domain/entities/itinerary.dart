import 'itinerary_day.dart';
import 'booking_option.dart';
import 'packing_item.dart';

/// Domain entity representing a complete multi-day travel itinerary.
class Itinerary {
  final List<ItineraryDay> days;
  final List<BookingOption> accommodations;
  final List<BookingOption> foodOptions;
  final List<BookingOption> transportOptions;
  final List<PackingItem> packingList;

  const Itinerary({
    required this.days,
    this.accommodations = const [],
    this.foodOptions = const [],
    this.transportOptions = const [],
    this.packingList = const [],
  });

  Itinerary copyWith({
    List<ItineraryDay>? days,
    List<BookingOption>? accommodations,
    List<BookingOption>? foodOptions,
    List<BookingOption>? transportOptions,
    List<PackingItem>? packingList,
  }) {
    return Itinerary(
      days: days ?? this.days,
      accommodations: accommodations ?? this.accommodations,
      foodOptions: foodOptions ?? this.foodOptions,
      transportOptions: transportOptions ?? this.transportOptions,
      packingList: packingList ?? this.packingList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'days': days.map((x) => x.toMap()).toList(),
      'accommodations': accommodations.map((x) => x.toMap()).toList(),
      'foodOptions': foodOptions.map((x) => x.toMap()).toList(),
      'transportOptions': transportOptions.map((x) => x.toMap()).toList(),
      'packingList': packingList.map((x) => x.toMap()).toList(),
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
      transportOptions: List<BookingOption>.from(
        (map['transportOptions'] as List<dynamic>? ?? []).map<BookingOption>(
          (x) => BookingOption.fromMap(x as Map<String, dynamic>),
        ),
      ),
      packingList: List<PackingItem>.from(
        (map['packingList'] as List<dynamic>? ?? []).map<PackingItem>(
          (x) => PackingItem.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }
}
