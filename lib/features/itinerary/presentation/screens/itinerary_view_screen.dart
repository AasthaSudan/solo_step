import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../providers/itinerary_provider.dart';
import '../widgets/day_card.dart';
import '../widgets/day_card_skeleton.dart';

/// Screen presenting the full day-by-day travel plan (Layer 1 UI).
/// Simulates itinerary generation on load and offers a complete save workflow.
class ItineraryViewScreen extends ConsumerStatefulWidget {
  final String tripId;
  final String destinationName;

  const ItineraryViewScreen({
    super.key,
    required this.tripId,
    required this.destinationName,
  });

  @override
  ConsumerState<ItineraryViewScreen> createState() => _ItineraryViewScreenState();
}

class _ItineraryViewScreenState extends ConsumerState<ItineraryViewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(itineraryProvider.notifier).generateItinerary(widget.destinationName);
    });
  }

  void _handleRegenerate() {
    ref.read(itineraryProvider.notifier).generateItinerary(widget.destinationName);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Regenerating itinerary using Gemini Call #2 (Mock)...'),
        duration: Duration(milliseconds: 1200),
      ),
    );
  }

  bool _isSaving = false;

  Future<void> _handleSaveAndStartPlanning() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to save a trip.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final tripId = const Uuid().v4();
      await ref.read(itineraryProvider.notifier).saveTrip(
            user.uid,
            tripId,
            widget.destinationName,
          );

      if (!mounted) return;
      
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
                      Icons.verified_outlined,
                      color: Color(0xFFE0AAFF),
                      size: 54,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Trip Saved Successfully!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22 * textScale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your ${widget.destinationName} trip is now persisted. You will be redirected to the Home screen in active trip status.',
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
                      onPressed: () {
                        Navigator.of(context).pop(); // dismiss dialog
                        context.go('/home', extra: const {'startWithActiveTrip': true});
                      },
                      child: Text(
                        'Go to Dashboard',
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save trip: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isTablet = screenSize.width > 600;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    
    final asyncItinerary = ref.watch(itineraryProvider);
    final isLoading = asyncItinerary.isLoading || asyncItinerary.value == null;

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
              // Custom Header Row (Back Button & Title)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                      tooltip: 'Back to Details',
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${widget.destinationName} Itinerary',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20 * textScale,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(color: Color.fromRGBO(255, 255, 255, 0.08), height: 1),

              // Main Schedule Body
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 540.0 : double.infinity,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: isLoading
                          ? ListView.builder(
                              key: const ValueKey('loading_itinerary'),
                              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                              itemCount: 3,
                              itemBuilder: (context, index) => const DayCardSkeleton(),
                            )
                          : ListView.builder(
                              key: const ValueKey('loaded_itinerary'),
                              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                              physics: const BouncingScrollPhysics(),
                              itemCount: asyncItinerary.value!.days.length,
                              itemBuilder: (context, index) {
                                return DayCard(
                                  day: asyncItinerary.value!.days[index],
                                  initiallyExpanded: index == 0, // Keep first day expanded by default
                                );
                              },
                            ),
                    ),
                  ),
                ),
              ),

              // Bottom persistent action buttons (disabled during loading)
              if (!isLoading)
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 540.0 : double.infinity,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Primary Save & Plan Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF9D4EDD),
                                foregroundColor: Colors.white,
                                shadowColor: const Color.fromRGBO(157, 78, 221, 0.5),
                                elevation: 6,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _isSaving ? null : _handleSaveAndStartPlanning,
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      'Save & Start Planning',
                                      style: TextStyle(
                                        fontSize: 16 * textScale,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Secondary Regenerate Button
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: const BorderSide(color: Color.fromRGBO(255, 255, 255, 0.12), width: 1.5),
                                ),
                              ),
                              onPressed: _handleRegenerate,
                              child: Text(
                                'Regenerate Itinerary',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15 * textScale,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
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
