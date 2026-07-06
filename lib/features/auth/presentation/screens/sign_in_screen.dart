import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/guest_sign_in_link.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

/// A premium, responsive sign-in screen (Layer 1 UI).
/// Adapts gracefully to phones and tablets.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      if (mounted) {
        context.go('/onboarding');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGuestSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    
    try {
      await ref.read(authRepositoryProvider).signInAnonymously();
      if (mounted) {
        context.go('/onboarding');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isTablet = screenSize.width > 600;
    
    // Scale typography/padding based on screen size dynamically
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);
    final double paddingHorizontal = isTablet ? 40.0 : 24.0;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFF7F5F0),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      // Limit width on tablets to keep elements readable/premium
                      maxWidth: isTablet ? 480.0 : double.infinity,
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: paddingHorizontal,
                        vertical: 24.0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Top Spacer
                          const SizedBox(height: 20),

                          // Brand Branding Section
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Glassmorphic Logo Container
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeOut,
                                padding: const EdgeInsets.all(24.0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.explore_outlined,
                                  size: isTablet ? 80.0 : 64.0,
                                  color: const Color(0xFF2C3E50),
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // App Name
                              Text(
                                'SoloStep',
                                style: TextStyle(
                                  color: const Color(0xFF1A1A1A),
                                  fontSize: (isTablet ? 36.0 : 32.0) * textScaleFactor,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              // Tagline
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Text(
                                  'Your AI companion for solo travel',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 16.0 * textScaleFactor,
                                    fontWeight: FontWeight.w400,
                                    height: 1.4,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Bottom Controls Section
                          Padding(
                            padding: const EdgeInsets.only(top: 40.0, bottom: 20.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Action Button
                                GoogleSignInButton(
                                  onPressed: _isLoading ? () {} : () => _handleGoogleSignIn(),
                                ),
                                const SizedBox(height: 20),
                                
                                // Anonymous Path Link
                                GuestSignInLink(
                                  onPressed: _isLoading ? () {} : () => _handleGuestSignIn(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
