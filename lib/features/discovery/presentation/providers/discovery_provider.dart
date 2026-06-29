import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/destination.dart';
import '../../domain/repositories/destination_repository.dart';
import '../../data/repositories/gemini_destination_repository_impl.dart';

final destinationRepositoryProvider = Provider<DestinationRepository>((ref) {
  return GeminiDestinationRepositoryImpl();
});

class DiscoveryNotifier extends Notifier<AsyncValue<List<Destination>>> {
  @override
  AsyncValue<List<Destination>> build() {
    return const AsyncData([]); // Initial state: empty list
  }

  Future<void> triggerGeneration(String uid) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(destinationRepositoryProvider);
      final destinations = await repository.generateDestinations(uid);
      state = AsyncData(destinations);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final discoveryResultsProvider = NotifierProvider<DiscoveryNotifier, AsyncValue<List<Destination>>>(() {
  return DiscoveryNotifier();
});
