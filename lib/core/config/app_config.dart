import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  final String? geminiApiKey;

  AppConfig._({required this.geminiApiKey});

  static late final AppConfig instance;

  static Future<void> initialize() async {
    const compileTimeKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    String? key = compileTimeKey.isNotEmpty ? compileTimeKey : null;

    if (key == null && !kIsWeb) {
      try {
        await dotenv.load(fileName: '.env');
        final envKey = dotenv.env['GEMINI_API_KEY']?.trim();
        if (envKey != null && envKey.isNotEmpty) {
          key = envKey;
        }
      } catch (_) {
        // Ignore missing .env for non-web builds.
      }
    }

    instance = AppConfig._(
      geminiApiKey: key,
    );
  }

  bool get hasGeminiApiKey => geminiApiKey != null && geminiApiKey!.isNotEmpty;

  String get geminiApiKeyOrThrow {
    final key = geminiApiKey;
    if (key == null || key.isEmpty) {
      throw Exception('GEMINI_API_KEY is missing or empty.');
    }
    return key;
  }
}
