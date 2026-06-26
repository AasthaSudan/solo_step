/// Domain entity representing a single activity in a day's itinerary.
class ItineraryActivity {
  final String time; // 'morning' | 'afternoon' | 'evening'
  final String title;
  final String category; // 'sightseeing' | 'food' | 'transport' | 'stay' | 'activity'
  final double estimatedCost;
  final String notes;

  const ItineraryActivity({
    required this.time,
    required this.title,
    required this.category,
    required this.estimatedCost,
    required this.notes,
  });
}
