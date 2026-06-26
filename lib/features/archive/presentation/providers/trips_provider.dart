import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/trip.dart';

final tripsProvider = StreamProvider<List<Trip>>((ref) async* {
  // Simulating a network delay
  await Future.delayed(const Duration(milliseconds: 800));

  yield const [
    Trip(
      id: 'trip_1',
      destinationName: 'Manali, Himachal Pradesh',
      tagline: 'Snowy cafés, winding roads, and a slow solo pace',
      dates: 'June 25 - June 30, 2026',
      status: TripStatus.active,
      budget: 18000,
      spent: 4200,
      days: 5,
      topCategory: 'Food',
      checkInsCompleted: 3,
    ),
    Trip(
      id: 'trip_2',
      destinationName: 'Hampi, Karnataka',
      tagline: 'Temple ruins, sunset climbs, and a history-heavy reset',
      dates: 'Dec 12 - Dec 15, 2026',
      status: TripStatus.planning,
      budget: 12000,
      spent: 0,
      days: 3,
      topCategory: 'Stay',
      checkInsCompleted: 0,
    ),
    Trip(
      id: 'trip_3',
      destinationName: 'Munnar, Kerala',
      tagline: 'Tea gardens, misty mornings, and quiet hill drives',
      dates: 'June 18 - June 22, 2026',
      status: TripStatus.completed,
      budget: 15000,
      spent: 12850,
      days: 5,
      topCategory: 'Stay',
      checkInsCompleted: 8,
    ),
    Trip(
      id: 'trip_4',
      destinationName: 'South Goa, Goa',
      tagline: 'Slow beaches, local food stalls, and sunset wandering',
      dates: 'Jan 05 - Jan 10, 2026',
      status: TripStatus.completed,
      budget: 20000,
      spent: 22400,
      days: 6,
      topCategory: 'Activity',
      checkInsCompleted: 11,
    ),
    Trip(
      id: 'trip_5',
      destinationName: 'Udaipur, Rajasthan',
      tagline: 'Lake views, palace walks, and a camera-first plan',
      dates: 'Aug 02 - Aug 06, 2026',
      status: TripStatus.planning,
      budget: 16000,
      spent: 0,
      days: 4,
      topCategory: 'Food',
      checkInsCompleted: 0,
    ),
  ];
});
