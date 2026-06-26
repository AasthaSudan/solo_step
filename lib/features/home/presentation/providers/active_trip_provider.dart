import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActiveTripNotifier extends Notifier<AsyncValue<bool>> {
  @override
  AsyncValue<bool> build() {
    return const AsyncData(false); // Default to no active trip
  }

  void setHasActiveTrip(bool hasTrip) {
    state = AsyncData(hasTrip);
  }

  void toggleTripStatus() {
    final current = state.value ?? false;
    state = AsyncData(!current);
  }
}

final activeTripProvider = NotifierProvider<ActiveTripNotifier, AsyncValue<bool>>(() {
  return ActiveTripNotifier();
});
