import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../providers/itinerary_provider.dart';
import '../widgets/day_card.dart';
import '../widgets/day_card_skeleton.dart';
import '../../../../features/budget/presentation/providers/budget_provider.dart';
import '../../../../features/budget/presentation/widgets/log_spend_sheet.dart';
import '../../../../features/budget/domain/entities/expense.dart';
import '../../../../features/budget/presentation/screens/budget_dashboard_view.dart';
import '../widgets/booking_options_view.dart';
import '../widgets/itinerary_map_view.dart';
import '../widgets/ai_replan_sheet.dart';
import '../widgets/packing_list_view.dart';
import '../../domain/entities/itinerary.dart';

/// Screen presenting the full day-by-day travel plan (Layer 1 UI).
/// Simulates itinerary generation on load and offers a complete save workflow.
class ItineraryViewScreen extends ConsumerStatefulWidget {
  final String tripId;
  final String destinationName;
  final int initialTabIndex;

  const ItineraryViewScreen({
    super.key,
    required this.tripId,
    required this.destinationName,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<ItineraryViewScreen> createState() => _ItineraryViewScreenState();
}

class _ItineraryViewScreenState extends ConsumerState<ItineraryViewScreen> with WidgetsBindingObserver {
  SpendCategory? _pendingBookingCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
          onSave: (cat, amountInr, day, label) {
            ref.read(budgetProvider(widget.tripId).notifier).logSpend(cat, amountInr, day: day, label: label);
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
        content: Text('Regenerating itinerary...'),
        duration: Duration(milliseconds: 1200),
      ),
    );
  }

  void _showModal(Widget child, {bool fullScreen = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF7F5F0), // Warm Cream
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: fullScreen ? 0.95 : 0.85,
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 12),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: child,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(Itinerary itinerary) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildActionPill(
            icon: Icons.backpack,
            label: 'Packing',
            onTap: () {
              _showModal(
                PackingListView(tripId: widget.tripId, destinationName: widget.destinationName),
                fullScreen: true,
              );
            },
          ),
          const SizedBox(width: 8),
          _buildActionPill(
            icon: Icons.map_outlined,
            label: 'Map',
            onTap: () {
              _showModal(
                ItineraryMapView(activities: itinerary.days.expand((d) => d.activities).toList()),
                fullScreen: true,
              );
            },
          ),
          const SizedBox(width: 8),
          _buildActionPill(
            icon: Icons.hotel_outlined,
            label: 'Bookings',
            onTap: () {
              _showModal(
                BookingOptionsView(
                  accommodations: itinerary.accommodations,
                  foodOptions: itinerary.foodOptions,
                  transportOptions: itinerary.transportOptions,
                  onOptionTapped: (cat) {
                    Navigator.pop(context);
                    _pendingBookingCategory = cat;
                  },
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          _buildActionPill(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Budget',
            onTap: () {
              _showModal(
                BudgetDashboardView(tripId: widget.tripId),
                fullScreen: true,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionPill({required IconData icon, required String label, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: const Color(0xFF2C3E50), size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
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

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2C3E50),
              onPrimary: Colors.white,
              surface: Color(0xFFF7F5F0),
              onSurface: Color(0xFF1A1A1A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) {
      // User cancelled date selection
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
            startDate: pickedDate,
          );

      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          final textScale = MediaQuery.textScalerOf(context).scale(1.0);
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: Colors.grey.shade200, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C3E50).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_outlined,
                      color: Color(0xFF2C3E50),
                      size: 54,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Trip Saved Successfully!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF1A1A1A),
                      fontSize: 22 * textScale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your ${widget.destinationName} trip is now persisted. You will be redirected to the Home screen in active trip status.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14 * textScale,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C3E50),
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
    final bool isLoading = asyncItinerary.isLoading || (asyncItinerary.valueOrNull == null && !asyncItinerary.hasError);
    final bool hasError = asyncItinerary.hasError;

    final String placeholderUrl =
        'https://loremflickr.com/1200/400/${Uri.encodeComponent(widget.destinationName)},travel,landscape/all';

    return PopScope(
      canPop: widget.tripId != 'new',
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (widget.tripId == 'new') {
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Discard Trip?'),
              content: const Text('If you go back now, this generated itinerary will be lost. Make sure to tap "Save Trip" at the bottom if you want to keep it.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Keep Exploring', style: TextStyle(color: Color(0xFF2C3E50))),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Discard', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ),
          );
          if (shouldPop == true && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F5F0), // Warm Cream
        body: Column(
          children: [
            // Banner Image
            Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: placeholderUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey.shade300, height: 180),
                  errorWidget: (context, url, error) => Container(color: Colors.grey.shade300, height: 180),
                ),
                // Gradient for text readability and fade into background
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                          const Color(0xFFF7F5F0),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white.withValues(alpha: 0.8),
                          child: BackButton(
                            color: const Color(0xFF1A1A1A),
                            onPressed: isLoading ? null : () {
                              if (widget.tripId != 'new') {
                                Navigator.of(context).pop();
                              } else {
                                // Trigger PopScope onPopInvokedWithResult
                                Navigator.of(context).maybePop();
                              }
                            },
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${widget.destinationName} Itinerary',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24 * textScale,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 4),
                            ]
                          ),
                        ),
                      ),
                      if (!isLoading && !hasError)
                        CircleAvatar(
                          backgroundColor: Colors.white.withValues(alpha: 0.8),
                          child: IconButton(
                            icon: const Icon(Icons.auto_awesome, color: Color(0xFF2C3E50)),
                            tooltip: 'AI Replan',
                            onPressed: () {
                              showAiReplanSheet(
                                context: context,
                                onReplan: (reason) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Replanning... this might take a few seconds!')),
                                  );
                                  ref.read(itineraryProvider.notifier).replanItinerary(reason, widget.tripId, widget.destinationName);
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Divider(color: Colors.grey.shade200, height: 1),

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
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14 * textScale),
                                  ),
                                  Text(
                                    'Spent: ₹$spent',
                                    style: TextStyle(color: const Color(0xFF1A1A1A), fontSize: 14 * textScale, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  progress > 0.9 ? const Color(0xFFEA4335) : const Color(0xFF2C3E50)
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

              if (!isLoading && !hasError && asyncItinerary.valueOrNull != null) ...[
                const SizedBox(height: 8),
                _buildQuickActions(asyncItinerary.valueOrNull!),
                const SizedBox(height: 8),
              ],

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
                                  style: TextStyle(color: Colors.grey.shade700, fontSize: 16 * textScale),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _handleRegenerate,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2C3E50),
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
                            : ListView.builder(
                                  key: const ValueKey('loaded_itinerary'),
                                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: asyncItinerary.valueOrNull!.days.length,
                                  itemBuilder: (context, index) {
                                    return DayCard(
                                      day: asyncItinerary.valueOrNull!.days[index],
                                      initiallyExpanded: index == 0,
                                    );
                                  },
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
                                backgroundColor: const Color(0xFF2C3E50),
                                foregroundColor: Colors.white,
                                shadowColor: Colors.black.withOpacity(0.1),
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
                                  side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                                ),
                              ),
                              onPressed: _handleRegenerate,
                              child: Text(
                                'Regenerate Itinerary',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
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
      );
  }
}
