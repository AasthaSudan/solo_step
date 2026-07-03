import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';

void main() async {
  final apiKey = Platform.environment['GEMINI_API_KEY'];
  if (apiKey == null) {
    print('No API Key');
    return;
  }
  final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
  try {
    final session = model.startChat(history: [
      Content('model', [TextPart('Hi')]),
    ]);
    final response = await session.sendMessage(Content.text('Hello'));
    print('SUCCESS: ${response.text}');
  } catch (e) {
    print('ERROR: $e');
  }
}
