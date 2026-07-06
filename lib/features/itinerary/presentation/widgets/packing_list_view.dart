import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/itinerary.dart';
import '../providers/itinerary_provider.dart';

class PackingListView extends ConsumerWidget {
  final String tripId;
  final String destinationName;

  const PackingListView({
    super.key,
    required this.tripId,
    required this.destinationName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itineraryState = ref.watch(itineraryProvider);
    final isGenerating = itineraryState.isLoading;

    return itineraryState.maybeWhen(
      data: (itinerary) {
        if (itinerary == null) return const SizedBox.shrink();

        if (itinerary.packingList.isEmpty) {
          return _buildEmptyState(context, ref, isGenerating);
        }

        return _buildList(context, ref, itinerary, isGenerating);
      },
      orElse: () => const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, bool isGenerating) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF2C3E50).withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.backpack,
                size: 64,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Packing List Yet',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Let Gemini analyze your itinerary, the local weather, and cultural norms to generate a hyper-personalized checklist for you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: isGenerating
                    ? null
                    : () {
                        ref.read(itineraryProvider.notifier).generatePackingList(tripId, destinationName);
                      },
                icon: isGenerating
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  isGenerating ? 'Generating...' : '✨ Generate Smart Packing List',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C3E50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref, Itinerary itinerary, bool isGenerating) {
    // Group by category
    final groupedItems = <String, List<dynamic>>{};
    int totalItems = itinerary.packingList.length;
    int packedItems = itinerary.packingList.where((i) => i.isPacked).length;
    double progress = totalItems > 0 ? packedItems / totalItems : 0.0;

    for (var item in itinerary.packingList) {
      if (!groupedItems.containsKey(item.category)) {
        groupedItems[item.category] = [];
      }
      groupedItems[item.category]!.add(item);
    }

    return Stack(
      children: [
        Column(
          children: [
            // Progress Indicator
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Packing Progress',
                    style: TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$packedItems / $totalItems',
                    style: const TextStyle(
                      color: Color(0xFF2C3E50),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2C3E50)),
                borderRadius: BorderRadius.circular(4),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: groupedItems.keys.length,
                itemBuilder: (context, index) {
                  final category = groupedItems.keys.elementAt(index);
                  final items = groupedItems[category]!;

                  int packedInCategory = items.where((i) => i.isPacked).length;

                  return Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent, // Remove borders
                    ),
                    child: ExpansionTile(
                      initiallyExpanded: true,
                      iconColor: const Color(0xFF2C3E50),
                      collapsedIconColor: Colors.grey.shade500,
                      title: Row(
                        children: [
                          Text(
                            category.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$packedInCategory/${items.length}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      children: items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          child: InkWell(
                            onTap: () {
                              ref.read(itineraryProvider.notifier).togglePackingItem(item.id, tripId, destinationName);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: item.isPacked ? const Color(0xFF2C3E50).withOpacity(0.06) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: item.isPacked ? const Color(0xFF2C3E50).withOpacity(0.2) : Colors.grey.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    item.isPacked ? Icons.check_circle : Icons.radio_button_unchecked,
                                    color: item.isPacked ? const Color(0xFF2C3E50) : Colors.grey.shade400,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: TextStyle(
                                        color: item.isPacked ? Colors.grey.shade500 : const Color(0xFF1A1A1A),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        decoration: item.isPacked ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.info_outline, size: 20, color: Colors.grey.shade500),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      _showReasonDialog(context, item.name, item.reason);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        if (isGenerating)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  void _showReasonDialog(BuildContext context, String itemName, String reason) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade200, width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFF2C3E50)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                itemName,
                style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          reason,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it', style: TextStyle(color: Color(0xFF2C3E50))),
          ),
        ],
      ),
    );
  }
}
