import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/destination_image.dart';


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
import '../../features/safety/presentation/screens/fake_call_screen.dart';
import '../../features/safety/presentation/screens/safety_screen.dart';


import '../../features/shell/presentation/screens/home_shell.dart';


final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

Map<String, dynamic>? _mapExtra(GoRouterState state) {
  final extra = state.extra;
  if (extra is Map<String, dynamic>) return extra;
  if (extra is Map) return Map<String, dynamic>.from(extra);
  return null;
}

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/sign-in',
  errorBuilder: (context, state) {
    return Scaffold(
      appBar: AppBar(title: const Text('Route Error')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Sorry, this route could not be opened.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                state.error?.toString() ?? 'Invalid route state.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/home/discover'),
                child: const Text('Back to Discover'),
              ),
            ],
          ),
        ),
      ),
    );
  },
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
                final extra = _mapExtra(state);
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
                    Destination? destination;
                    if (state.extra is Destination) {
                      destination = state.extra as Destination;
                    }

                    if (destination == null) {
                      final encodedId = state.pathParameters['id'] ?? '';
                      if (encodedId.isNotEmpty) {
                        final decodedName = Uri.decodeComponent(encodedId);
                        destination = Destination(
                          name: decodedName,
                          tagline: 'Discover more about $decodedName',
                          dailyBudgetEstimate: 0,
                          highlights: const [],
                          safetyNote: 'No detailed destination data is available.',
                          imageUrl: destinationImageUrl(decodedName),
                        );
                      }
                    }

                    if (destination == null) {
                      return Scaffold(
                        appBar: AppBar(title: const Text('Destination Error')),
                        body: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Error: No destination provided'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => context.go('/home/discover'),
                                child: const Text('Back to Discover'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return DestinationDetailScreen(destination: destination);
                  },
                ),

                GoRoute(
                  path: 'chat',
                  builder: (context, state) {
                    final extra = _mapExtra(state);
                    final destinationName = extra?['destinationName'] as String? ?? state.uri.queryParameters['destinationName'];
                    final tripId = extra?['tripId'] as String? ?? state.uri.queryParameters['tripId'];
                    if (destinationName == null || destinationName.isEmpty || tripId == null || tripId.isEmpty) {
                      return Scaffold(
                        appBar: AppBar(title: const Text('AI Agent Error')),
                        body: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Unable to open the travel agent without a valid trip.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () => context.go('/home/discover'),
                                  child: const Text('Back to Discover'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    return AiAgentChatScreen(
                      tripId: tripId,
                      destinationName: destinationName,
                    );
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
                  path: 'itinerary/:tripId',
                  builder: (context, state) {
                    final tripId = state.pathParameters['tripId'] ?? '';
                    if (tripId.isEmpty) {
                      return Scaffold(
                        appBar: AppBar(title: const Text('Itinerary Error')),
                        body: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Trip identifier is missing or invalid.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () => context.go('/trips'),
                                  child: const Text('Back to Trips'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    final extra = _mapExtra(state);
                    final destinationName = extra?['destinationName'] as String? ?? state.uri.queryParameters['destinationName'];
                    final initialTabIndex = extra?['initialTabIndex'] as int? ?? int.tryParse(state.uri.queryParameters['initialTabIndex'] ?? '') ?? 0;

                    if (tripId == 'new' && (destinationName == null || destinationName.isEmpty)) {
                      return Scaffold(
                        appBar: AppBar(title: const Text('Itinerary Error')),
                        body: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'A destination is required to create a new itinerary.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () => context.go('/home/discover'),
                                  child: const Text('Back to Discover'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return ItineraryViewScreen(
                      tripId: tripId,
                      destinationName: destinationName ?? (tripId == 'new' ? 'Your Destination' : 'Trip'),
                      initialTabIndex: initialTabIndex,
                    );
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
        // Tab 2: Safety
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/safety',
              builder: (context, state) => const SafetyScreen(),
              routes: [
                GoRoute(
                  path: 'fake-call',
                  builder: (context, state) => const FakeCallScreen(),
                ),
              ],
            ),
          ],
        ),
        // Tab 3: Profile
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
