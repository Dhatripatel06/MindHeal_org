// lib/core/config/app_config.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // --- KEYS ARE NOW LOADED FROM .env ---

  // We use `static final` instead of `static const` because they are
  // loaded at runtime, not compile-time.
  
  /// Loads the Gemini API Key from the .env file.
  static final String geminiApiKey =
      dotenv.env['GEMINI_API_KEY'] ?? 'MISSING_GEMINI_KEY';

  /// Loads the OpenAI (Whisper) API Key from the .env file.
  static final String openAiApiKey =
      dotenv.env['OPENAI_API_KEY'] ?? 'MISSING_OPENAI_KEY';

  /// Loads the HuggingFace Token from the .env file.
  static final String huggingFaceToken =
      dotenv.env['HF_TOKEN'] ?? 'MISSING_HF_TOKEN';

  // Example of other configs
  static const bool isDebug = kDebugMode;

  /// Helper function to check if keys are loaded
  static void checkKeys() {
    if (geminiApiKey == 'MISSING_GEMINI_KEY') {
      print("WARNING: GEMINI_API_KEY is not loaded from .env file.");
    }
    if (openAiApiKey == 'MISSING_OPENAI_KEY') {
      print("WARNING: OPENAI_API_KEY is not loaded from .env file.");
    }
  }
}