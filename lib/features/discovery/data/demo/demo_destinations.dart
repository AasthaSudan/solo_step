import '../../domain/entities/destination.dart';

/// Curated destinations for the internship presentation profile.
/// Fixed image URLs keep the demo independent of random image search.
const demoDestinations = <Destination>[
  Destination(
    name: 'Rishikesh',
    tagline: 'Riverfront calm, yoga mornings, and a little adventure.',
    dailyBudgetEstimate: 3000,
    highlights: [
      'Ganga riverfront',
      'Yoga and ashrams',
      'Rafting and waterfalls',
    ],
    safetyNote:
        'Stay on well-lit riverfront routes after dark and use registered cabs for late travel.',
    imageUrl:
        'https://images.unsplash.com/photo-1720863458635-849623bae4d3?auto=format&fit=crop&w=1200&q=85',
  ),
  Destination(
    name: 'Gokarna',
    tagline: 'Quiet beaches, coastal walks, and a slower spiritual escape.',
    dailyBudgetEstimate: 2800,
    highlights: ['Om Beach', 'Coastal trails', 'Temple town culture'],
    safetyNote:
        'Avoid isolated beach walks after sunset and keep valuables secure in crowded areas.',
    imageUrl:
        'https://images.unsplash.com/photo-1733158714880-95917a61b973?auto=format&fit=crop&w=1200&q=85',
  ),
  Destination(
    name: 'Munnar',
    tagline: 'Misty tea hills, scenic viewpoints, and a refreshing slow trip.',
    dailyBudgetEstimate: 3500,
    highlights: [
      'Tea plantations',
      'Misty viewpoints',
      'Eravikulam National Park',
    ],
    safetyNote:
        'Use a local driver for hill routes and avoid plantation roads after dusk.',
    imageUrl:
        'https://images.unsplash.com/photo-1742286087579-fcaa5ed24c35?auto=format&fit=crop&w=1200&q=85',
  ),
  Destination(
    name: 'Jaipur',
    tagline:
        'Royal architecture, colourful bazaars, and unforgettable local food.',
    dailyBudgetEstimate: 3200,
    highlights: ['Amber Fort', 'Hawa Mahal', 'Johari Bazaar food walk'],
    safetyNote:
        'Use prepaid or app-based rides and agree on prices before local transport.',
    imageUrl:
        'https://images.unsplash.com/photo-1477587458883-47145ed94245?auto=format&fit=crop&w=1200&q=85',
  ),
  Destination(
    name: 'Varanasi',
    tagline: 'A memorable cultural journey along the sacred Ganges.',
    dailyBudgetEstimate: 2800,
    highlights: ['Ganga Aarti', 'Sarnath', 'Old-city food walks'],
    safetyNote:
        'Stay with your group near the ghats at night and use a registered guide for narrow lanes.',
    imageUrl:
        'https://images.unsplash.com/photo-1762513907666-29901bf5899a?auto=format&fit=crop&w=1200&q=85',
  ),
];

bool isInternshipDemoProfile(Map<String, dynamic> profile) {
  final interests = (profile['interests'] as List<dynamic>? ?? [])
      .map((item) => item.toString())
      .toSet();
  return profile['mood'] == 'adventure' &&
      profile['budgetTier'] == 'comfort' &&
      profile['tripDuration'] == 'short_trip' &&
      profile['experienceLevel'] == 'first_timer' &&
      interests.contains('nature') &&
      interests.contains('offbeat') &&
      interests.contains('wellness');
}
