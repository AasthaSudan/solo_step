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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.grey.shade200),
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
                  color: Color(0xFF1A1A1A),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tell me why you want to replan this itinerary, and I will magically rewrite it for you!',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
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
                    color: Colors.grey.shade50,
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(opt['icon']!, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        opt['label']!,
                        style: const TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('OR', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300)),
            ],
          ),
          const SizedBox(height: 24),
          
          TextField(
            controller: _customReasonController,
            style: const TextStyle(color: Color(0xFF1A1A1A)),
            decoration: InputDecoration(
              hintText: 'e.g., I suddenly want to eat spicy street food',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF2C3E50)),
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
              backgroundColor: const Color(0xFF2C3E50),
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
