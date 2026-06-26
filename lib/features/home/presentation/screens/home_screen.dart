import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/trip_summary_card.dart';

/// The main dashboard screen (Layer 1 UI).
/// Allows switching between empty-state and active-trip layouts using an App Bar toggle.
class HomeScreen extends StatefulWidget {
  /// When [startWithActiveTrip] is true the dashboard opens in the active-trip
  /// layout immediately (used after saving an itinerary).
  final bool startWithActiveTrip;

  const HomeScreen({super.key, this.startWithActiveTrip = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Initialised from widget param so ItineraryViewScreen can redirect with
  // active-trip state already set.
  late bool _hasActiveTrip;

  @override
  void initState() {
    super.initState();
    _hasActiveTrip = widget.startWithActiveTrip;
  }

  void _handlePlanNewTrip() {
    context.go('/home/discover');
  }

  void _handleTripCardPressed() {
    context.go('/home/active/Manali,%20Himachal%20Pradesh');
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
            children: [
              // Custom Navigation/App Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // User Info Greeting
                    Row(
                      children: [
                        // Avatar placeholder
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF9D4EDD), Color(0xFFC77DFF)],
                            ),
                            border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.15), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromRGBO(199, 125, 255, 0.25),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, Explorer!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16 * textScale,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Ready for your next adventure?',
                              style: TextStyle(
                                color: const Color.fromRGBO(255, 255, 255, 0.55),
                                fontSize: 12 * textScale,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    // Demo State Toggle Button (for testing empty vs active card)
                    Container(
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(255, 255, 255, 0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.1), width: 1),
                      ),
                      child: IconButton(
                        icon: Icon(
                          _hasActiveTrip ? Icons.toggle_on : Icons.toggle_off,
                          color: _hasActiveTrip ? const Color(0xFFE0AAFF) : Colors.white60,
                          size: 26,
                        ),
                        tooltip: 'Toggle Trip Presence State',
                        onPressed: () {
                          setState(() {
                            _hasActiveTrip = !_hasActiveTrip;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_hasActiveTrip 
                                  ? 'Switched to Active Trip Dashboard State'
                                  : 'Switched to Empty Dashboard State'),
                              duration: const Duration(milliseconds: 1200),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(color: Color.fromRGBO(255, 255, 255, 0.08), height: 1),

              // Main Dashboard Area
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 540.0 : double.infinity,
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: _hasActiveTrip
                            ? Column(
                                key: const ValueKey('active_trip_state'),
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Active Trip',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14 * textScale,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  // Active Trip Summary Card
                                  TripSummaryCard(
                                    destination: 'Manali, Himachal Pradesh',
                                    tagline: 'A snowy sanctuary for the solo explorer',
                                    dates: 'June 25 - June 30, 2026',
                                    status: 'Active',
                                    currentDay: 2,
                                    totalDays: 5,
                                    onTap: _handleTripCardPressed,
                                  ),
                                  const SizedBox(height: 28),
                                  
                                  // Quick Actions Section
                                  Text(
                                    'Quick Actions',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14 * textScale,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  // Active Trip Quick Controls (Layer 1 Visual Mock)
                                  GridView.count(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 1.4,
                                    children: [
                                      _buildQuickActionItem(
                                        icon: Icons.map_outlined,
                                        label: 'View Itinerary',
                                        color: const Color(0xFFC77DFF),
                                        onTap: _handleTripCardPressed,
                                      ),
                                      _buildQuickActionItem(
                                        icon: Icons.account_balance_wallet_outlined,
                                        label: 'Track Expenses',
                                        color: const Color(0xFFFBBC05),
                                        onTap: () {
                                          context.go('/home/active/Manali,%20Himachal%20Pradesh');
                                        },
                                      ),
                                      _buildQuickActionItem(
                                        icon: Icons.shield_outlined,
                                        label: 'Return Signal',
                                        color: const Color(0xFFEA4335),
                                        onTap: () {
                                          context.go('/home/checkin');
                                        },
                                      ),
                                      _buildQuickActionItem(
                                        icon: Icons.chat_bubble_outline,
                                        label: 'AI Travel Agent',
                                        color: const Color(0xFF4285F4),
                                        onTap: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('AI Support Chat (Mock)')),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : Container(
                                key: const ValueKey('empty_state'),
                                padding: const EdgeInsets.symmetric(vertical: 40.0),
                                child: EmptyStateWidget(
                                  onPlanTripPressed: _handlePlanNewTrip,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(255, 255, 255, 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color.fromRGBO(255, 255, 255, 0.08),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(31),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: const Color.fromRGBO(255, 255, 255, 0.9),
                  fontSize: 14 * textScale,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
