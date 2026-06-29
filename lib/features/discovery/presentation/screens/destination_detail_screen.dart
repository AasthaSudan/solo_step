import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/destination.dart';

/// Screen showing detailed information for a single recommended destination.
class DestinationDetailScreen extends StatelessWidget {
  final Destination destination;

  const DestinationDetailScreen({
    super.key,
    required this.destination,
  });

  void _handleBuildItinerary(BuildContext context) {
    context.go('/trips/itinerary/new', extra: {'destinationName': destination.name});
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isTablet = screenSize.width > 600;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);

    // Calculate total cost estimate based on a mock 5-day trip duration
    final double mockDurationDays = 5;
    final double totalCostEstimate = destination.dailyBudgetEstimate * mockDurationDays;

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
              // Custom Header Row (Back Button & Title)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      onPressed: () => context.pop(),
                      tooltip: 'Back to Suggestions',
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Destination Details',
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

              // Main Details Content
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 540.0 : double.infinity,
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Destination Name & Hero Card
                          Text(
                            destination.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: (isTablet ? 32.0 : 28.0) * textScale,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            destination.tagline,
                            style: TextStyle(
                              color: const Color.fromRGBO(255, 255, 255, 0.7),
                              fontSize: 16 * textScale,
                              fontWeight: FontWeight.w400,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // "Why this fits you" glassmorphic match box
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20.0),
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(199, 125, 255, 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color.fromRGBO(199, 125, 255, 0.25),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color.fromRGBO(157, 78, 221, 0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.auto_awesome_outlined,
                                      color: Color(0xFFC77DFF),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Why this fits you',
                                      style: TextStyle(
                                        color: const Color(0xFFE0AAFF),
                                        fontSize: 14 * textScale,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'This destination matches your selected Adventure Vibe. Based on your interest in exploring nature, street dining, and ancient heritage sites, Gemini curated this location to provide scenic trekking, local historical walks, and authentic regional eats.',
                                  style: TextStyle(
                                    color: const Color.fromRGBO(255, 255, 255, 0.8),
                                    fontSize: 14 * textScale,
                                    fontWeight: FontWeight.w400,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Expense & Visit metadata grid card
                          Container(
                            padding: const EdgeInsets.all(20.0),
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(255, 255, 255, 0.04),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color.fromRGBO(255, 255, 255, 0.08),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildDetailRow(
                                  icon: Icons.calendar_today_outlined,
                                  label: 'Best Time to Visit',
                                  value: 'October – March',
                                  textScale: textScale,
                                ),
                                const SizedBox(height: 16),
                                const Divider(color: Color.fromRGBO(255, 255, 255, 0.08), height: 1),
                                const SizedBox(height: 16),
                                _buildDetailRow(
                                  icon: Icons.currency_rupee,
                                  label: 'Daily Budget Estimate',
                                  value: '₹${destination.dailyBudgetEstimate.toInt()} / day',
                                  textScale: textScale,
                                ),
                                const SizedBox(height: 16),
                                const Divider(color: Color.fromRGBO(255, 255, 255, 0.08), height: 1),
                                const SizedBox(height: 16),
                                _buildDetailRow(
                                  icon: Icons.wallet_travel_outlined,
                                  label: 'Total Estimate (5 Days)',
                                  value: '₹${totalCostEstimate.toInt()}',
                                  valueColor: const Color(0xFFC77DFF),
                                  textScale: textScale,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Highlights list
                          Text(
                            'EXPLORATION HIGHLIGHTS',
                            style: TextStyle(
                              color: const Color(0xFFC77DFF),
                              fontSize: 12 * textScale,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...destination.highlights.map((highlight) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 4.0),
                                    child: Icon(
                                      Icons.check_circle_outline,
                                      color: Color(0xFFE0AAFF),
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      highlight,
                                      style: TextStyle(
                                        color: const Color.fromRGBO(255, 255, 255, 0.85),
                                        fontSize: 15 * textScale,
                                        fontWeight: FontWeight.w500,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 12),

                          // Safety Warning Banner
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(234, 67, 53, 0.06),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color.fromRGBO(234, 67, 53, 0.15),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.shield_outlined,
                                      color: Color(0xFFEA4335),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'AI Safety Guidance',
                                      style: TextStyle(
                                        color: const Color(0xFFEA4335),
                                        fontSize: 13 * textScale,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  destination.safetyNote,
                                  style: TextStyle(
                                    color: const Color.fromRGBO(255, 255, 255, 0.75),
                                    fontSize: 13 * textScale,
                                    fontWeight: FontWeight.w400,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Primary action button (Build Itinerary)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF9D4EDD),
                                foregroundColor: Colors.white,
                                shadowColor: const Color.fromRGBO(157, 78, 221, 0.5),
                                elevation: 6,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () => _handleBuildItinerary(context),
                              child: Text(
                                'Build my itinerary',
                                style: TextStyle(
                                  fontSize: 16 * textScale,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Secondary action button (Back to suggestions list)
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: const BorderSide(color: Color.fromRGBO(255, 255, 255, 0.12), width: 1.5),
                                ),
                              ),
                              onPressed: () => context.pop(),
                              child: Text(
                                'Back to Suggestions',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15 * textScale,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    required double textScale,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFFE0AAFF),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: const Color.fromRGBO(255, 255, 255, 0.55),
                fontSize: 14 * textScale,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 14 * textScale,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
