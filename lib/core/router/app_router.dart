import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/active_trip/presentation/screens/active_trip_screen.dart';
import '../../features/archive/presentation/screens/trips_screen.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/debrief/presentation/screens/debrief_screen.dart';
import '../../features/discovery/domain/entities/destination.dart';
import '../../features/discovery/data/mock_destinations.dart';
import '../../features/discovery/presentation/screens/destination_detail_screen.dart';
import '../../features/discovery/presentation/screens/destination_discovery_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/itinerary/presentation/screens/itinerary_view_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_flow_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/return_signal/presentation/screens/manual_checkin_screen.dart';
import '../../features/return_signal/presentation/screens/trusted_contacts_screen.dart';
import '../../features/shell/presentation/screens/home_shell.dart';
import '../../features/debrief/domain/entities/debrief_card.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/sign-in',
  routes: [
    GoRoute(
      path: '/sign-in',
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingFlowScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return HomeShell(navigationShell: navigationShell);
      },
      branches: [
        // Tab 0: Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) {
                final extra = state.extra as Map<String, dynamic>?;
                final startWithActiveTrip = extra?['startWithActiveTrip'] as bool? ?? false;
                return HomeScreen(startWithActiveTrip: startWithActiveTrip);
              },
              routes: [
                GoRoute(
                  path: 'discover',
                  builder: (context, state) => const DestinationDiscoveryScreen(),
                ),
                GoRoute(
                  path: 'destination/:id',
                  builder: (context, state) {
                    final destinationName = state.pathParameters['id'] ?? '';
                    Destination? destination;
                    if (state.extra is Destination) {
                      destination = state.extra as Destination;
                    } else {
                      destination = mockDestinations.where((d) => d.name == destinationName).firstOrNull;
                    }

                    if (destination == null) {
                      return const Center(child: Text('Error: No destination provided'));
                    }
                    return DestinationDetailScreen(destination: destination);
                  },
                ),
                GoRoute(
                  path: 'active/:name',
                  builder: (context, state) {
                    final destinationName = state.pathParameters['name'] ?? 'Unknown';
                    return ActiveTripScreen(destinationName: destinationName);
                  },
                ),
                GoRoute(
                  path: 'checkin',
                  builder: (context, state) => const ManualCheckinScreen(),
                ),
              ],
            ),
          ],
        ),
        // Tab 1: Trips
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/trips',
              builder: (context, state) => const TripsScreen(),
              routes: [
                GoRoute(
                  path: 'active/:name',
                  builder: (context, state) {
                    final destinationName = state.pathParameters['name'] ?? 'Unknown';
                    return ActiveTripScreen(destinationName: destinationName);
                  },
                ),
                GoRoute(
                  path: 'itinerary/:name',
                  builder: (context, state) {
                    final destinationName = state.pathParameters['name'] ?? 'Unknown';
                    return ItineraryViewScreen(destinationName: destinationName);
                  },
                ),
                GoRoute(
                  path: 'debrief',
                  builder: (context, state) {
                    DebriefCard? card;
                    if (state.extra is DebriefCard) {
                      card = state.extra as DebriefCard;
                    }
                    card ??= DebriefCard(
                        personality: 'Budget Adventurer',
                        traits: const ['Street Food Scout', 'Route Planner', 'Early Riser'],
                        caption: 'Wrapped a trip with smart spending, strong check-ins, and plenty of local discoveries.',
                        savedVsEstimateInr: 2500,
                        totalSpentInr: 12500,
                        daysCount: 4,
                        topCategory: 'Food',
                        checkInsCompleted: 8,
                      );
                    return DebriefScreen(card: card);
                  },
                ),
              ],
            ),
          ],
        ),
        // Tab 2: Profile
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
              routes: [
                GoRoute(
                  path: 'trusted-contacts',
                  builder: (context, state) => const TrustedContactsScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
