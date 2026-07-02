/// Domain entity representing a single activity in a day's itinerary.
class ItineraryActivity {
  final String time; // 'morning' | 'afternoon' | 'evening'
  final String title;
  final String category; // 'sightseeing' | 'food' | 'transport' | 'stay' | 'activity'
  final double estimatedCost;
  final String notes;
  final String? googleMapsQuery;
  final double? latitude;
  final double? longitude;
  final String? transitInstructions;
  final String? imageUrl;
  final String? bookingLink;

  const ItineraryActivity({
    required this.time,
    required this.title,
    required this.category,
    required this.estimatedCost,
    required this.notes,
    this.googleMapsQuery,
    this.latitude,
    this.longitude,
    this.transitInstructions,
    this.imageUrl,
    this.bookingLink,
  });

  Map<String, dynamic> toMap() {
    return {
      'time': time,
      'title': title,
      'category': category,
      'estimatedCost': estimatedCost,
      'notes': notes,
      if (googleMapsQuery != null) 'googleMapsQuery': googleMapsQuery,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (transitInstructions != null) 'transitInstructions': transitInstructions,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (bookingLink != null) 'bookingLink': bookingLink,
    };
  }

  factory ItineraryActivity.fromMap(Map<String, dynamic> map) {
    return ItineraryActivity(
      time: map['time'] as String? ?? '',
      title: map['title'] as String? ?? '',
      category: map['category'] as String? ?? '',
      estimatedCost: (map['estimatedCost'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] as String? ?? '',
      googleMapsQuery: map['googleMapsQuery'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      transitInstructions: map['transitInstructions'] as String?,
      imageUrl: map['imageUrl'] as String?,
      bookingLink: map['bookingLink'] as String?,
    );
  }
}
