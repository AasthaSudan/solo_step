import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../domain/entities/proposed_swap.dart';
import '../../domain/entities/replan_result.dart';
import '../../domain/repositories/replan_repository.dart';
import '../../../budget/domain/entities/expense.dart';
import '../../../itinerary/domain/entities/itinerary.dart';
import '../../../itinerary/domain/entities/itinerary_day.dart';

class GeminiReplanRepositoryImpl implements ReplanRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  GeminiReplanRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to replan trips.');
    }
    return user.uid;
  }

  @override
  Future<ReplanResult> requestReplan({
    required String tripId,
    required int remainingBudgetInr,
  }) async {
    try {
      final tripDocRef = _firestore.collection('users').doc(_uid).collection('trips').doc(tripId);
      final tripSnapshot = await tripDocRef.get();

      if (!tripSnapshot.exists) {
        throw Exception('Trip not found');
      }

      final tripData = tripSnapshot.data()!;
      final destinationName = tripData['destinationName'] as String;
      final currentItineraryData = tripData['itinerary'] as Map<String, dynamic>? ?? {'days': []};
      
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('GEMINI_API_KEY is missing in .env');
      }

      final prompt = '''
You are an expert travel planner. The user is on a trip to $destinationName.
They have a remaining budget of ₹$remainingBudgetInr for the rest of their trip.
Here is their current planned itinerary for the remaining days:
${jsonEncode(currentItineraryData)}

Please optimize these remaining days to fit within the remaining budget. Suggest cheaper alternatives for food, transport, or activities where possible.
Make sure every single activity has a realistic "category" (e.g. sightseeing, food, transport, stay, activity) and a numerical "estimatedCost".
Return the modified itinerary as structured JSON, reusing the exact same structure for "days".
''';

      final schema = Schema.object(
        properties: {
          'days': Schema.array(
            items: Schema.object(
              properties: {
                'dayNumber': Schema.integer(),
                'activities': Schema.array(
                  items: Schema.object(
                    properties: {
                      'time': Schema.string(),
                      'title': Schema.string(),
                      'category': Schema.string(),
                      'estimatedCost': Schema.number(),
                      'notes': Schema.string(),
                    },
                    requiredProperties: ['time', 'title', 'category', 'estimatedCost', 'notes'],
                  ),
                ),
                'stayName': Schema.string(),
                'stayCost': Schema.number(),
                'foodSuggestions': Schema.array(items: Schema.string()),
              },
              requiredProperties: ['dayNumber', 'activities', 'stayName', 'stayCost', 'foodSuggestions'],
            ),
          ),
        },
        requiredProperties: ['days'],
      );

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: schema,
        ),
      );

      final response = await model.generateContent([Content.text(prompt)]);
      if (response.text == null) {
        throw Exception('Gemini did not return text.');
      }

      final newItineraryData = jsonDecode(response.text!) as Map<String, dynamic>;
      final newItinerary = Itinerary.fromMap(newItineraryData);
      final oldItinerary = Itinerary.fromMap(currentItineraryData);

      // Generate Proposed Swaps by finding cost differences
      List<ProposedSwap> swaps = _generateSwaps(oldItinerary.days, newItinerary.days);

      return ReplanResult(
        swaps: swaps,
        newItinerary: newItinerary,
      );
    } catch (e) {
      debugPrint('Error requesting replan: $e');
      rethrow;
    }
  }

  List<ProposedSwap> _generateSwaps(List<ItineraryDay> oldDays, List<ItineraryDay> newDays) {
    final List<ProposedSwap> swaps = [];
    
    // Flatten activities
    final oldActivities = oldDays.expand((d) => d.activities).toList();
    final newActivities = newDays.expand((d) => d.activities).toList();

    // Match them up sequentially for the sake of the UI diff
    final int minLength = oldActivities.length < newActivities.length ? oldActivities.length : newActivities.length;

    for (int i = 0; i < minLength; i++) {
      final oldAct = oldActivities[i];
      final newAct = newActivities[i];

      if (oldAct.estimatedCost > newAct.estimatedCost) {
        SpendCategory category = SpendCategory.values.firstWhere(
          (c) => c.name.toLowerCase() == newAct.category.toLowerCase(),
          orElse: () => SpendCategory.other,
        );

        swaps.add(ProposedSwap(
          oldTitle: oldAct.title,
          oldCost: oldAct.estimatedCost.toInt(),
          newTitle: newAct.title,
          newCost: newAct.estimatedCost.toInt(),
          category: category,
        ));
      }
    }

    return swaps;
  }

  @override
  Future<void> acceptReplan({
    required String tripId,
    required Itinerary newItinerary,
  }) async {
    try {
      final tripDocRef = _firestore.collection('users').doc(_uid).collection('trips').doc(tripId);
      
      await tripDocRef.update({
        'itinerary': newItinerary.toMap(),
      });
    } catch (e) {
      debugPrint('Error accepting replan: $e');
      rethrow;
    }
  }
}
