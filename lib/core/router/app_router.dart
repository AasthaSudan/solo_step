import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/active_trip/presentation/screens/active_trip_screen.dart';
import '../../features/archive/presentation/screens/trips_screen.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/debrief/presentation/screens/debrief_screen.dart';
import '../../features/discovery/domain/entities/destination.dart';
import '../../features/discovery/presentation/screens/destination_detail_screen.dart';
import '../../features/discovery/presentation/screens/destination_discovery_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/itinerary/presentation/screens/itinerary_view_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_flow_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/chat/presentation/screens/ai_agent_chat_screen.dart';

import '../../features/shell/presentation/screens/home_shell.dart';


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
                bool startWithActiveTrip = false;
                if (state.extra is Map<String, dynamic>) {
                  startWithActiveTrip = (state.extra as Map<String, dynamic>)['startWithActiveTrip'] as bool? ?? false;
                }
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

                    Destination? destination;
                    if (state.extra is Destination) {
                      destination = state.extra as Destination;
                    }

                    if (destination == null) {
                      return const Center(child: Text('Error: No destination provided'));
                    }
                    return DestinationDetailScreen(destination: destination);
                  },
                ),
                GoRoute(
                  path: 'active/:tripId',
                  builder: (context, state) {
                    final tripId = state.pathParameters['tripId'] ?? 'Unknown';
                    // We can pass tripId now instead of destinationName
                    final extra = state.extra as Map<String, dynamic>?;
                    final destinationName = extra?['destinationName'] as String? ?? 'Unknown Destination';
                    return ActiveTripScreen(tripId: tripId, destinationName: destinationName);
                  },
                ),
                GoRoute(
                  path: 'chat',
                  builder: (context, state) {
                    final extra = state.extra as Map<String, dynamic>?;
                    final destinationName = extra?['destinationName'] as String? ?? 'Your Destination';
                    return AiAgentChatScreen(destinationName: destinationName);
                  },
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
                  path: 'active/:tripId',
                  builder: (context, state) {
                    final tripId = state.pathParameters['tripId'] ?? 'Unknown';
                    final extra = state.extra as Map<String, dynamic>?;
                    final destinationName = extra?['destinationName'] as String? ?? 'Unknown Destination';
                    return ActiveTripScreen(tripId: tripId, destinationName: destinationName);
                  },
                ),
                GoRoute(
                  path: 'itinerary/:tripId',
                  builder: (context, state) {
                    final tripId = state.pathParameters['tripId'] ?? 'Unknown';
                    final extra = state.extra as Map<String, dynamic>?;
                    final destinationName = extra?['destinationName'] as String? ?? 'Unknown Destination';
                    return ItineraryViewScreen(tripId: tripId, destinationName: destinationName);
                  },
                ),
                GoRoute(
                  path: 'debrief/:tripId',
                  builder: (context, state) {
                    final tripId = state.pathParameters['tripId'] ?? 'Unknown';
                    return DebriefScreen(tripId: tripId);
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

            ),
          ],
        ),
      ],
    ),
  ],
);
