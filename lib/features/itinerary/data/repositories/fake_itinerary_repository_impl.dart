import 'dart:async';
import '../../domain/entities/itinerary.dart';
import '../../domain/entities/itinerary_day.dart';
import '../../domain/entities/itinerary_activity.dart';
import '../../domain/repositories/itinerary_repository.dart';

class FakeItineraryRepositoryImpl implements ItineraryRepository {
  @override
  Future<Itinerary> generateItinerary(String destinationName) async {
    await Future.delayed(const Duration(milliseconds: 1500)); // Simulate Gemini latency
    
    return const Itinerary(
      days: [
        ItineraryDay(
          dayNumber: 1,
          stayName: 'Misty Mountain Resort',
          stayCost: 1800.0,
          foodSuggestions: [
            'Saravana Bhavan (Authentic Kerala Thali)',
            'Rapsy Restaurant (Famous for Spanish Omelettes & Parotta)'
          ],
          activities: [
            ItineraryActivity(
              time: 'morning',
              title: 'Arrival & Resort Check-in',
              category: 'transport',
              estimatedCost: 250.0,
              notes: 'Take a pre-booked local auto-rickshaw from Munnar main town bus terminal directly to the hillside resort.',
            ),
            ItineraryActivity(
              time: 'afternoon',
              title: 'Local Lunch & Tea Museum History Tour',
              category: 'food',
              estimatedCost: 350.0,
              notes: 'Enjoy authentic meals followed by a guided walk through India\'s first tea museum learning vintage machinery.',
            ),
            ItineraryActivity(
              time: 'evening',
              title: 'Lockhart Gap Valley Sunset Walk',
              category: 'sightseeing',
              estimatedCost: 100.0,
              notes: 'Take a scenic walk along the winding mountain road overlooking lush green twilight gorges.',
            ),
          ],
        ),
        ItineraryDay(
          dayNumber: 2,
          stayName: 'Misty Mountain Resort',
          stayCost: 1800.0,
          foodSuggestions: [
            'Claypot Organic Diner (Local farm-to-table cuisine)',
            'Estate Chai shop (Fresh hot cardamom tea & banana fritters)'
          ],
          activities: [
            ItineraryActivity(
              time: 'morning',
              title: 'Kolukkumalai Jeep Safari & Sunrise Hike',
              category: 'activity',
              estimatedCost: 950.0,
              notes: 'Early 4:30 AM departure in an off-road 4x4 jeep to reach the world\'s highest organic tea garden before sunrise.',
            ),
            ItineraryActivity(
              time: 'afternoon',
              title: 'Anayirangal Dam Boating & Tea Tasting',
              category: 'sightseeing',
              estimatedCost: 400.0,
              notes: 'Relaxing speed-boat ride across the reservoir, followed by a professional tea tasting flight session.',
            ),
            ItineraryActivity(
              time: 'evening',
              title: 'Attukad Waterfalls Pine Forest Hike',
              category: 'activity',
              estimatedCost: 150.0,
              notes: 'Guided short trek through the pine trees to a spectacular overlook of the cascading mountain stream.',
            ),
          ],
        ),
        ItineraryDay(
          dayNumber: 3,
          stayName: 'Overnight Sleeper Bus (Checkout)',
          stayCost: 650.0,
          foodSuggestions: [
            'Guru\'s Restaurant (Ginger chicken & Malabar biryani)',
            'Munnar Town Spice Street (Banana chips & local fudge)'
          ],
          activities: [
            ItineraryActivity(
              time: 'morning',
              title: 'Eravikulam National Park Safari',
              category: 'sightseeing',
              estimatedCost: 300.0,
              notes: 'Board the forest department bus to see the endangered Nilgiri Tahr mountain goats roaming high meadows.',
            ),
            ItineraryActivity(
              time: 'afternoon',
              title: 'Cardamom Spice Plantation Tour',
              category: 'activity',
              estimatedCost: 200.0,
              notes: 'Educational farm walk learning about harvesting cardamom, vanilla pods, pepper vines, and cocoa.',
            ),
            ItineraryActivity(
              time: 'evening',
              title: 'Sleeper Bus Departure Prep & Dinner',
              category: 'transport',
              estimatedCost: 120.0,
              notes: 'Pick up bags from resort storage, grab a light dinner in town, and board the overnight bus home.',
            ),
          ],
        ),
      ],
    );
  }
}
