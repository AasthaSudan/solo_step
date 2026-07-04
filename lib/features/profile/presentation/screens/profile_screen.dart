import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../onboarding/presentation/providers/user_profile_provider.dart';
import '../../../onboarding/domain/entities/user_profile.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final authStateAsync = ref.watch(authStateProvider);

    final String email = authStateAsync.value?.email ?? 'wanderer@example.com';
    final String name = (authStateAsync.value?.isAnonymous == true) ? 'Guest Explorer' : 'Aastha Sudan';

    return Scaffold(
      backgroundColor: const Color(0xFF0F0B1E),
      body: Stack(
        children: [
          // Background blobs for atmosphere
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF9D4EDD).withAlpha(40),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFC77DFF).withAlpha(30),
              ),
            ),
          ),
          // Blur overlay
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40.0, sigmaY: 40.0),
            child: Container(color: Colors.transparent),
          ),
          
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Header / Avatar ──────────────────────────────
                          Center(
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF9D4EDD), Color(0xFFC77DFF)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF9D4EDD).withAlpha(80),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const CircleAvatar(
                                    radius: 56,
                                    backgroundColor: Color(0xFF15102A),
                                    child: Icon(Icons.person, size: 60, color: Color(0xFFE0AAFF)),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF15102A),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.edit, size: 16, color: Color(0xFFE0AAFF)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // ── Name & Email ───────────────────────────────
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            email,
                            style: const TextStyle(
                              color: Color.fromRGBO(255, 255, 255, 0.6),
                              fontSize: 15,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 48),
                          
                          // ── Travel Vibes Section ────────────────────────
                          const Text(
                            'Your Travel Persona',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          profileAsync.when(
                            data: (profile) {
                              if (profile == null) {
                                return _buildEmptyVibeState();
                              }
                              return _buildVibeCard(profile, context);
                            },
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: CircularProgressIndicator(color: Color(0xFF9D4EDD)),
                              ),
                            ),
                            error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent))),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // ── Account Settings ────────────────────────────
                          const Text(
                            'Settings',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildSettingTile(
                            icon: Icons.notifications_outlined,
                            title: 'Notifications',
                            onTap: () {},
                          ),
                          const SizedBox(height: 12),
                          _buildSettingTile(
                            icon: Icons.security_outlined,
                            title: 'Privacy & Security',
                            onTap: () {},
                          ),
                          const SizedBox(height: 12),
                          _buildSettingTile(
                            icon: Icons.help_outline,
                            title: 'Help & Support',
                            onTap: () {},
                          ),
                          
                          const SizedBox(height: 48),
                          
                          // ── Sign Out Button ─────────────────────────────
                          Center(
                            child: InkWell(
                              onTap: () async {
                                await ref.read(authRepositoryProvider).signOut();
                                if (context.mounted) {
                                  context.go('/sign-in');
                                }
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withAlpha(20),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.redAccent.withAlpha(80)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.logout, color: Colors.redAccent, size: 20),
                                    SizedBox(width: 12),
                                    Text(
                                      'Sign Out',
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVibeCard(UserProfile profile, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF15102A).withAlpha(150),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color.fromRGBO(199, 125, 255, 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(157, 78, 221, 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: Color(0xFFC77DFF), size: 20),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'AI Travel Vibe',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Re-take onboarding quiz to change vibe!')),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFC77DFF),
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Edit', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildVibeRow('Mood', profile.mood, Icons.mood),
          const SizedBox(height: 16),
          _buildVibeRow('Interests', profile.interests.join(', '), Icons.explore),
        ],
      ),
    );
  }

  Widget _buildVibeRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color.fromRGBO(255, 255, 255, 0.4)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color.fromRGBO(255, 255, 255, 0.4),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyVibeState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF15102A).withAlpha(150),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.05)),
      ),
      child: const Center(
        child: Text(
          'No travel profile set up yet.',
          style: TextStyle(color: Colors.white54),
        ),
      ),
    );
  }

  Widget _buildSettingTile({required IconData icon, required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF15102A).withAlpha(150),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 14),
          ],
        ),
      ),
    );
  }
}
