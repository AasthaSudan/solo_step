enum TripStatus { planning, upcoming, active, completed }

class Trip {
  final String id;
  final String destinationName;
  final String tagline;
  final String dates;
  final TripStatus status;
  final int budget;
  final int spent;
  final int days;
  final String topCategory;
  final DateTime? startDate;
  final DateTime? endDate;

  const Trip({
    required this.id,
    required this.destinationName,
    required this.tagline,
    required this.dates,
    required this.status,
    required this.budget,
    required this.spent,
    required this.days,
    required this.topCategory,
    this.startDate,
    this.endDate,
  });
}
