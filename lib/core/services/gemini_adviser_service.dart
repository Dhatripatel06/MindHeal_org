import 'dart:developer';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiAdviserService {
  // Singleton instance
  static GeminiAdviserService? _instance;

  late final GenerativeModel _model;
  late final String _modelName;
  late final String _apiKey;

  // Private constructor
  GeminiAdviserService._internal(this._apiKey) {
    _modelName =
        'models/gemini-2.5-flash'; // Use full path for 2.5 Flash - fast and capable
    try {
      _model = GenerativeModel(
        model: _modelName,
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.8, // More creative for better conversations
          topK: 40,
          topP: 0.9,
          maxOutputTokens: 2048, // Increased for longer responses
        ),
        safetySettings: [
          SafetySetting(
              HarmCategory.harassment,
              HarmBlockThreshold
                  .low), // More lenient for mental health discussions
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.low),
          SafetySetting(
              HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
          SafetySetting(
              HarmCategory.dangerousContent,
              HarmBlockThreshold
                  .low), // Allow discussions about mental health struggles
        ],
      );
      log('✅ GeminiAdviserService initialized with model: $_modelName');
    } catch (e) {
      log('❌ Failed to initialize GeminiAdviserService: $e');
      rethrow;
    }
  }

  // Factory constructor to initialize with updated API key
  factory GeminiAdviserService() {
    if (_instance == null) {
      // Use the updated API key that supports latest models
      final apiKey = 'AIzaSyD_oHsKdXDTibGft_f4MOaHjm-r1MUHYeQ';
      if (apiKey.isEmpty) {
        log('⚠️ Warning: API key not configured');
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
    final userNameInfo =
        userName != null ? " The user's name is $userName." : "";

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
      case 'happy':
        return 'Help them savor this positive state.';
      case 'sad':
        return 'Offer comfort and healthy coping mechanisms.';
      case 'angry':
        return 'Suggest breathing techniques and safe processing.';
      case 'fear':
        return 'Provide reassurance and grounding techniques.';
      case 'surprise':
        return 'Help process unexpected events.';
      case 'disgust':
        return 'Suggest healthy boundaries.';
      case 'neutral':
        return 'Encourage self-reflection.';
      default:
        return 'Provide general emotional support.';
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
      case 'happy':
        return "What a wonderful moment! Savor this joy and maybe share it with someone you care about.";
      case 'sad':
        return "I see you're having a tough time. It's okay to feel sad. Take deep breaths; this feeling will pass.";
      case 'angry':
        return "I understand you're frustrated. Take deep breaths, count to ten, or take a walk to cool down.";
      case 'fear':
        return "You are stronger than you know. Try the 5-4-3-2-1 grounding technique to center yourself.";
      case 'surprise':
        return "Unexpected things happen! Take a moment to process your feelings and adapt.";
      default:
        return "Your feelings are valid. Acknowledge them without judgment. You have the strength to navigate this.";
    }
  }

  String _getHindiFallbackAdvice(String emotion) {
    return "मैं समझ सकता हूं कि आप इस समय भावनाओं का अनुभव कर रहे हैं। गहरी सांस लें और याद रखें कि आप अकेले नहीं हैं।";
  }

  String _getGujaratiFallbackAdvice(String emotion) {
    return "હું સમજી શકું છું કે તમે લાગણીઓ અનુભવી રહ્યા છો. ઊંડો શ્વાસ લો અને યાદ રાખો કે તમે એકલા નથી.";
  }

  Future<bool> testApiConnection() async {
    if (!isConfigured) {
      log('❌ API not configured - Key status: ${apiKeyPreview}');
      return false;
    }
    try {
      log('🧪 Testing API connection with model: $_modelName');
      final response = await _model.generateContent(
          [Content.text('Test connection - respond with "OK"')]);
      bool success = response.text?.isNotEmpty ?? false;
      log(success
          ? '✅ API connection test successful'
          : '❌ API connection test failed - empty response');
      return success;
    } catch (e) {
      log('❌ API connection test failed: $e');
      return false;
    }
  }

  /// Test chat functionality specifically
  Future<String> testChatFunction() async {
    try {
      return await getChatResponse(
        userMessage: "Hello, this is a test message",
        wellnessContext: "User is testing the chat functionality",
      );
    } catch (e) {
      log('❌ Chat function test failed: $e');
      return "Chat test failed: $e";
    }
  }

  /// Get personalized chat response with user's wellness history
  Future<String> getChatResponse({
    required String userMessage,
    String? wellnessContext,
    String language = 'English',
  }) async {
    if (!isConfigured) {
      log('❌ Service not configured. API Key status: ${apiKeyPreview}');
      return "I understand you want to talk, but I'm having some connectivity issues right now. Can you tell me more about how you're feeling?";
    }

    try {
      log('🤖 Getting chat response for: "$userMessage" using model: $_modelName');

      final prompt = _buildChatPrompt(
        userMessage: userMessage,
        context: wellnessContext,
        language: language,
      );

      log('📝 Generated prompt (first 200 chars): ${prompt.substring(0, prompt.length > 200 ? 200 : prompt.length)}...');
      log('🔧 Model config: temperature=0.8, maxTokens=2048');
      log('🔐 API key status: ${_apiKey.substring(0, 10)}...${_apiKey.substring(_apiKey.length - 4)}');

      final content = [Content.text(prompt)];
      log('📤 Calling generateContent...');
      final response = await _model.generateContent(content);
      log('📥 Raw response received. Text null? ${response.text == null}, Empty? ${response.text?.isEmpty}');

      if (response.text != null && response.text!.isNotEmpty) {
        log('✅ Chat response generated successfully (length: ${response.text!.length})');
        return response.text!.trim();
      } else {
        log('⚠️ Empty response from model. Prompt feedback: ${response.promptFeedback}');
        if (response.promptFeedback?.blockReason != null) {
          log('🚫 Response blocked: ${response.promptFeedback!.blockReason}');
          return "I want to help, but the content seems to have triggered safety filters. Can you rephrase your question?";
        }
        return "I'm listening to you, but I'm having trouble finding the right words right now. Can you share more about what's on your mind?";
      }
    } catch (e, stackTrace) {
      log('❌ Error getting chat response: $e');
      log('📋 Error type: ${e.runtimeType}');
      log('📋 Stack trace: ${stackTrace.toString().split('\n').take(3).join('\n')}');

      // Provide more specific error messages
      String errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('api key')) {
        return "I'm having trouble with my configuration right now. The technical team has been notified. Can you tell me more about how you're feeling in the meantime?";
      } else if (errorMsg.contains('quota') || errorMsg.contains('limit')) {
        return "I'm experiencing high demand right now. Let me try to help you anyway - what's on your mind today?";
      } else if (errorMsg.contains('not found') || errorMsg.contains('model')) {
        return "I'm having some technical difficulties with my AI model. But I'm still here to listen - how can I support you?";
      } else {
        return "I want to help, but I'm experiencing some technical difficulties. Please tell me more about what you're going through.";
      }
    }
  }

  /// Build chat prompt with wellness context
  String _buildChatPrompt({
    required String userMessage,
    String? context,
    String language = 'English',
  }) {
    return '''
You are Luna 🌙, a warm, caring, and enthusiastic friend who also happens to be a skilled counselor. You're like that amazing friend who always knows what to say, speaks in a natural, conversational way, and genuinely cares about people's well-being.

User's Message: "$userMessage"

${context ?? ''}

Your Personality & Style:
- Talk like a close, supportive friend - warm, genuine, and relatable 💝
- Use casual, friendly language but with the wisdom of a counselor 🧠✨
- Be encouraging and optimistic while validating their feelings 🌈
- Respond in English, Hindi, or Gujarati based on what feels natural for the conversation 🗣️
- Write 20-40 lines to give thoughtful, comprehensive support 📝
- Use phrases like "buddy", "yaar", "bhai", "dost" to feel more personal 🤗
- ALWAYS use emojis to make responses more attractive and engaging! 😊💫

Your Approach:
- If someone says "I think I'm good today" → encourage them to BE actually good: "Hey buddy! 🌟 Why just think you're good? BE actually good! 💪 I'm here for you - embrace that happiness, enjoy this beautiful life with a positive perspective! 🌺🎉"
- Always remind them to live in the present moment - "This moment is God's gift 🎁, and God is with you 🙏✨"
- Trust the process, trust nature, trust God 🌿🕊️
- Be their cheerleader while offering practical wisdom 📣💡
- Use conversational fillers like "yaar", "arre", "bas" when appropriate 
- Share the joy of living and being present 🌈☀️

Key Messages to Weave In:
- Live every moment in the present 🕰️✨
- Life is God's gift - embrace it fully! 🎁💖
- Trust the process and trust in divine support 🙏🌟
- Nature and God are always with you 🌳🕊️
- I'm here for you as your friend 🤝💙
- Be actually happy, not just think about happiness 😄🌺
- Positive perspective transforms everything 🌈🔄

Emoji Usage Guidelines:
- Use 2-4 relevant emojis per sentence for engagement 😊✨
- Match emojis to emotions and topics appropriately 🎯
- Use heart emojis for love/support: 💝❤️💙
- Use nature emojis for peace/growth: 🌺🌿🌈☀️
- Use celebration emojis for encouragement: 🎉✨🌟
- Use spiritual emojis for divine connection: 🙏🕊️✨
- Use friendship emojis for support: 🤗🤝💪

Respond as Luna - your caring, enthusiastic friend who wants to see you thrive! 🌟💖
''';
  }

  /// Simple test to verify API connectivity with minimal prompt
  Future<String> testSimpleConnection() async {
    if (!isConfigured) {
      return '❌ API not configured';
    }

    try {
      log('🧪 Testing simple API connection...');
      log('🔑 Using API key: ${_apiKey.substring(0, 10)}...${_apiKey.substring(_apiKey.length - 4)}');
      log('🤖 Using model: $_modelName');

      // Create the simplest possible model for testing
      final testModel = GenerativeModel(
        model: _modelName,
        apiKey: _apiKey,
      );

      final response = await testModel.generateContent([
        Content.text('Respond with just "Hello, I am working!" - nothing more.')
      ]);

      log('📥 Raw test response: ${response.text}');
      log('🔍 Response candidates: ${response.candidates.length}');
      log('🔍 Prompt feedback: ${response.promptFeedback?.blockReason}');

      if (response.text?.isNotEmpty == true) {
        log('✅ Simple test successful: ${response.text}');
        return '✅ API Working: ${response.text}';
      } else {
        log('⚠️ Empty response from API');
        return '⚠️ API returned empty response - Feedback: ${response.promptFeedback}';
      }
    } catch (e, stackTrace) {
      log('❌ Simple test failed: $e');
      log('📋 Error type: ${e.runtimeType}');
      log('📋 Stack: ${stackTrace.toString().split('\n').take(2).join('\n')}');
      return '❌ API Error: ${e.runtimeType} - $e';
    }
  }

  /// Test multiple model variants to find one that works
  Future<String> testModelVariants() async {
    if (!isConfigured) {
      return '❌ API not configured';
    }

    final modelVariants = [
      'models/gemini-2.5-flash',
      'models/gemini-2.5-pro',
      'models/gemini-2.0-flash',
      'models/gemini-flash-latest',
      'models/gemini-pro-latest',
    ];

    String results = '🧪 Testing Model Variants:\n\n';

    for (String modelName in modelVariants) {
      try {
        log('🧪 Testing model: $modelName');
        final testModel = GenerativeModel(
          model: modelName,
          apiKey: _apiKey,
        );

        final response = await testModel.generateContent(
            [Content.text('Just say "Hello from $modelName"')]);

        if (response.text?.isNotEmpty == true) {
          results += '✅ $modelName: ${response.text}\n';
          log('✅ $modelName works: ${response.text}');
        } else {
          results += '⚠️ $modelName: Empty response\n';
          log('⚠️ $modelName returned empty response');
        }
      } catch (e) {
        results += '❌ $modelName: ${e.runtimeType}\n';
        log('❌ $modelName failed: $e');
      }
    }

    return results;
  }
}
