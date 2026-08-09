import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/destination.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/utils/destination_image.dart';
/// Screen showing detailed information for a single recommended destination.
class DestinationDetailScreen extends StatelessWidget {
  final Destination destination;

  const DestinationDetailScreen({super.key, required this.destination});

  void _handleBuildItinerary(BuildContext context) {
    final encodedDestinationName = Uri.encodeQueryComponent(destination.name);
    context.go('/trips/itinerary/new?destinationName=$encodedDestinationName');
  }

  String _bestTimeToVisit() {
    final name = destination.name.toLowerCase();
    if (name.contains('goa') || name.contains('gokarna')) {
      return 'October – March';
    }
    if (name.contains('munnar') || name.contains('kerala')) {
      return 'September – March';
    }
    if (name.contains('rishikesh') ||
        name.contains('tirthan') ||
        name.contains('manali')) {
      return 'March – June';
    }
    if (name.contains('varanasi')) return 'November – February';
    return 'October – March';
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isTablet = screenSize.width > 600;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);

    // Calculate total cost estimate based on a mock 5-day trip duration
    const double mockDurationDays = 5;
    final double totalCostEstimate =
        destination.dailyBudgetEstimate * mockDurationDays;
    final highlights = destination.highlights.isEmpty
        ? destinationFallbackHighlights(destination.name)
        : destination.highlights;

    final String destinationUrl = destination.imageUrl;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Hero Image Header
          SliverAppBar(
            expandedHeight: 350.0,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFFF7F5F0),
            leading: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.8),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Color(0xFF1A1A1A),
                    size: 20,
                  ),
                  onPressed: () => context.pop(),
                  tooltip: 'Back to Suggestions',
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: destinationUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: Colors.grey.shade300),
                    errorWidget: (context, url, error) =>
                        Container(color: Colors.grey.shade300),
                  ).animate().fade(duration: 800.ms),
                  // Gradient for text readability if we put text here
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFFF7F5F0).withValues(alpha: 0.2),
                          const Color(0xFFF7F5F0),
                        ],
                        stops: const [0.6, 0.8, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 540.0 : double.infinity,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 24.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Destination Name & Tagline
                      Text(
                        destination.name,
                        style: TextStyle(
                          color: const Color(0xFF1A1A1A),
                          fontSize: (isTablet ? 38.0 : 32.0) * textScale,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          height: 1.1,
                        ),
                      ).animate().fade().slideY(begin: 0.1),
                      const SizedBox(height: 8),
                      Text(
                        destination.tagline,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 18 * textScale,
                          fontWeight: FontWeight.w400,
                          height: 1.35,
                        ),
                      ).animate().fade(delay: 100.ms).slideY(begin: 0.1),
                      const SizedBox(height: 28),

                      // "Why this fits you" glassmorphic match box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
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
                                  color: Color(0xFF2C3E50),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Why this fits you',
                                  style: TextStyle(
                                    color: const Color(0xFF2C3E50),
                                    fontSize: 14 * textScale,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Gemini selected ${destination.name} for this trip because it offers ${destination.tagline.toLowerCase()} Explore ${highlights.take(2).join(' and ')} for a more local experience.',
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: 14 * textScale,
                                fontWeight: FontWeight.w400,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fade(delay: 200.ms).slideY(begin: 0.1),
                      const SizedBox(height: 28),

                      // Expense & Visit metadata grid card
                      Container(
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow(
                              icon: Icons.calendar_today_outlined,
                              label: 'Best Time to Visit',
                              value: _bestTimeToVisit(),
                              textScale: textScale,
                            ),
                            const SizedBox(height: 16),
                            Divider(color: Colors.grey.shade300, height: 1),
                            const SizedBox(height: 16),
                            _buildDetailRow(
                              icon: Icons.currency_rupee,
                              label: 'Daily Budget Estimate',
                              value:
                                  '₹${destination.dailyBudgetEstimate.toInt()} / day',
                              textScale: textScale,
                            ),
                            const SizedBox(height: 16),
                            Divider(color: Colors.grey.shade300, height: 1),
                            const SizedBox(height: 16),
                            _buildDetailRow(
                              icon: Icons.wallet_travel_outlined,
                              label: 'Total Estimate (5 Days)',
                              value: '₹${totalCostEstimate.toInt()}',
                              valueColor: const Color(0xFF2C3E50),
                              textScale: textScale,
                            ),
                          ],
                        ),
                      ).animate().fade(delay: 300.ms).slideY(begin: 0.1),
                      const SizedBox(height: 32),

                      // Highlights list
                      Text(
                        'EXPLORATION HIGHLIGHTS',
                        style: TextStyle(
                          color: const Color(0xFF2C3E50),
                          fontSize: 12 * textScale,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ).animate().fade(delay: 400.ms),
                      const SizedBox(height: 16),
                      ...highlights.asMap().entries.map((entry) {
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
                                      entry.value,
                                      style: TextStyle(
                                        color: const Color(0xFF1A1A1A),
                                        fontSize: 15 * textScale,
                                        fontWeight: FontWeight.w500,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .animate()
                            .fade(
                              delay: Duration(
                                milliseconds: 400 + (entry.key * 100).toInt(),
                              ),
                            )
                            .slideX(begin: 0.05);
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
                                color: Colors.grey.shade600,
                                fontSize: 13 * textScale,
                                fontWeight: FontWeight.w400,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fade(delay: 800.ms).slideY(begin: 0.1),
                      const SizedBox(height: 40),

                      // Primary action button (Build Itinerary)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2C3E50),
                            foregroundColor: Colors.white,
                            shadowColor: const Color.fromRGBO(
                              157,
                              78,
                              221,
                              0.5,
                            ),
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
                      ).animate().fade(delay: 900.ms).scale(),
                      const SizedBox(height: 16),

                      // Secondary action button (Back to suggestions list)
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1.5,
                              ),
                            ),
                          ),
                          onPressed: () => context.pop(),
                          child: Text(
                            'Back to Suggestions',
                            style: TextStyle(
                              color: const Color(0xFF1A1A1A),
                              fontSize: 15 * textScale,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ).animate().fade(delay: 1000.ms).scale(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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
            Icon(icon, color: const Color(0xFFE0AAFF), size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14 * textScale,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? const Color(0xFF1A1A1A),
            fontSize: 14 * textScale,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
