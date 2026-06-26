import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/debrief_card.dart';
import '../../domain/repositories/debrief_repository.dart';
import '../../data/repositories/fake_debrief_repository_impl.dart';

final debriefRepositoryProvider = Provider<DebriefRepository>((ref) {
  return FakeDebriefRepositoryImpl();
});

final debriefProvider = AsyncNotifierProvider<DebriefNotifier, DebriefCard?>(() {
  return DebriefNotifier();
});

class DebriefNotifier extends AsyncNotifier<DebriefCard?> {
  @override
  FutureOr<DebriefCard?> build() async {
    return _generate('mock_trip_1');
  }

  Future<DebriefCard> _generate(String tripId) async {
    final flavor = await ref.read(debriefRepositoryProvider).fetchFlavor(tripId);
    
    // Fake BudgetSummary derived numbers for Layer 2
    return DebriefCard(
      personality: flavor.personality,
      traits: flavor.traits,
      caption: flavor.caption,
      savedVsEstimateInr: 2150,
      totalSpentInr: 15350,
      daysCount: 5,
      topCategory: 'Stay',
      checkInsCompleted: 8,
    );
  }

  Future<void> regenerate(String tripId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _generate(tripId));
  }
}
