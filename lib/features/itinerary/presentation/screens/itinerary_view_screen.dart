import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../providers/itinerary_provider.dart';
import '../widgets/day_card.dart';
import '../widgets/day_card_skeleton.dart';
import '../../../../features/budget/presentation/providers/budget_provider.dart';
import '../../../../features/budget/presentation/widgets/log_spend_sheet.dart';
import '../../../../features/budget/domain/entities/expense.dart';
import '../widgets/booking_options_view.dart';

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

class _ItineraryViewScreenState extends ConsumerState<ItineraryViewScreen> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late TabController _tabController;
  SpendCategory? _pendingBookingCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.tripId == 'new') {
        ref.read(itineraryProvider.notifier).generateItinerary(widget.destinationName);
      } else {
        ref.read(itineraryProvider.notifier).loadItinerary(widget.tripId);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _pendingBookingCategory != null) {
      final category = _pendingBookingCategory!;
      _pendingBookingCategory = null;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        showLogSpendSheet(
          context,
          initialCategory: category,
          onSave: (cat, amountInr) {
            ref.read(budgetProvider(widget.tripId).notifier).logSpend(cat, amountInr);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Logged ₹$amountInr for ${cat.label}')),
            );
          },
        );
      });
    }
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
    final bool isLoading = asyncItinerary.isLoading || (asyncItinerary.value == null && !asyncItinerary.hasError);
    final bool hasError = asyncItinerary.hasError;

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

              // Budget Progress Bar for existing active trips
              if (widget.tripId != 'new')
                Consumer(
                  builder: (context, ref, child) {
                    final budgetAsync = ref.watch(budgetProvider(widget.tripId));
                    return budgetAsync.when(
                      data: (budgetState) {
                        final summary = budgetState.summary;
                        final spent = summary.spentInr;
                        final budget = summary.totalBudgetInr;
                        final progress = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Budget: ₹$budget',
                                    style: TextStyle(color: Colors.white70, fontSize: 14 * textScale),
                                  ),
                                  Text(
                                    'Spent: ₹$spent',
                                    style: TextStyle(color: Colors.white, fontSize: 14 * textScale, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: progress,
                                backgroundColor: const Color.fromRGBO(255, 255, 255, 0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  progress > 0.9 ? const Color(0xFFEA4335) : const Color(0xFF34A853)
                                ),
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (e, _) => const SizedBox.shrink(),
                    );
                  },
                ),

              // Tabs for Plan and Bookings
              if (!isLoading && !hasError)
                TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFFC77DFF),
                  labelColor: const Color(0xFFC77DFF),
                  unselectedLabelColor: Colors.white54,
                  tabs: const [
                    Tab(text: 'Itinerary Plan'),
                    Tab(text: 'Options & Booking'),
                  ],
                ),
              if (!isLoading && !hasError) const SizedBox(height: 8),

              // Main Schedule Body
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 540.0 : double.infinity,
                    ),
                    child: hasError
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                                const SizedBox(height: 16),
                                Text(
                                  'Failed to generate itinerary. Please try again.',
                                  style: TextStyle(color: Colors.white70, fontSize: 16 * textScale),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _handleRegenerate,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF9D4EDD),
                                  ),
                                  child: const Text('Retry', style: TextStyle(color: Colors.white)),
                                )
                              ],
                            ),
                          )
                        : isLoading
                            ? ListView.builder(
                                key: const ValueKey('loading_itinerary'),
                                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                                itemCount: 3,
                                itemBuilder: (context, index) => const DayCardSkeleton(),
                              )
                            : TabBarView(
                            controller: _tabController,
                            children: [
                              ListView.builder(
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
                              BookingOptionsView(
                                accommodations: asyncItinerary.value!.accommodations,
                                foodOptions: asyncItinerary.value!.foodOptions,
                                onOptionTapped: (cat) {
                                  _pendingBookingCategory = cat;
                                },
                              ),
                            ],
                          ),
                  ),
                ),
              ),

              // Bottom persistent action buttons (disabled during loading, only shown for new trip)
              if (!isLoading && !hasError && widget.tripId == 'new')
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
      floatingActionButton: widget.tripId != 'new'
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFFFBBC05),
              onPressed: () {
                showLogSpendSheet(
                  context,
                  onSave: (category, amountInr) {
                    ref.read(budgetProvider(widget.tripId).notifier).logSpend(category, amountInr);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Logged ₹$amountInr for ${category.label}')),
                    );
                  },
                );
              },
              icon: const Icon(Icons.add, color: Colors.black87),
              label: const Text('Log Spend', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }
}
