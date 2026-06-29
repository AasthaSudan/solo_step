import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/destination.dart';
import '../providers/discovery_provider.dart';
import '../widgets/destination_card.dart';
import '../widgets/destination_card_skeleton.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Screen displaying 5 swipeable suggested destinations with filter options.
class DestinationDiscoveryScreen extends ConsumerStatefulWidget {
  const DestinationDiscoveryScreen({super.key});

  @override
  ConsumerState<DestinationDiscoveryScreen> createState() => _DestinationDiscoveryScreenState();
}

class _HomeScreenVibeChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _HomeScreenVibeChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.1), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFC77DFF)),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13 * textScale,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DestinationDiscoveryScreenState extends ConsumerState<DestinationDiscoveryScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // Viewport fraction 0.85 gives a beautiful peek effect of neighboring cards
    _pageController = PageController(viewportFraction: 0.85);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _triggerGeneration() {
    final authUser = ref.read(authStateProvider).value;
    if (authUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for authentication to load...')),
      );
      return;
    }
    ref.read(discoveryResultsProvider.notifier).triggerGeneration(authUser.uid);
  }

  void _handleSelectDestination(Destination destination) {
    context.go('/home/destination/${Uri.encodeComponent(destination.name)}', extra: destination);
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isTablet = screenSize.width > 600;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0C20), // Dark space blue
              Color(0xFF15102A), // Deep indigo
              Color(0xFF2E1A47), // Rich twilight purple
            ],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom Header Row (Back Button & Title)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      onPressed: () => context.pop(),
                      tooltip: 'Back to Dashboard',
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI Discovery',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20 * textScale,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(color: Color.fromRGBO(255, 255, 255, 0.08), height: 1),

              // Vibe Tweaks Confirmation Section
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vibe Check',
                      style: TextStyle(
                        color: const Color(0xFFC77DFF),
                        fontSize: 12 * textScale,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Wrap of dynamic profile tag highlights
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: const [
                        _HomeScreenVibeChip(label: 'Adventure Vibe', icon: Icons.terrain_outlined),
                        _HomeScreenVibeChip(label: 'Comfort Budget', icon: Icons.hotel_outlined),
                        _HomeScreenVibeChip(label: 'Short Trip (4-7 days)', icon: Icons.calendar_month_outlined),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Generate Destinations Trigger Button
                    if (ref.watch(discoveryResultsProvider).value?.isEmpty ?? true)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9D4EDD),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: ref.watch(discoveryResultsProvider).isLoading ? null : _triggerGeneration,
                          child: Text(
                            ref.watch(discoveryResultsProvider).isLoading ? 'Analyzing Profile...' : 'Generate Destinations',
                            style: TextStyle(
                              fontSize: 16 * textScale,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // PageView swiping deck section
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 540.0 : double.infinity,
                    ),
                    child: _buildMainContent(isTablet, textScale),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(bool isTablet, double textScale) {
    final asyncResults = ref.watch(discoveryResultsProvider);

    if (asyncResults.isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: const DestinationCardSkeleton(),
      );
    }

    final destinations = asyncResults.value ?? [];

    if (destinations.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.travel_explore_outlined,
              size: 64,
              color: const Color.fromRGBO(255, 255, 255, 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Explore Custom Suggestions',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16 * textScale,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Press the button above to run our Gemini recommendation model based on your profile inputs.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color.fromRGBO(255, 255, 255, 0.5),
                fontSize: 14 * textScale,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    // Swipe deck display
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (value) {
              setState(() {
                _currentPage = value;
              });
            },
            itemCount: destinations.length,
            itemBuilder: (context, index) {
              // Apply dynamic scale based on whether this page is current
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.1)).clamp(0.9, 1.0);
                  } else {
                    value = index == 0 ? 1.0 : 0.9;
                  }
                  
                  return Transform.scale(
                    scale: value,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
                      child: child,
                    ),
                  );
                },
                child: DestinationCard(
                  destination: destinations[index],
                  onTap: () => _handleSelectDestination(destinations[index]),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Dots indicator at the bottom of the card swiper
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(destinations.length, (index) {
            final isCurrent = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              height: 8,
              width: isCurrent ? 24 : 8,
              decoration: BoxDecoration(
                color: isCurrent ? const Color(0xFFC77DFF) : const Color.fromRGBO(255, 255, 255, 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}
