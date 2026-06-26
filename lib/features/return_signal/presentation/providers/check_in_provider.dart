import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/check_in.dart';
import '../../domain/repositories/check_in_repository.dart';
import '../../data/repositories/fake_check_in_repository_impl.dart';

final checkInRepositoryProvider = Provider<CheckInRepository>((ref) {
  return FakeCheckInRepositoryImpl();
});

class CheckInState {
  final CheckIn? checkIn;
  final Duration remaining;
  final bool isLoading;

  const CheckInState({
    this.checkIn,
    this.remaining = Duration.zero,
    this.isLoading = false,
  });

  CheckInState copyWith({
    CheckIn? checkIn,
    Duration? remaining,
    bool? isLoading,
    bool clearCheckIn = false,
  }) {
    return CheckInState(
      checkIn: clearCheckIn ? null : (checkIn ?? this.checkIn),
      remaining: remaining ?? this.remaining,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final checkInProvider = NotifierProvider<CheckInNotifier, CheckInState>(() {
  return CheckInNotifier();
});

class CheckInNotifier extends Notifier<CheckInState> {
  Timer? _timer;

  @override
  CheckInState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return const CheckInState();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.checkIn != null) {
        final now = DateTime.now();
        final diff = state.checkIn!.returnBy.difference(now);
        if (diff.isNegative) {
          state = state.copyWith(remaining: Duration.zero);
        } else {
          state = state.copyWith(remaining: diff);
        }
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> arm({
    required String tripId,
    required String activityName,
    required Duration duration,
    int graceMinutes = 15,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = ref.read(checkInRepositoryProvider);
      final checkIn = await repo.armCheckIn(
        tripId: tripId,
        activityName: activityName,
        returnBy: DateTime.now().add(duration),
        graceMinutes: graceMinutes,
      );
      state = state.copyWith(
        checkIn: checkIn,
        remaining: duration,
        isLoading: false,
      );
      _startTimer();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      // Handle error in real app
    }
  }

  Future<void> disarm() async {
    if (state.checkIn == null) return;
    final checkInId = state.checkIn!.id;
    state = state.copyWith(isLoading: true);
    try {
      final repo = ref.read(checkInRepositoryProvider);
      await repo.disarmCheckIn(checkInId);
      _timer?.cancel();
      state = state.copyWith(clearCheckIn: true, remaining: Duration.zero, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> imBack() async {
    if (state.checkIn == null) return;
    final checkInId = state.checkIn!.id;
    state = state.copyWith(isLoading: true);
    try {
      final repo = ref.read(checkInRepositoryProvider);
      await repo.completeCheckIn(checkInId);
      _timer?.cancel();
      state = state.copyWith(clearCheckIn: true, remaining: Duration.zero, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
}
