import '../../domain/entities/booking_option.dart';
import '../../domain/entities/itinerary.dart';
import '../../domain/entities/itinerary_activity.dart';
import '../../domain/entities/itinerary_day.dart';

/// Deterministic itinerary used when Gemini is unavailable during a demo.
class DemoItineraryFactory {
  static Itinerary create(String destinationName) {
    final isVaranasi = destinationName.toLowerCase().contains('varanasi');
    final place = isVaranasi ? 'Varanasi' : destinationName;
    final days = isVaranasi
        ? [
            _day(
              1,
              place,
              'Dashashwamedh Ghat & Ganga Aarti',
              450,
              'Walk the riverfront early, then attend the evening Ganga Aarti.',
            ),
            _day(
              2,
              place,
              'Sarnath Buddhist Circuit',
              700,
              'Visit Sarnath in the morning and return to the old city for a food walk.',
            ),
            _day(
              3,
              place,
              'Assi Ghat Sunrise Boat Ride',
              900,
              'Take a sunrise boat ride and leave time for local silk shopping.',
            ),
          ]
        : [
            _day(
              1,
              place,
              'Local highlights walk',
              500,
              'Start with the best-known landmark and get oriented with a neighbourhood walk.',
            ),
            _day(
              2,
              place,
              'Culture and food trail',
              800,
              'Spend the day on a cultural route with a trusted local restaurant for lunch.',
            ),
            _day(
              3,
              place,
              'Slow morning and hidden gem',
              600,
              'Keep the final day flexible for a quieter local experience and shopping.',
            ),
          ];

    return Itinerary(
      days: days,
      accommodations: [
        BookingOption(
          id: 'demo-stay',
          type: 'accommodation',
          name: 'Comfortable central stay in $place',
          description:
              'A well-connected mid-range stay close to the main sights.',
          estimatedCostInr: 1800,
          searchLink:
              'https://www.google.com/maps/search/?api=1&query=${Uri.encodeQueryComponent('mid-range stay $place')}',
        ),
      ],
      foodOptions: [
        BookingOption(
          id: 'demo-food',
          type: 'food',
          name: 'Recommended local food walk',
          description: 'Popular local dishes with busy, well-reviewed stops.',
          estimatedCostInr: 700,
          searchLink:
              'https://www.google.com/maps/search/?api=1&query=${Uri.encodeQueryComponent('local food $place')}',
        ),
      ],
    );
  }

  static ItineraryDay _day(
    int day,
    String location,
    String title,
    double cost,
    String notes,
  ) {
    return ItineraryDay(
      dayNumber: day,
      activities: [
        ItineraryActivity(
          time: 'Morning',
          title: title,
          category: 'sightseeing',
          estimatedCost: cost,
          notes: notes,
          googleMapsQuery: '$title $location',
          transitInstructions:
              'Use a registered auto or taxi and confirm the fare before starting.',
        ),
        ItineraryActivity(
          time: 'Evening',
          title: 'Easy local dinner',
          category: 'food',
          estimatedCost: 350,
          notes: 'Choose a busy, well-reviewed restaurant close to your stay.',
          googleMapsQuery: 'local dinner $location',
          transitInstructions:
              'Walk where possible; otherwise use a registered cab.',
        ),
      ],
      stayName: 'Comfortable central stay in $location',
      stayCost: 1800,
      stayMapsQuery: 'mid-range stay $location',
      foodSuggestions: const [
        'Local breakfast',
        'Busy neighbourhood restaurant',
      ],
    );
  }
}
