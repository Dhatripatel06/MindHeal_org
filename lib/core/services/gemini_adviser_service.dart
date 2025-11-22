import 'dart:developer';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiAdviserService {
  // Singleton instance
  static GeminiAdviserService? _instance;

  late final GenerativeModel _model;
  late final String _modelName;
  late final String _apiKey;

  // Private constructor
  GeminiAdviserService._internal(this._apiKey) {
    _modelName = 'gemini-1.5-flash-latest';
    _model = GenerativeModel(
      model: _modelName,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.9,
        maxOutputTokens: 1000,
      ),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
      ],
    );
  }

  // Factory constructor to initialize with dotenv
  factory GeminiAdviserService() {
    if (_instance == null) {
      // Load key from .env
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        log('⚠️ Warning: GEMINI_API_KEY not found in .env');
      }
      _instance = GeminiAdviserService._internal(apiKey);
    }
    return _instance!;
  }

  // --- ✅ ADDED: Missing Getter for Debugging ---
  String get apiKeyPreview {
    if (_apiKey.isEmpty) return 'NOT_CONFIGURED';
    if (_apiKey.length <= 8) return '***';
    // Show first 4 and last 4 characters for verification
    return '${_apiKey.substring(0, 4)}...${_apiKey.substring(_apiKey.length - 4)}';
  }

  /// Check if the service is properly configured
  bool get isConfigured =>
      _apiKey.isNotEmpty &&
      _apiKey != 'MISSING_GEMINI_KEY' &&
      _apiKey != 'YOUR_API_KEY_HERE';

  // --- Conversational Advice (Voice) ---
  Future<String> getConversationalAdvice({
    required String userSpeech,
    required String detectedEmotion,
    String? userName,
    String language = 'English',
  }) async {
    try {
      log('🤖 Getting conversational advice for: "$userSpeech" (Emotion: $detectedEmotion) in $language');

      final prompt = _buildConversationalPrompt(
        userSpeech: userSpeech,
        emotion: detectedEmotion,
        language: language,
        userName: userName,
      );

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!;
      } else {
        throw Exception('Empty response from Gemini API');
      }
    } catch (e) {
      log('❌ Error getting conversational advice: $e');
      return _getFallbackAdvice(detectedEmotion, language);
    }
  }

  String _buildConversationalPrompt({
    required String userSpeech,
    required String emotion,
    String language = 'English',
    String? userName,
  }) {
    final languageInstruction = _getLanguageInstruction(language);
    final userNameInfo = userName != null ? " The user's name is $userName." : "";

    return '''
    You are MindHeal AI, a compassionate, warm, and wise virtual best friend and counselor.
    A user is talking to you. You have analyzed WHAT they said and HOW they said it (their emotional tone).$userNameInfo

    **CRITICAL LANGUAGE REQUIREMENT:**
    $languageInstruction

    **Analysis of User's Input:**
    - **What they said (Text):** "$userSpeech"
    - **How they said it (Emotion):** ${emotion.toUpperCase()}

    **Your Role & Guidelines:**
    1. Act as a supportive friend, NOT a robot. Be warm, empathetic, and conversational. Use "you".
    2. Acknowledge BOTH text and emotion.
    3. If Text and Emotion conflict, gently explore it.
    4. If Text and Emotion match, validate their feelings.
    5. Handle distressing text with extreme care (validate pain, offer hope).
    6. Handle positive text/emotion with encouragement.
    7. Keep responses to 2-4 supportive sentences.
    
    Please provide your compassionate, friendly response now:
    ''';
  }

  // --- Emotional Advice (Image/General) ---
  Future<String> getEmotionalAdvice({
    required String detectedEmotion,
    required double confidence,
    String? additionalContext,
    String language = 'English',
  }) async {
    if (!isConfigured) {
      log('❌ Service not configured. Returning fallback.');
      return _getFallbackAdvice(detectedEmotion, language);
    }

    try {
      final prompt = _buildAdvicePrompt(
        emotion: detectedEmotion,
        confidence: confidence,
        context: additionalContext,
        language: language,
      );

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!;
      } else {
        throw Exception('Empty response from Gemini API');
      }
    } catch (e) {
      log('❌ Error getting emotional advice: $e');
      return _getFallbackAdvice(detectedEmotion, language);
    }
  }

  String _buildAdvicePrompt({
    required String emotion,
    required double confidence,
    String? context,
    String language = 'English',
  }) {
    final confidenceLevel = _getConfidenceDescription(confidence);
    final languageInstruction = _getLanguageInstruction(language);

    return '''
You are MindHeal AI, a compassionate and professional mental wellness counselor. 

**CRITICAL LANGUAGE REQUIREMENT:**
$languageInstruction

**Analysis Results:**
- Detected Emotion: ${emotion.toUpperCase()}
- Confidence Level: ${(confidence * 100).toInt()}% ($confidenceLevel)
${context != null ? '- Additional Context: $context' : ''}

**Response Guidelines:**
1. Start with validation and understanding.
2. Provide 2-3 specific, actionable suggestions.
3. Include gentle encouragement.
4. Keep tone conversational yet professional.
5. Limit to 3-4 sentences.

**Focus:**
${_getEmotionSpecificGuidance(emotion)}

Please provide your compassionate advice now:
''';
  }

  // --- Helpers ---

  String _getEmotionSpecificGuidance(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy': return 'Help them savor this positive state.';
      case 'sad': return 'Offer comfort and healthy coping mechanisms.';
      case 'angry': return 'Suggest breathing techniques and safe processing.';
      case 'fear': return 'Provide reassurance and grounding techniques.';
      case 'surprise': return 'Help process unexpected events.';
      case 'disgust': return 'Suggest healthy boundaries.';
      case 'neutral': return 'Encourage self-reflection.';
      default: return 'Provide general emotional support.';
    }
  }

  String _getConfidenceDescription(double confidence) {
    if (confidence >= 0.9) return 'Very High Accuracy';
    if (confidence >= 0.8) return 'High Accuracy';
    if (confidence >= 0.7) return 'Good Accuracy';
    return 'Lower Accuracy';
  }

  String _getLanguageInstruction(String language) {
    switch (language) {
      case 'हिंदी':
        return 'Respond ONLY in Hindi (हिंदी) using Devanagari script. No English words.';
      case 'ગુજરાતી':
        return 'Respond ONLY in Gujarati (ગુજરાતી) using Gujarati script. No English words.';
      default:
        return 'Respond in clear, compassionate English.';
    }
  }

  String _getFallbackAdvice(String emotion, [String language = 'English']) {
    if (language == 'हिंदी') return _getHindiFallbackAdvice(emotion);
    if (language == 'ગુજરાતી') return _getGujaratiFallbackAdvice(emotion);

    switch (emotion.toLowerCase()) {
      case 'happy': return "What a wonderful moment! Savor this joy and maybe share it with someone you care about.";
      case 'sad': return "I see you're having a tough time. It's okay to feel sad. Take deep breaths; this feeling will pass.";
      case 'angry': return "I understand you're frustrated. Take deep breaths, count to ten, or take a walk to cool down.";
      case 'fear': return "You are stronger than you know. Try the 5-4-3-2-1 grounding technique to center yourself.";
      case 'surprise': return "Unexpected things happen! Take a moment to process your feelings and adapt.";
      default: return "Your feelings are valid. Acknowledge them without judgment. You have the strength to navigate this.";
    }
  }

  String _getHindiFallbackAdvice(String emotion) {
    return "मैं समझ सकता हूं कि आप इस समय भावनाओं का अनुभव कर रहे हैं। गहरी सांस लें और याद रखें कि आप अकेले नहीं हैं।";
  }

  String _getGujaratiFallbackAdvice(String emotion) {
    return "હું સમજી શકું છું કે તમે લાગણીઓ અનુભવી રહ્યા છો. ઊંડો શ્વાસ લો અને યાદ રાખો કે તમે એકલા નથી.";
  }

  Future<bool> testApiConnection() async {
    if (!isConfigured) return false;
    try {
      final response = await _model.generateContent([Content.text('Test')]);
      return response.text?.isNotEmpty ?? false;
    } catch (e) {
      return false;
    }
  }
}