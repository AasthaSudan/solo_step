import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  final String? geminiApiKey;

  AppConfig._({required this.geminiApiKey});

  static late final AppConfig instance;

  static Future<void> initialize() async {
    instance = AppConfig._(geminiApiKey: dotenv.env['GEMINI_API_KEY']);
  }

  String get geminiApiKeyOrThrow {
    final key = geminiApiKey;
    if (key == null || key.isEmpty) {
      throw Exception('GEMINI_API_KEY is missing or empty.');
    }
    return key;
  }
}
