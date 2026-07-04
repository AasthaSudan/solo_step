import 'package:flutter/material.dart';

void showAiReplanSheet({
  required BuildContext context,
  required Function(String reason) onReplan,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const AiReplanSheet(),
  ).then((reason) {
    if (reason != null && reason is String) {
      onReplan(reason);
    }
  });
}

class AiReplanSheet extends StatefulWidget {
  const AiReplanSheet({super.key});

  @override
  State<AiReplanSheet> createState() => _AiReplanSheetState();
}

class _AiReplanSheetState extends State<AiReplanSheet> {
  final TextEditingController _customReasonController = TextEditingController();

  final List<Map<String, String>> _quickOptions = [
    {'icon': '🌧️', 'label': "It's raining", 'reason': "It is raining outside, please replace all outdoor activities with indoor ones (like museums, cafes, malls)."},
    {'icon': '🥱', 'label': 'Feeling tired', 'reason': "I am feeling very tired. Please replace high-energy activities with relaxing ones like a spa, cafe, or short walk."},
    {'icon': '💸', 'label': 'Tight budget', 'reason': "I am on a very tight budget right now. Please replace expensive activities or restaurants with free or very cheap alternatives."},
    {'icon': '🧗‍♀️', 'label': 'Adventurous', 'reason': "I am feeling adventurous! Please replace boring or standard sightseeing with thrilling or active options."},
  ];

  void _submitReason(String reason) {
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: bottomInset + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF15102A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFFC77DFF), width: 1.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '✨ AI Travel Companion',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Tell me why you want to replan this itinerary, and I will magically rewrite it for you!',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 24),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _quickOptions.map((opt) {
              return InkWell(
                onTap: () => _submitReason(opt['reason']!),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(199, 125, 255, 0.1),
                    border: Border.all(color: const Color.fromRGBO(199, 125, 255, 0.5)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(opt['icon']!, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        opt['label']!,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          Row(
            children: const [
              Expanded(child: Divider(color: Colors.white24)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('OR', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ),
              Expanded(child: Divider(color: Colors.white24)),
            ],
          ),
          const SizedBox(height: 24),
          
          TextField(
            controller: _customReasonController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'e.g., I suddenly want to eat spicy street food',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF0F0C20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF9D4EDD)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                _submitReason(value.trim());
              }
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9D4EDD),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              if (_customReasonController.text.trim().isNotEmpty) {
                _submitReason(_customReasonController.text.trim());
              }
            },
            child: const Text(
              'Rewrite Itinerary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
