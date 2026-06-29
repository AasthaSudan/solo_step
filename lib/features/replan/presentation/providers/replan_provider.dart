import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/replan_result.dart';
import '../../domain/repositories/replan_repository.dart';
import '../../data/repositories/gemini_replan_repository_impl.dart';

final replanRepositoryProvider = Provider<ReplanRepository>((ref) {
  return GeminiReplanRepositoryImpl();
});

final replanProvider = AsyncNotifierProvider<ReplanNotifier, ReplanResult?>(() {
  return ReplanNotifier();
});

class ReplanNotifier extends AsyncNotifier<ReplanResult?> {
  // We need to keep track of the tripId so we can accept the replan
  String? _currentTripId;

  @override
  FutureOr<ReplanResult?> build() {
    return null; // Null means no replan requested/active
  }

  Future<void> requestReplan(String tripId, int remainingBudgetInr) async {
    _currentTripId = tripId;
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(replanRepositoryProvider);
      final result = await repo.requestReplan(
        tripId: tripId,
        remainingBudgetInr: remainingBudgetInr,
      );
      state = AsyncValue.data(result);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> accept() async {
    if (state.value == null || _currentTripId == null) return;
    
    try {
      final repo = ref.read(replanRepositoryProvider);
      await repo.acceptReplan(
        tripId: _currentTripId!,
        newItinerary: state.value!.newItinerary,
      );
      state = const AsyncValue.data(null);
    } catch (e) {
      // In a real app we'd probably want to show an error state here, but for now dismiss
      state = const AsyncValue.data(null);
    }
  }

  void dismiss() {
    state = const AsyncValue.data(null);
  }
}
