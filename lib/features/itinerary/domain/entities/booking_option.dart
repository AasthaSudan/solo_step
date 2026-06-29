class BookingOption {
  final String id;
  final String type; // e.g. 'accommodation', 'food', 'transport'
  final String name;
  final String description;
  final int estimatedCostInr;
  final String searchLink; // The link to Google Maps, Zomato, or MakeMyTrip

  const BookingOption({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.estimatedCostInr,
    required this.searchLink,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'description': description,
      'estimatedCostInr': estimatedCostInr,
      'searchLink': searchLink,
    };
  }

  factory BookingOption.fromMap(Map<String, dynamic> map) {
    return BookingOption(
      id: map['id'] as String? ?? '',
      type: map['type'] as String? ?? 'accommodation',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      estimatedCostInr: (map['estimatedCostInr'] as num?)?.toInt() ?? 0,
      searchLink: map['searchLink'] as String? ?? '',
    );
  }
}
