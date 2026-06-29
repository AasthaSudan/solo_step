import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/itinerary_activity.dart';

/// Renders a single activity within a day's schedule.
/// Displays a categorized and priced chip with custom theme colors.
class ActivityLineItem extends StatelessWidget {
  final ItineraryActivity activity;

  const ActivityLineItem({
    super.key,
    required this.activity,
  });

  // Determines color codes for different activity categories
  Map<String, dynamic> _getCategoryStyle(String category) {
    switch (category.toLowerCase()) {
      case 'sightseeing':
        return {
          'color': const Color(0xFF4285F4), // Blue
          'bg': const Color.fromRGBO(66, 133, 244, 0.12),
          'icon': Icons.museum_outlined,
        };
      case 'food':
        return {
          'color': const Color(0xFFFBBC05), // Amber
          'bg': const Color.fromRGBO(251, 188, 5, 0.12),
          'icon': Icons.restaurant_outlined,
        };
      case 'transport':
        return {
          'color': const Color(0xFF00F5D4), // Teal
          'bg': const Color.fromRGBO(0, 245, 212, 0.12),
          'icon': Icons.directions_bus_filled_outlined,
        };
      case 'stay':
        return {
          'color': const Color(0xFF9D4EDD), // Purple
          'bg': const Color.fromRGBO(157, 78, 221, 0.12),
          'icon': Icons.hotel_outlined,
        };
      case 'activity':
      default:
        return {
          'color': const Color(0xFFFF007F), // Rose/Pink
          'bg': const Color.fromRGBO(255, 0, 127, 0.12),
          'icon': Icons.explore_outlined,
        };
    }
  }

  Future<void> _launchMaps(String? query) async {
    if (query == null || query.isEmpty) return;
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeQueryComponent(query)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _launchUrlStr(String? urlStr) async {
    if (urlStr == null || urlStr.isEmpty) return;
    final url = Uri.tryParse(urlStr);
    if (url != null && await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final style = _getCategoryStyle(activity.category);
    final Color accentColor = style['color'];
    final Color bgColor = style['bg'];
    final IconData iconData = style['icon'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Indicator Column
          SizedBox(
            width: 76,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.time.toUpperCase(),
                  style: TextStyle(
                    color: const Color(0xFFC77DFF),
                    fontSize: 11 * textScale,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  iconData,
                  color: Colors.white60,
                  size: 18,
                ),
              ],
            ),
          ),
          
          // Timeline indicator line & circle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Column(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE0AAFF),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 1.5,
                  height: 120, // Increased to accommodate new UI
                  color: const Color.fromRGBO(255, 255, 255, 0.08),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Activity Description Block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  activity.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15 * textScale,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                if (activity.imageUrl != null && activity.imageUrl!.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      activity.imageUrl!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                
                if (activity.transitInstructions != null && activity.transitInstructions!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(0, 245, 212, 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color.fromRGBO(0, 245, 212, 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.directions_transit, size: 14, color: Color(0xFF00F5D4)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            activity.transitInstructions!,
                            style: TextStyle(
                              color: const Color(0xFF00F5D4),
                              fontSize: 12 * textScale,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 6),
                
                // Notes
                Text(
                  activity.notes,
                  style: TextStyle(
                    color: const Color.fromRGBO(255, 255, 255, 0.65),
                    fontSize: 13 * textScale,
                    fontWeight: FontWeight.w400,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Category + Price Chip + Maps Button
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: accentColor.withAlpha(51), width: 1),
                      ),
                      child: Text(
                        '${activity.category.toUpperCase()}  •  ₹${activity.estimatedCost.toInt()}',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 11 * textScale,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (activity.googleMapsQuery != null && activity.googleMapsQuery!.isNotEmpty)
                      InkWell(
                        onTap: () => _launchMaps(activity.googleMapsQuery),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(66, 133, 244, 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF4285F4).withAlpha(100), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.map_outlined, size: 14, color: Color(0xFF4285F4)),
                              const SizedBox(width: 4),
                              Text(
                                'Maps',
                                style: TextStyle(
                                  color: const Color(0xFF4285F4),
                                  fontSize: 11 * textScale,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (activity.bookingLink != null && activity.bookingLink!.isNotEmpty)
                      InkWell(
                        onTap: () => _launchUrlStr(activity.bookingLink),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(157, 78, 221, 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF9D4EDD).withAlpha(100), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.open_in_new_outlined, size: 14, color: Color(0xFF9D4EDD)),
                              const SizedBox(width: 4),
                              Text(
                                'Book',
                                style: TextStyle(
                                  color: const Color(0xFF9D4EDD),
                                  fontSize: 11 * textScale,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

