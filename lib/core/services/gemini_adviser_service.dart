import 'dart:developer';
import 'dart:async';
import 'dart:io';
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
            HarmBlockThreshold.low,
          ), // More lenient for mental health discussions
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.low),
          SafetySetting(
            HarmCategory.sexuallyExplicit,
            HarmBlockThreshold.medium,
          ),
          SafetySetting(
            HarmCategory.dangerousContent,
            HarmBlockThreshold.low,
          ), // Allow discussions about mental health struggles
        ],
      );
      log('✅ GeminiAdviserService initialized with model: $_modelName');
    } catch (e) {
      log('❌ Failed to initialize GeminiAdviserService: $e');
      rethrow;
    }
  }

  // Factory constructor to initialize with API key from .env
  factory GeminiAdviserService() {
    if (_instance == null) {
      // Read API key from .env file
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        log('⚠️ Warning: GEMINI_API_KEY not found in .env file');
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
      log(
        '🤖 Getting conversational advice for: "$userSpeech" (Emotion: $detectedEmotion) in $language',
      );

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
        userName != null ? " Your buddy's name is $userName! 😊" : "";

    return '''
You are Luna 🌙, a warm, caring friend and skilled counselor who just listened to the user's voice recording and analyzed both what they said AND how they said it (their vocal tone). You're responding with the warmth of a best friend who truly hears them.$userNameInfo

**CRITICAL LANGUAGE REQUIREMENT:**
$languageInstruction

**What You Heard from Their Voice Recording:**
- What they said (transcribed): "$userSpeech" 🗣️
- How they sounded (emotion detected from voice tone): ${emotion.toUpperCase()} 🎯
- You analyzed their vocal patterns, tone, and speech to understand their emotional state 📡💝

**Your Luna Personality:**
- Talk like their supportive bestie - warm, genuine, relatable 💕
- Use encouraging emojis to make your response more attractive 🌟
- Be optimistic while validating their feelings 🌈
- Use casual, friendly phrases like "buddy", "yaar", "dost" 🤗
- Give them that friend-energy they need! ✨

**Your Response Style:**
1. Acknowledge BOTH what they said (the words) AND how they sounded (the emotion) with genuine warmth 💝
2. Respond to the meaning of their words while validating their vocal emotional tone 🤝
3. Give 2-3 specific, actionable suggestions that address what they shared 💡
4. End with encouragement and remind them you're here for them 🌟
5. ALWAYS use emojis to make it more engaging! 😊
6. Keep it to 3-5 supportive sentences
7. Focus on living in the present moment - "this moment is God's gift" 🎁

**Emotion-Specific Friend Energy:**
${_getEmotionSpecificFriendlyGuidance(emotion)}

Please provide your caring, emoji-filled response as Luna, addressing both their words and their emotional tone:
''';
  }

  // --- Emotional Advice (Image/General) ---
  Future<String> getEmotionalAdvice({
    required String detectedEmotion,
    required double confidence,
    String? additionalContext,
    String language = 'English',
    int retryCount = 0,
  }) async {
    if (!isConfigured) {
      log('❌ Service not configured. Returning fallback.');
      return _getFallbackAdvice(detectedEmotion, language);
    }

    try {
      log(
        '📸 Getting emotional advice for $detectedEmotion${retryCount > 0 ? ' (Attempt ${retryCount + 1})' : ''}',
      );

      final prompt = _buildAdvicePrompt(
        emotion: detectedEmotion,
        confidence: confidence,
        context: additionalContext,
        language: language,
      );

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out after 30 seconds');
        },
      );

      if (response.text != null && response.text!.isNotEmpty) {
        log('✅ Emotional advice generated successfully');
        return response.text!;
      } else {
        throw Exception('Empty response from Gemini API');
      }
    } on TimeoutException catch (e) {
      log('⏱️ Timeout in emotional advice: $e');
      if (retryCount < 2) {
        await Future.delayed(Duration(seconds: retryCount + 1));
        return getEmotionalAdvice(
          detectedEmotion: detectedEmotion,
          confidence: confidence,
          additionalContext: additionalContext,
          language: language,
          retryCount: retryCount + 1,
        );
      }
      return _getFallbackAdvice(detectedEmotion, language);
    } on SocketException catch (e) {
      log('🌐 Network error in emotional advice: $e');
      if (retryCount < 2) {
        await Future.delayed(Duration(seconds: retryCount + 1));
        return getEmotionalAdvice(
          detectedEmotion: detectedEmotion,
          confidence: confidence,
          additionalContext: additionalContext,
          language: language,
          retryCount: retryCount + 1,
        );
      }
      return _getFallbackAdvice(detectedEmotion, language);
    } catch (e) {
      log('❌ Error getting emotional advice: $e');
      if (retryCount < 2) {
        await Future.delayed(Duration(seconds: retryCount + 1));
        return getEmotionalAdvice(
          detectedEmotion: detectedEmotion,
          confidence: confidence,
          additionalContext: additionalContext,
          language: language,
          retryCount: retryCount + 1,
        );
      }
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
    final displayConfidence = _normalizeConfidence(confidence);

    return '''
You are Luna 🌙, a warm, caring friend and skilled counselor who just analyzed the user's facial expression from their photo/selfie and detected their emotional state. You're responding with the care of a best friend who can read their face and wants to help!

**CRITICAL LANGUAGE REQUIREMENT:**
$languageInstruction

**What You Detected from Their Photo/Selfie:**
- Facial emotion detected: ${emotion.toUpperCase()} 😊
- Detection confidence: $displayConfidence% ($confidenceLevel) 🎯
- You analyzed their facial expressions, micro-expressions, and visual cues 📸
${context != null ? '- Additional facial insights: $context 🔍' : ''}

**Your Luna Personality:**
- Talk like their supportive bestie - warm, genuine, relatable 💕
- Use encouraging emojis to make your response attractive and engaging 🌟
- Be optimistic while validating their feelings 🌈  
- Use casual, friendly phrases like "buddy", "yaar", "dost" 🤗
- Give them that uplifting friend-energy they need! ✨

**Response Guidelines:**
1. Acknowledge the emotion you see in their face with genuine warmth 💝
2. Validate what their facial expression tells you in a caring, friend-like way 🤝
3. Provide 2-3 specific, actionable suggestions that feel like bestie advice 💡
4. Include gentle encouragement with friend energy 🌟
5. ALWAYS use emojis to make it more attractive and engaging! 😊
6. Keep tone conversational and supportive, like texting a close friend 📱
7. Limit to 3-4 sentences but make them count! 💪
8. Remind them to live in the present moment - "this moment is God's gift" 🎁

**Focus for ${emotion.toUpperCase()}:**
${_getEmotionSpecificFriendlyGuidance(emotion)}

Please provide your caring, emoji-filled response as Luna, based on what you see in their facial expression:
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

  String _getEmotionSpecificFriendlyGuidance(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return 'Celebrate this amazing feeling with them! 🎉 Encourage them to spread this positive vibe and make the most of this beautiful moment! ☀️';
      case 'sad':
        return 'Give them a virtual hug 🤗 and remind them that it\'s totally okay to feel down sometimes. Help them process these feelings with self-compassion and gentle care 💝';
      case 'angry':
        return 'Help them channel this energy positively! 💪 Suggest some deep breathing, a quick walk, or maybe hitting a pillow - whatever helps them release this safely 🌬️';
      case 'fear':
        return 'Be their calming presence 🕯️ Remind them they\'re braver than they believe and help them ground themselves in the present moment 🌱';
      case 'surprise':
        return 'Help them navigate this unexpected moment! 🌪️ Sometimes surprises are gifts in disguise - help them process and see the possibilities ✨';
      case 'disgust':
        return 'Validate that some things just don\'t feel right, and that\'s their intuition talking! 🧭 Help them set healthy boundaries and honor their feelings 🛡️';
      case 'neutral':
        return 'This is a perfect moment for reflection! 🪞 Help them connect with themselves and maybe discover what they\'re truly feeling underneath 🎯';
      default:
        return 'Be their emotional companion and help them navigate whatever they\'re feeling with love and understanding 💞';
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
      final response = await _model.generateContent([
        Content.text('Test connection - respond with "OK"'),
      ]);
      bool success = response.text?.isNotEmpty ?? false;
      log(
        success
            ? '✅ API connection test successful'
            : '❌ API connection test failed - empty response',
      );
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
    int retryCount = 0,
  }) async {
    if (!isConfigured) {
      log('❌ Service not configured. API Key status: ${apiKeyPreview}');
      return "I understand you want to talk, but I'm having some connectivity issues right now. Can you tell me more about how you're feeling?";
    }

    try {
      log(
        '🤖 Getting chat response for: "$userMessage" using model: $_modelName (Attempt ${retryCount + 1})',
      );

      final prompt = _buildChatPrompt(
        userMessage: userMessage,
        context: wellnessContext,
        language: language,
      );

      log(
        '📝 Generated prompt (first 200 chars): ${prompt.substring(0, prompt.length > 200 ? 200 : prompt.length)}...',
      );
      log('🔧 Model config: temperature=0.8, maxTokens=2048');
      log(
        '🔐 API key status: ${_apiKey.substring(0, 10)}...${_apiKey.substring(_apiKey.length - 4)}',
      );

      final content = [Content.text(prompt)];
      log('📤 Calling generateContent with 30s timeout...');

      // Add timeout to prevent hanging indefinitely
      final response = await _model.generateContent(content).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out after 30 seconds');
        },
      );

      log(
        '📥 Raw response received. Text null? ${response.text == null}, Empty? ${response.text?.isEmpty}',
      );

      if (response.text != null && response.text!.isNotEmpty) {
        log(
          '✅ Chat response generated successfully (length: ${response.text!.length})',
        );
        return response.text!.trim();
      } else {
        log(
          '⚠️ Empty response from model. Prompt feedback: ${response.promptFeedback}',
        );
        if (response.promptFeedback?.blockReason != null) {
          log('🚫 Response blocked: ${response.promptFeedback!.blockReason}');
          return "I want to help, but the content seems to have triggered safety filters. Can you rephrase your question?";
        }
        return "I'm listening to you, but I'm having trouble finding the right words right now. Can you share more about what's on your mind?";
      }
    } on TimeoutException catch (e) {
      log('⏱️ Timeout error: $e');

      // Retry up to 2 times on timeout
      if (retryCount < 2) {
        log('🔄 Retrying request (${retryCount + 1}/2)...');
        await Future.delayed(
          Duration(seconds: retryCount + 1),
        ); // Progressive delay
        return getChatResponse(
          userMessage: userMessage,
          wellnessContext: wellnessContext,
          language: language,
          retryCount: retryCount + 1,
        );
      }

      return "I'm sorry, the connection is taking too long to respond. Please check your internet connection and try again.";
    } on SocketException catch (e) {
      log('🌐 Network error: $e');

      // Retry on network errors
      if (retryCount < 2) {
        log('🔄 Retrying after network error (${retryCount + 1}/2)...');
        await Future.delayed(Duration(seconds: retryCount + 2));
        return getChatResponse(
          userMessage: userMessage,
          wellnessContext: wellnessContext,
          language: language,
          retryCount: retryCount + 1,
        );
      }

      return "I can't connect to the internet right now. Please check your connection and try again.";
    } catch (e, stackTrace) {
      log('❌ Error getting chat response: $e');
      log('📋 Error type: ${e.runtimeType}');
      log(
        '📋 Stack trace: ${stackTrace.toString().split('\n').take(3).join('\n')}',
      );

      // Retry on general errors (except specific known errors)
      String errorMsg = e.toString().toLowerCase();

      if (errorMsg.contains('api key')) {
        return "I'm having trouble with my configuration right now. Please check your API key settings.";
      } else if (errorMsg.contains('quota') || errorMsg.contains('limit')) {
        return "I'm experiencing high demand right now. The API quota may be reached. Please try again later.";
      } else if (errorMsg.contains('not found') || errorMsg.contains('model')) {
        return "I'm having some technical difficulties with my AI model. Please try again in a moment.";
      } else if (retryCount < 2) {
        // Retry for unknown errors
        log('🔄 Retrying after error (${retryCount + 1}/2)...');
        await Future.delayed(Duration(seconds: retryCount + 1));
        return getChatResponse(
          userMessage: userMessage,
          wellnessContext: wellnessContext,
          language: language,
          retryCount: retryCount + 1,
        );
      } else {
        return "I want to help, but I'm experiencing technical difficulties. Please try again in a moment.";
      }
    }
  }

  /// Build chat prompt with wellness context
  String _buildChatPrompt({
    required String userMessage,
    String? context,
    String language = 'English',
  }) {
    final languageInstruction = _getLanguageInstruction(language);
    return '''
You are Luna 🌙, a warm, caring, and enthusiastic friend who also happens to be a skilled counselor. You're like that amazing friend who always knows what to say, speaks in a natural, conversational way, and genuinely cares about people's well-being.

User's Message: "$userMessage"

${context ?? ''}

Your Personality & Style:
- Talk like a close, supportive friend - warm, genuine, and relatable 💝
- Use casual, friendly language but with the wisdom of a counselor 🧠✨
- Be encouraging and optimistic while validating their feelings 🌈
- $languageInstruction 🗣️
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
      log(
        '🔑 Using API key: ${_apiKey.substring(0, 10)}...${_apiKey.substring(_apiKey.length - 4)}',
      );
      log('🤖 Using model: $_modelName');

      // Create the simplest possible model for testing
      final testModel = GenerativeModel(model: _modelName, apiKey: _apiKey);

      final response = await testModel.generateContent([
        Content.text(
          'Respond with just "Hello, I am working!" - nothing more.',
        ),
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
        final testModel = GenerativeModel(model: modelName, apiKey: _apiKey);

        final response = await testModel.generateContent([
          Content.text('Just say "Hello from $modelName"'),
        ]);

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

  // Normalize confidence to 90-99% range for display
  int _normalizeConfidence(double confidence) {
    // Map confidence (0.0-1.0) to 90-99 range
    return 90 + (confidence * 9).toInt();
  }
}
