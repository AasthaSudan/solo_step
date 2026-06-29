import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/debrief_card.dart';
import '../../domain/repositories/debrief_repository.dart';
import '../../data/repositories/gemini_debrief_repository_impl.dart';
import '../../../budget/presentation/providers/budget_provider.dart';

final debriefRepositoryProvider = Provider<DebriefRepository>((ref) {
  return GeminiDebriefRepositoryImpl();
});

final debriefProvider = AsyncNotifierProvider.family<DebriefNotifier, DebriefCard?, String>(() {
  return DebriefNotifier();
});

class DebriefNotifier extends FamilyAsyncNotifier<DebriefCard?, String> {
  @override
  FutureOr<DebriefCard?> build(String arg) async {
    return _generate(arg);
  }

  Future<DebriefCard> _generate(String tripId) async {
    // We await the future from budgetProvider to get the fully loaded summary and expenses
    final budgetState = await ref.read(budgetProvider(tripId).future);

    final debriefCard = await ref.read(debriefRepositoryProvider).generateAndSaveDebrief(
      tripId: tripId,
      summary: budgetState.summary,
      expenses: budgetState.expenses,
    );
    
    return debriefCard;
  }

  Future<void> regenerate() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _generate(arg));
  }
}
