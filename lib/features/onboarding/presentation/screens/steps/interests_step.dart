import 'package:flutter/material.dart';
import '../../widgets/selectable_chip.dart';

/// Step 4: Interests Multi-Selection
class InterestsStep extends StatelessWidget {
  final List<String> selectedInterests;
  final ValueChanged<String> onToggle;

  const InterestsStep({
    super.key,
    required this.selectedInterests,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);

    final List<Map<String, String>> interests = [
      {'key': 'nature', 'label': '🌲 Nature & hiking'},
      {'key': 'food', 'label': '🍜 Food & street eats'},
      {'key': 'history', 'label': '🏰 History & monuments'},
      {'key': 'nightlife', 'label': '🍷 Nightlife'},
      {'key': 'art', 'label': '🎨 Art & museums'},
      {'key': 'beaches', 'label': '🌊 Beaches'},
      {'key': 'offbeat', 'label': '💎 Offbeat/hidden gems'},
      {'key': 'wellness', 'label': '🧘 Wellness & spirituality'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose your interests',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24 * textScaleFactor,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select at least one category to curate sightseeing and culinary options.',
          style: TextStyle(
            color: const Color.fromRGBO(255, 255, 255, 0.6),
            fontSize: 15 * textScaleFactor,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 32),
        // Responsive wrapping list of chips
        Center(
          child: Wrap(
            spacing: 12.0,
            runSpacing: 16.0,
            alignment: WrapAlignment.center,
            children: interests.map((interest) {
              final isSelected = selectedInterests.contains(interest['key']);
              return SelectableChip(
                label: interest['label']!,
                isSelected: isSelected,
                onTap: () => onToggle(interest['key']!),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
