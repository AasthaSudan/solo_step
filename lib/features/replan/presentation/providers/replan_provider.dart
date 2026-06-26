import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/proposed_swap.dart';
import '../../domain/repositories/replan_repository.dart';
import '../../data/repositories/fake_replan_repository_impl.dart';

final replanRepositoryProvider = Provider<ReplanRepository>((ref) {
  return FakeReplanRepositoryImpl();
});

final replanProvider = AsyncNotifierProvider<ReplanNotifier, List<ProposedSwap>?>(() {
  return ReplanNotifier();
});

class ReplanNotifier extends AsyncNotifier<List<ProposedSwap>?> {
  @override
  FutureOr<List<ProposedSwap>?> build() {
    return null; // Null means no replan requested/active
  }

  Future<void> requestReplan(String tripId, int remainingBudgetInr) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(replanRepositoryProvider);
      final swaps = await repo.requestReplan(
        tripId: tripId,
        remainingBudgetInr: remainingBudgetInr,
      );
      state = AsyncValue.data(swaps);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void accept() {
    // In a real app, this would write the changes back to the Trip's itinerary.
    state = const AsyncValue.data(null);
  }

  void dismiss() {
    state = const AsyncValue.data(null);
  }
}
