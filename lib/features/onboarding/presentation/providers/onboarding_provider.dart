import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingState {
  final String? mood;
  final String? budgetTier;
  final String? tripDuration;
  final List<String> interests;
  final String? experienceLevel;

  const OnboardingState({
    this.mood,
    this.budgetTier,
    this.tripDuration,
    this.interests = const [],
    this.experienceLevel,
  });

  OnboardingState copyWith({
    String? mood,
    String? budgetTier,
    String? tripDuration,
    List<String>? interests,
    String? experienceLevel,
  }) {
    return OnboardingState(
      mood: mood ?? this.mood,
      budgetTier: budgetTier ?? this.budgetTier,
      tripDuration: tripDuration ?? this.tripDuration,
      interests: interests ?? this.interests,
      experienceLevel: experienceLevel ?? this.experienceLevel,
    );
  }
}

class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState();

  void setMood(String mood) {
    state = state.copyWith(mood: mood);
  }

  void setBudget(String budgetTier) {
    state = state.copyWith(budgetTier: budgetTier);
  }

  void setDuration(String duration) {
    state = state.copyWith(tripDuration: duration);
  }

  void toggleInterest(String interest) {
    final currentInterests = List<String>.from(state.interests);
    if (currentInterests.contains(interest)) {
      currentInterests.remove(interest);
    } else {
      currentInterests.add(interest);
    }
    state = state.copyWith(interests: currentInterests);
  }

  void setExperience(String experience) {
    state = state.copyWith(experienceLevel: experience);
  }
}

final onboardingProvider = NotifierProvider<OnboardingNotifier, OnboardingState>(() {
  return OnboardingNotifier();
});
