// File: lib/core/services/gemini_service.dart

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:logger/logger.dart';

class GeminiService {
  //
  // --- ⬇️ UPDATED API KEY ⬇️ ---
  //
  final String _apiKey = "AIzaSyD_oHsKdXDTibGft_f4MOaHjm-r1MUHYeQ";
  //
  // --- ⬆️ UPDATED API KEY ⬆️ ---
  //
  // API supports: Gemini 2.5 Pro, 2.5 Flash, 2.0 Flash, 2.0 Flash-Lite, Gemma 3 models
  //

  GenerativeModel? _model;
  final Logger _logger = Logger();
  // Using full model path for maximum compatibility with Google AI API
  final String _modelName = 'models/gemini-2.5-flash';

  GeminiService() {
    if (_apiKey.startsWith("<")) {
      _logger.e(
          "API Key not set in gemini_service.dart. Replace AIzaSyDK6KZrkqJRlFoCw4RU06pUNTm-vl69GzQ");
    } else {
      try {
        _model = GenerativeModel(
          model: _modelName, // Use the stored name
          apiKey: _apiKey,
        );
        _logger.i("GeminiService initialized with model: $_modelName");
      } catch (e) {
        _logger.e("Failed to initialize Gemini Model", error: e);
      }
    }
  }

  bool get isAvailable => _model != null;

  Future<String?> getAdvice({
    required String mood,
    required String language,
  }) async {
    if (_model == null) {
      if (_apiKey.startsWith("<")) {
        return "Error: API Key not set. Please update gemini_service.dart.";
      }
      _logger.w("Gemini model not initialized, cannot get advice.");
      return "Error: Advice service is currently unavailable (Model init failed).";
    }

    String targetLanguage;
    switch (language.toLowerCase()) {
      case 'hindi':
        targetLanguage = 'Hindi';
        break;
      case 'gujarati':
        targetLanguage = 'Gujarati';
        break;
      default:
        targetLanguage = 'English';
    }

    final prompt = '''
      You are a compassionate mental wellness assistant.
      A person is currently feeling "$mood".
      Provide brief, constructive, and supportive advice (2-3 short sentences) suitable for someone feeling this way.
      Respond ONLY in the $targetLanguage language. Do not include any introductory phrases like "Here is some advice:" or translations. Do not add quotation marks around your response.
      ''';

    _logger.i(
        "Generating advice for mood: $mood in language: $targetLanguage with model: $_modelName");

    try {
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);

      if (response.text != null && response.text!.isNotEmpty) {
        _logger.i("Advice generated successfully.");
        return response.text!.trim().replaceAll(RegExp(r'^"|"$'), '').trim();
      } else {
        _logger.w("Received empty response from Gemini API.");
        if (response.promptFeedback?.blockReason != null) {
          _logger.w(
              "Response blocked. Reason: ${response.promptFeedback?.blockReason}");
          return "Error: Request blocked for safety reasons (${response.promptFeedback?.blockReason}).";
        }
        return "Sorry, I couldn't think of any advice right now.";
      }
    } catch (e) {
      _logger.e("Error generating content with Gemini API", error: e);
      String errorMessage = "Sorry, an error occurred while getting advice.";
      final eString = e.toString().toLowerCase();
      if (eString.contains('api key not valid')) {
        errorMessage = "Error: Invalid API Key. Please check GeminiService.";
      } else if (eString.contains('not found') ||
          eString.contains('not supported')) {
        errorMessage =
            "Error: Configured AI model ($_modelName) unavailable. Check API key project permissions or model name in GeminiService.";
      } else if (eString.contains('quota') || eString.contains('limit')) {
        errorMessage =
            "Error: API quota exceeded. Please check your usage limits.";
      } else if (eString.contains('billing')) {
        errorMessage =
            "Error: Billing issue with the associated Google Cloud project.";
      } else if (eString.contains('permission denied')) {
        errorMessage =
            "Error: Permission denied. Ensure the Generative AI API is enabled in your Google Cloud project.";
      }
      return errorMessage;
    }
  }
}
