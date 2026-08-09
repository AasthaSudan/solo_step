import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  final String? geminiApiKey;

  AppConfig._({required this.geminiApiKey});

  static late final AppConfig instance;

  static Future<void> initialize() async {
    const compileTimeKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    String? key = compileTimeKey.isNotEmpty ? compileTimeKey : null;

    if (key == null) {
      try {
        await dotenv.load(fileName: '.env');
        final envKey = dotenv.env['GEMINI_API_KEY']?.trim();
        if (envKey != null && envKey.isNotEmpty) {
          key = envKey;
        }
      } catch (_) {
        // Ignore missing .env for builds without the file.
      }
    }

    instance = AppConfig._(
      geminiApiKey: key,
    );
  }

  bool get hasGeminiApiKey => geminiApiKey != null && geminiApiKey!.isNotEmpty;

  String? get geminiApiKeyOrNull => geminiApiKey?.isNotEmpty == true ? geminiApiKey : null;

  String get geminiApiKeyOrThrow => requireGeminiApiKey();

  String requireGeminiApiKey() {
    final key = geminiApiKeyOrNull;
    if (key == null) {
      throw const GeminiApiKeyMissingException();
    }
    return key;
  }
}

class GeminiApiKeyMissingException implements Exception {
  const GeminiApiKeyMissingException();

  @override
  String toString() =>
      'GEMINI_API_KEY is missing. Set GEMINI_API_KEY using --dart-define or in a .env file.';
}
