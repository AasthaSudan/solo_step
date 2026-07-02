import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/itinerary.dart';
import '../../domain/repositories/itinerary_repository.dart';
import '../../data/repositories/gemini_itinerary_repository_impl.dart';
import 'package:firebase_auth/firebase_auth.dart';

final itineraryRepositoryProvider = Provider<ItineraryRepository>((ref) {
  return GeminiItineraryRepositoryImpl();
});

class ItineraryNotifier extends Notifier<AsyncValue<Itinerary?>> {
  @override
  AsyncValue<Itinerary?> build() {
    return const AsyncData(null); // Initially no itinerary
  }

  Future<void> generateItinerary(String destinationName) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(itineraryRepositoryProvider);
      final itinerary = await repository.generateItinerary(destinationName);
      state = AsyncData(itinerary);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> loadItinerary(String tripId) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(itineraryRepositoryProvider);
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('User not logged in');
      
      final itinerary = await repository.getTripItinerary(uid, tripId);
      state = AsyncData(itinerary);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> saveTrip(String uid, String tripId, String destinationName, {DateTime? startDate}) async {
    final currentItinerary = state.value;
    if (currentItinerary == null) {
      throw Exception('No itinerary to save');
    }
    
    final repository = ref.read(itineraryRepositoryProvider);
    await repository.saveTrip(uid, tripId, destinationName, currentItinerary, startDate: startDate);
  }
}

final itineraryProvider = NotifierProvider<ItineraryNotifier, AsyncValue<Itinerary?>>(() {
  return ItineraryNotifier();
});
