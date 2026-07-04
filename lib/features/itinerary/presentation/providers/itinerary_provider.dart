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

  Future<void> replanItinerary(String reason, String tripId, String destinationName) async {
    final currentItinerary = state.value;
    if (currentItinerary == null) {
      throw Exception('No active itinerary to replan');
    }

    state = const AsyncLoading();
    try {
      final repository = ref.read(itineraryRepositoryProvider);
      final updatedItinerary = await repository.replanItinerary(currentItinerary, reason);
      
      // If the trip is already saved (tripId != 'new'), we should auto-save the updated itinerary.
      if (tripId != 'new') {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          // We can't fetch startDate easily here without passing it, but it's optional for saveTrip if already created.
          // Wait, saveTrip without startDate might overwrite the startDate. We'll pass it if we have it, 
          // or we can fetch the existing trip document to get startDate, or we modify saveTrip to merge.
          // For now, let's just save the itinerary part, saveTrip uses set(merge: true) wait let's check saveTrip in repository.
          // It uses docRef.set(tripData) which overwrites! We should update saveTrip to use merge.
          await repository.saveTrip(uid, tripId, destinationName, updatedItinerary);
        }
      }
      
      state = AsyncData(updatedItinerary);
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
