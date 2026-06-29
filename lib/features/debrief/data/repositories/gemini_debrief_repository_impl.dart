import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../domain/entities/debrief_card.dart';
import '../../domain/repositories/debrief_repository.dart';
import '../../../budget/domain/entities/budget_summary.dart';
import '../../../budget/domain/entities/expense.dart';
import '../../../itinerary/domain/entities/itinerary.dart';

class GeminiDebriefRepositoryImpl implements DebriefRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  GeminiDebriefRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to generate debriefs.');
    }
    return user.uid;
  }

  @override
  Future<DebriefCard> generateAndSaveDebrief({
    required String tripId,
    required BudgetSummary summary,
    required List<Expense> expenses,
  }) async {
    try {
      final tripDocRef = _firestore.collection('users').doc(_uid).collection('trips').doc(tripId);
      final tripSnapshot = await tripDocRef.get();

      String destinationName = 'Unknown Destination';
      int daysCount = 0;

      if (tripSnapshot.exists) {
        final tripData = tripSnapshot.data()!;
        destinationName = tripData['destinationName'] as String? ?? 'Unknown Destination';
        
        final itineraryData = tripData['itinerary'] as Map<String, dynamic>?;
        if (itineraryData != null) {
          final itinerary = Itinerary.fromMap(itineraryData);
          daysCount = itinerary.days.length;
        }
      } else {
        // Fallback for when the trip doesn't exist during Layer 3 UI testing
        debugPrint('Trip doc $tripId not found. Using fallback data for Debrief.');
        destinationName = 'Mystery Location';
        daysCount = 3;
      }

      // Calculate stats locally
      final savedVsEstimateInr = summary.estimatedToDateInr - summary.spentInr;
      final totalSpentInr = summary.spentInr;
      final topCategory = _calculateTopCategory(expenses);
      
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('GEMINI_API_KEY is missing in .env');
      }

      final prompt = '''
You are a fun, witty travel companion analyzing a user's recently completed trip to $destinationName.
Based on their spending habits, they saved ₹$savedVsEstimateInr compared to their original estimates, and their highest spend category was "$topCategory".

Please generate a personalized "flavor" for their trip wrap-up debrief.
- "personality": A catchy title (e.g. "Budget Adventurer", "Foodie Spender").
- "traits": 3 short, punchy traits describing their style based on the stats.
- "caption": A short, fun, 1-2 sentence caption summarizing their trip's vibe and financial success.

Return the result as structured JSON.
''';

      final schema = Schema.object(
        properties: {
          'personality': Schema.string(),
          'traits': Schema.array(items: Schema.string()),
          'caption': Schema.string(),
        },
        requiredProperties: ['personality', 'traits', 'caption'],
      );

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: schema,
          temperature: 1.2,
        ),
      );

      final response = await model.generateContent([Content.text(prompt)]);
      if (response.text == null) {
        throw Exception('Gemini did not return text.');
      }

      final flavorData = jsonDecode(response.text!) as Map<String, dynamic>;
      
      final debriefCard = DebriefCard(
        personality: flavorData['personality'] as String? ?? 'The Unknown Traveler',
        traits: (flavorData['traits'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        caption: flavorData['caption'] as String? ?? 'A trip for the books.',
        savedVsEstimateInr: savedVsEstimateInr,
        totalSpentInr: totalSpentInr,
        daysCount: daysCount,
        topCategory: topCategory,
      );

      // Save the generated debrief back to the trip document if it exists
      if (tripSnapshot.exists) {
        await tripDocRef.update({
          'debrief': {
            'personality': debriefCard.personality,
            'traits': debriefCard.traits,
            'caption': debriefCard.caption,
            'savedVsEstimateInr': debriefCard.savedVsEstimateInr,
            'totalSpentInr': debriefCard.totalSpentInr,
            'daysCount': debriefCard.daysCount,
            'topCategory': debriefCard.topCategory,
          }
        });
      }

      return debriefCard;
    } catch (e) {
      debugPrint('Error generating and saving debrief: $e');
      rethrow;
    }
  }

  String _calculateTopCategory(List<Expense> expenses) {
    if (expenses.isEmpty) return 'None';

    final categoryTotals = <String, int>{};
    for (final exp in expenses) {
      final cat = exp.category.label;
      categoryTotals[cat] = (categoryTotals[cat] ?? 0) + exp.amountInr;
    }

    String topCat = 'None';
    int maxAmount = -1;

    categoryTotals.forEach((cat, amount) {
      if (amount > maxAmount) {
        maxAmount = amount;
        topCat = cat;
      }
    });

    return topCat;
  }
}
