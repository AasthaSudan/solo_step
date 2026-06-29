import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/debrief_provider.dart';
import '../widgets/debrief_card_widget.dart';

/// The screen displaying the trip's final AI debrief card.
///
/// It provides a "Share Story Card" action that captures the card component
/// to share to social platforms, and a "Done" action to return to the dashboard.
class DebriefScreen extends ConsumerStatefulWidget {
  final String tripId;
  const DebriefScreen({super.key, required this.tripId});

  @override
  ConsumerState<DebriefScreen> createState() => _DebriefScreenState();
}

class _DebriefScreenState extends ConsumerState<DebriefScreen> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareCard() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      final boundary = _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception("Could not find card boundary");
      }
      
      // Capture the image at a high pixel ratio for sharpness
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/soloready_debrief.png');
      await file.writeAsBytes(pngBytes);

      // Trigger the native share sheet
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Check out my travel personality on SoloReady! ✈️🌍',
      );

      if (result.status == ShareResultStatus.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card shared successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share card: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final debriefAsync = ref.watch(debriefProvider(widget.tripId));
    final bool isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Trip Debrief',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20 * textScale,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF0F081D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F081D), // Dark Space Violet
              Color(0xFF1E0E3B), // Midnight Purple
              Color(0xFF0F081D), // Dark Space Violet
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isTablet ? 540.0 : double.infinity,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Completion Title Callout
                    Text(
                      'Trip Completed! 🎉',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22 * textScale,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Here is your custom travel personality card synthesized from your budget and safety loops.',
                      style: TextStyle(
                        color: const Color.fromRGBO(255, 255, 255, 0.6),
                        fontSize: 14 * textScale,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),

                    // The Debrief Card Widget
                    debriefAsync.when(
                      data: (card) {
                        if (card == null) return const SizedBox();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            RepaintBoundary(
                              key: _cardKey,
                              child: DebriefCardWidget(card: card),
                            ),
                            const SizedBox(height: 32),

                            // Actions
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF9D4EDD),
                                foregroundColor: Colors.white,
                                shadowColor: const Color.fromRGBO(157, 78, 221, 0.4),
                                elevation: 8,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: _isSharing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Icon(Icons.share_rounded, size: 20),
                              label: Text(
                                _isSharing ? 'Preparing...' : 'Share Story Card',
                                style: TextStyle(
                                  fontSize: 16 * textScale,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              onPressed: _shareCard,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color.fromRGBO(255, 255, 255, 0.7),
                                side: const BorderSide(
                                  color: Color.fromRGBO(255, 255, 255, 0.15),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () => context.pop(),
                              child: Text(
                                'Done',
                                style: TextStyle(
                                  fontSize: 16 * textScale,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 64.0),
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                      error: (err, stack) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 64.0),
                        child: Center(
                          child: Text(
                            'Failed to generate debrief: $err',
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
