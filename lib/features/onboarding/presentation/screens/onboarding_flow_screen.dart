import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/onboarding_progress_indicator.dart';
import 'steps/mood_step.dart';
import 'steps/budget_step.dart';
import 'steps/duration_step.dart';
import 'steps/interests_step.dart';
import 'steps/experience_step.dart';
import '../providers/onboarding_provider.dart';
import '../providers/user_profile_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/user_profile.dart';

/// The parent container for the 5-step onboarding quiz flow (Layer 1 UI).
class OnboardingFlowScreen extends ConsumerStatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  ConsumerState<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  final PageController _pageController = PageController();
  int _currentStepIndex = 0; // 0-indexed (0 to 4)

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentStepIndex < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _previousPage() {
    if (_currentStepIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  // Auto-advances the page after a brief delay for single-select UX
  void _autoAdvance() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _nextPage();
      }
    });
  }

  void _toggleInterest(String interest) {
    ref.read(onboardingProvider.notifier).toggleInterest(interest);
  }

  void _finishOnboarding() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final textScale = MediaQuery.textScalerOf(context).scale(1.0);
        return Dialog(
          backgroundColor: const Color(0xFF15102A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFC77DFF), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(199, 125, 255, 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFFE0AAFF),
                    size: 54,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Onboarding Complete!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22 * textScale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Profile logic and Gemini recommendations will be wired in Phase B/Layer 2.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color.fromRGBO(255, 255, 255, 0.7),
                    fontSize: 14 * textScale,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                  SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9D4EDD),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () async {
                      final onboardingState = ref.read(onboardingProvider);
                      final authUser = ref.read(authStateProvider).value;
                      if (authUser != null) {
                        final profile = UserProfile(
                          mood: onboardingState.mood ?? 'chill',
                          budgetTier: onboardingState.budgetTier ?? 'comfort',
                          budgetPerDayMin: 1500,
                          budgetPerDayMax: 3500,
                          tripDuration: onboardingState.tripDuration ?? 'short_trip',
                          interests: onboardingState.interests,
                          experienceLevel: onboardingState.experienceLevel ?? 'first_timer',
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        );
                        await ref.read(profileRepositoryProvider).saveProfile(authUser.uid, profile);
                        ref.invalidate(userProfileProvider);
                      }
                      if (context.mounted) {
                        context.go('/home');
                      }
                    },
                    child: Text(
                      'Go to Home Screen',
                      style: TextStyle(
                        fontSize: 16 * textScale,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isTablet = screenSize.width > 600;
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);
    final onboardingState = ref.watch(onboardingProvider);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0C20), // Dark space blue
              Color(0xFF15102A), // Deep indigo
              Color(0xFF2E1A47), // Rich twilight purple
            ],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Progress Row
              OnboardingProgressIndicator(
                currentStep: _currentStepIndex + 1,
                totalSteps: 5,
                onBack: _previousPage,
              ),
              
              // PageView Content
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      // Restrict content width on tablets
                      maxWidth: isTablet ? 520.0 : double.infinity,
                    ),
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(), // Force step selection navigation
                      onPageChanged: (index) {
                        setState(() {
                          _currentStepIndex = index;
                        });
                      },
                      children: [
                        // Step 1: Mood
                        SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          child: MoodStep(
                            selectedMood: onboardingState.mood,
                            onSelected: (mood) {
                              ref.read(onboardingProvider.notifier).setMood(mood);
                              _autoAdvance();
                            },
                          ),
                        ),
                        // Step 2: Budget
                        SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          child: BudgetStep(
                            selectedBudget: onboardingState.budgetTier,
                            onSelected: (budget) {
                              ref.read(onboardingProvider.notifier).setBudget(budget);
                              _autoAdvance();
                            },
                          ),
                        ),
                        // Step 3: Duration
                        SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          child: DurationStep(
                            selectedDuration: onboardingState.tripDuration,
                            onSelected: (duration) {
                              ref.read(onboardingProvider.notifier).setDuration(duration);
                              _autoAdvance();
                            },
                          ),
                        ),
                        // Step 4: Interests (Multi-select with explicit Next button)
                        SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          child: InterestsStep(
                            selectedInterests: onboardingState.interests,
                            onToggle: _toggleInterest,
                          ),
                        ),
                        // Step 5: Experience
                        SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          child: ExperienceStep(
                            selectedExperience: onboardingState.experienceLevel,
                            onSelected: (exp) {
                              ref.read(onboardingProvider.notifier).setExperience(exp);
                              Future.delayed(const Duration(milliseconds: 300), _finishOnboarding);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Bottom Persistent Actions (Only visible for Interests multi-select step)
              if (_currentStepIndex == 3)
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 520.0 : double.infinity,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: onboardingState.interests.isNotEmpty ? 1.0 : 0.4,
                              child: IgnorePointer(
                                ignoring: onboardingState.interests.isEmpty,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF9D4EDD), // Violet color matching the theme
                                    foregroundColor: Colors.white,
                                    shadowColor: const Color.fromRGBO(157, 78, 221, 0.5),
                                    elevation: 6,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: _nextPage,
                                  child: Text(
                                    'Next',
                                    style: TextStyle(
                                      fontSize: 16 * textScaleFactor,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
