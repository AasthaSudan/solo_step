import 'package:flutter/material.dart';
import '../../widgets/selectable_card.dart';

/// Step 2: Budget Tier Selection
class BudgetStep extends StatelessWidget {
  final String? selectedBudget;
  final ValueChanged<String> onSelected;

  const BudgetStep({
    super.key,
    required this.selectedBudget,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);

    final List<Map<String, dynamic>> budgets = [
      {
        'key': 'backpacker',
        'title': 'Backpacker',
        'subtitle': '₹800–1,500/day • Hostels, street food, public transport',
        'icon': Icons.backpack_outlined,
      },
      {
        'key': 'comfort',
        'title': 'Comfort',
        'subtitle': '₹1,500–3,500/day • Budget hotels, local diners, taxis',
        'icon': Icons.hotel_outlined,
      },
      {
        'key': 'premium',
        'title': 'Premium',
        'subtitle': '₹3,500–7,000/day • Boutique stays, fine eats, private cabs',
        'icon': Icons.card_travel_outlined,
      },
      {
        'key': 'luxury',
        'title': 'Luxury',
        'subtitle': '₹7,000+/day • 5-star luxury resorts, premium tours',
        'icon': Icons.diamond_outlined,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select your budget',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24 * textScaleFactor,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We use concrete price anchors to tailor accommodation and food suggestions.',
          style: TextStyle(
            color: const Color.fromRGBO(255, 255, 255, 0.6),
            fontSize: 15 * textScaleFactor,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 24),
        ...budgets.map((budget) {
          final isSelected = selectedBudget == budget['key'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: SelectableCard(
              title: budget['title'],
              subtitle: budget['subtitle'],
              icon: budget['icon'],
              isSelected: isSelected,
              onTap: () => onSelected(budget['key']),
            ),
          );
        }),
      ],
    );
  }
}
