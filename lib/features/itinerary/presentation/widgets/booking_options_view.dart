import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/booking_option.dart';
import '../../../../features/budget/domain/entities/expense.dart'; // To get SpendCategory

class BookingOptionsView extends StatelessWidget {
  final List<BookingOption> accommodations;
  final List<BookingOption> foodOptions;
  final List<BookingOption> transportOptions;
  final Function(SpendCategory) onOptionTapped;

  const BookingOptionsView({
    super.key,
    required this.accommodations,
    required this.foodOptions,
    required this.transportOptions,
    required this.onOptionTapped,
  });

  Future<void> _launchUrl(String urlString, SpendCategory category) async {
    final uri = Uri.parse(urlString);
    onOptionTapped(category);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (accommodations.isEmpty && foodOptions.isEmpty && transportOptions.isEmpty) {
      return const Center(
        child: Text(
          'No specific booking options available for this trip.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      physics: const BouncingScrollPhysics(),
      children: [
        if (accommodations.isNotEmpty) ...[
          _buildSectionTitle('Recommended Stays', Icons.bed_outlined, const Color(0xFFC77DFF)),
          const SizedBox(height: 16),
          ...accommodations.map((option) => _buildOptionCard(context, option, SpendCategory.stay)),
          const SizedBox(height: 32),
        ],
        if (foodOptions.isNotEmpty) ...[
          _buildSectionTitle('Local Eats & Dining', Icons.restaurant_outlined, const Color(0xFFFBBC05)),
          const SizedBox(height: 16),
          ...foodOptions.map((option) => _buildOptionCard(context, option, SpendCategory.food)),
          const SizedBox(height: 32),
        ],
        if (transportOptions.isNotEmpty) ...[
          _buildSectionTitle('Transport Routes', Icons.directions_transit_outlined, const Color(0xFF00E5FF)),
          const SizedBox(height: 16),
          ...transportOptions.map((option) => _buildOptionCard(context, option, SpendCategory.transport)),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard(BuildContext context, BookingOption option, SpendCategory category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _launchUrl(option.searchLink, category),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        option.description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(251, 188, 5, 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '₹${option.estimatedCostInr}',
                        style: const TextStyle(
                          color: Color(0xFFFBBC05),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      Icons.open_in_new,
                      color: Colors.white38,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
