import 'itinerary_activity.dart';

/// Domain entity representing a single day within an itinerary.
class ItineraryDay {
  final int dayNumber;
  final List<ItineraryActivity> activities;
  final String stayName;
  final double stayCost;
  final String? stayMapsQuery;
  final List<String> foodSuggestions;

  const ItineraryDay({
    required this.dayNumber,
    required this.activities,
    required this.stayName,
    required this.stayCost,
    this.stayMapsQuery,
    required this.foodSuggestions,
  });

  Map<String, dynamic> toMap() {
    return {
      'dayNumber': dayNumber,
      'activities': activities.map((x) => x.toMap()).toList(),
      'stayName': stayName,
      'stayCost': stayCost,
      if (stayMapsQuery != null) 'stayMapsQuery': stayMapsQuery,
      'foodSuggestions': foodSuggestions,
    };
  }

  factory ItineraryDay.fromMap(Map<String, dynamic> map) {
    return ItineraryDay(
      dayNumber: map['dayNumber'] as int? ?? 1,
      activities: List<ItineraryActivity>.from(
        (map['activities'] as List<dynamic>? ?? []).map<ItineraryActivity>(
          (x) => ItineraryActivity.fromMap(x as Map<String, dynamic>),
        ),
      ),
      stayName: map['stayName'] as String? ?? '',
      stayCost: (map['stayCost'] as num?)?.toDouble() ?? 0.0,
      stayMapsQuery: map['stayMapsQuery'] as String?,
      foodSuggestions: List<String>.from(map['foodSuggestions'] as List<dynamic>? ?? []),
    );
  }
}
