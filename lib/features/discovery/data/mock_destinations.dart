import '../domain/entities/destination.dart';

/// A static database of mock travel destinations for Layer 1.
const List<Destination> mockDestinations = [
  Destination(
    name: 'Munnar, Kerala',
    tagline: 'A green sanctuary in the Western Ghats',
    dailyBudgetEstimate: 1400.0,
    highlights: [
      'Stunning tea estate trails',
      'Anamudi Peak hiking',
      'Fresh local spices & homemade chocolates',
      'Quiet waterfalls & mist-covered hills'
    ],
    safetyNote: 'Mountain roads can get very foggy in the late afternoon. Avoid trekking solo after sunset.',
  ),
  Destination(
    name: 'Hampi, Karnataka',
    tagline: 'Step back in time among ancient ruins',
    dailyBudgetEstimate: 1100.0,
    highlights: [
      'Bicycle tour of Virupaksha Temple complexes',
      'Bouldering & sunset at Hemakuta Hill',
      'Coracle boat ride across the Tungabhadra River',
      'Charming hippie island cafes'
    ],
    safetyNote: 'Expect high temperatures. Keep hydrated and watch your steps while climbing ruins.',
  ),
  Destination(
    name: 'Bir Billing, Himachal Pradesh',
    tagline: 'Soar high above the Himalayan valleys',
    dailyBudgetEstimate: 1750.0,
    highlights: [
      'World-class paragliding tandem flights',
      'Chokling Monastery visits & meditation',
      'Cozy mountain cafes & Tibetan street food',
      'Sherab Ling monastery forest hikes'
    ],
    safetyNote: 'Ensure you fly only with certified pilots. Landing zones can get crowded in peak season.',
  ),
  Destination(
    name: 'Rishikesh, Uttarakhand',
    tagline: 'The yoga capital of the world',
    dailyBudgetEstimate: 950.0,
    highlights: [
      'Ganges white water rafting',
      'Meditation courses at ashrams',
      'Ganga Aarti sunset ceremonies',
      'Neer Garh waterfall hikes'
    ],
    safetyNote: 'Strong river currents. Swimmers should stick to designated, monitored bathing ghats.',
  ),
  Destination(
    name: 'South Goa, Goa',
    tagline: 'Serene white sand beaches & quiet coves',
    dailyBudgetEstimate: 2100.0,
    highlights: [
      'Sunset kayak at Palolem beach',
      'Portuguese-era heritage walks in Margao',
      'Fresh seafood at beachfront shacks',
      'Cabo de Rama fort cliffside walks'
    ],
    safetyNote: 'Strong undercurrents at some beaches. Pay attention to red flags raised by lifeguards.',
  ),
];
