import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  Future<void> _launch(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0C20), Color(0xFF15102A), Color(0xFF2E1A47)],
            stops: [0.0, 0.42, 1.0],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF9D4EDD), Color(0xFFC77DFF)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF9D4EDD).withAlpha(55),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.explore_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Explore',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24 * textScale,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Find and book accommodations, transport, and food.',
                                  style: TextStyle(
                                    color: const Color.fromRGBO(255, 255, 255, 0.6),
                                    fontSize: 13 * textScale,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      _SectionHeader(title: 'Accommodation', icon: Icons.hotel_rounded, color: const Color(0xFF4285F4)),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _BookingCard(title: 'MakeMyTrip', subtitle: 'Hotels & Stays', url: 'https://www.makemytrip.com/hotels/', icon: Icons.business, color: const Color(0xFF4285F4), onTap: _launch),
                          _BookingCard(title: 'Agoda', subtitle: 'Global Stays', url: 'https://www.agoda.com/', icon: Icons.map, color: const Color(0xFF4285F4), onTap: _launch),
                          _BookingCard(title: 'Booking.com', subtitle: 'Hotels & Homes', url: 'https://www.booking.com/', icon: Icons.hotel, color: const Color(0xFF4285F4), onTap: _launch),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      _SectionHeader(title: 'Transport', icon: Icons.directions_transit_rounded, color: const Color(0xFF34A853)),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _BookingCard(title: 'IRCTC', subtitle: 'Trains', url: 'https://www.irctc.co.in/', icon: Icons.train, color: const Color(0xFF34A853), onTap: _launch),
                          _BookingCard(title: 'RedBus', subtitle: 'Buses', url: 'https://www.redbus.in/', icon: Icons.directions_bus, color: const Color(0xFF34A853), onTap: _launch),
                          _BookingCard(title: 'MakeMyTrip', subtitle: 'Flights', url: 'https://www.makemytrip.com/flights/', icon: Icons.flight, color: const Color(0xFF34A853), onTap: _launch),
                        ],
                      ),

                      const SizedBox(height: 32),
                      _SectionHeader(title: 'Food & Dining', icon: Icons.restaurant_rounded, color: const Color(0xFFC77DFF)),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _BookingCard(title: 'Zomato', subtitle: 'Order & Dine', url: 'https://www.zomato.com/', icon: Icons.fastfood, color: const Color(0xFFC77DFF), onTap: _launch),
                          _BookingCard(title: 'Swiggy', subtitle: 'Delivery', url: 'https://www.swiggy.com/', icon: Icons.delivery_dining, color: const Color(0xFFC77DFF), onTap: _launch),
                          _BookingCard(title: 'Dineout', subtitle: 'Reservations', url: 'https://www.dineout.co.in/', icon: Icons.restaurant, color: const Color(0xFFC77DFF), onTap: _launch),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                    ],
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader({required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _BookingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String url;
  final IconData icon;
  final Color color;
  final void Function(String) onTap;

  const _BookingCard({
    required this.title,
    required this.subtitle,
    required this.url,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth > 400 ? 180 : (constraints.maxWidth - 12) / 2;
        return GestureDetector(
          onTap: () => onTap(url),
          child: Container(
            width: width,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 255, 255, 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withAlpha(40)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color.withAlpha(200), size: 28),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withAlpha(140),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}
