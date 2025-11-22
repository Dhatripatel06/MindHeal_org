import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mental_wellness_app/core/services/gemini_adviser_service.dart';
import 'package:mental_wellness_app/core/services/live_speech_transcription_service.dart';
import 'package:mental_wellness_app/core/services/translation_service.dart';
import 'package:mental_wellness_app/core/services/tts_service.dart';
import 'package:mental_wellness_app/features/mood_detection/data/models/audio_emotion_result.dart';
import 'package:mental_wellness_app/features/mood_detection/data/services/wav2vec2_emotion_service.dart';

/// Enhanced Audio Detection Provider with complete pipeline
/// Handles recording, emotion detection, transcription, translation, and AI advice
class AudioDetectionProvider extends ChangeNotifier {
  // Services
  final Wav2Vec2EmotionService _emotionService =
      Wav2Vec2EmotionService.instance;
  final LiveSpeechTranscriptionService _sttService =
      LiveSpeechTranscriptionService();
  final TranslationService _translationService = TranslationService();
  final GeminiAdviserService _geminiService = GeminiAdviserService();
  final TtsService _ttsService = TtsService();

  // State variables
  bool _isInitialized = false;
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _hasRecording = false;

  // Results and data
  AudioEmotionResult? _lastResult;
  String? _friendlyResponse;
  String? _lastError;
  List<double> _audioData = [];
  Duration _recordingDuration = Duration.zero;

  // Transcription and language
  String _liveTranscribedText = "";
  String? _lastRecordedFilePath;
  String _selectedLanguage = 'English';

  // TTS state tracking
  bool _isSpeaking = false;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isRecording => _isRecording;
  bool get isProcessing => _isProcessing;
  bool get hasRecording => _hasRecording;
  bool get isSpeaking => _isSpeaking;
  AudioEmotionResult? get lastResult => _lastResult;
  String? get friendlyResponse => _friendlyResponse;
  String? get lastError => _lastError;
  List<double> get audioData => _audioData;
  Duration get recordingDuration => _recordingDuration;
  String get selectedLanguage => _selectedLanguage;
  String get liveTranscribedText => _liveTranscribedText;
  String? get audioFilePath => _lastRecordedFilePath;

  // Language mappings
  String get currentLangCode => _getLangCode(_selectedLanguage);
  String get currentLocaleId => _getLocaleId(_selectedLanguage);

  /// Initialize the audio detection system
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🚀 Initializing Audio Detection Provider...');

      // Initialize emotion detection service
      await _emotionService.initialize();

      // Setup STT listener
      _sttService.addListener(() {
        _liveTranscribedText = _sttService.liveWords;
        if (_mounted) notifyListeners();
      });

      // Setup audio data stream listener
      _emotionService.audioDataStream.listen((data) {
        _audioData = data;
        if (_mounted) notifyListeners();
      });

      // Setup recording duration listener
      _emotionService.recordingDurationStream.listen((duration) {
        _recordingDuration = duration;
        if (_mounted) notifyListeners();
      });

      // Setup TTS state listener
      _ttsService.onStateChanged = (state) {
        _isSpeaking = (state == TtsState.playing);
        if (_mounted) notifyListeners();
      };

      _isInitialized = true;
      print('✅ Audio Detection Provider initialized successfully');
    } catch (e) {
      _lastError = "Initialization failed: $e";
      print('❌ Audio Detection Provider initialization failed: $e');
      rethrow;
    }
  }

  /// Set the selected language
  void setLanguage(String language) {
    if (_isRecording || _isProcessing) return;

    _selectedLanguage = language;
    print('🌐 Language changed to: $language');
    notifyListeners();
  }

  /// Start audio recording
  Future<void> startRecording() async {
    if (_isRecording) return;

    try {
      print('🎙️ Starting audio recording...');
      _clearState();
      _isRecording = true;
      _isProcessing = false;

      // Start recording with emotion service
      await _emotionService.startRecording();

      // Start speech recognition
      try {
        await _sttService.startListening(currentLocaleId);
      } catch (e) {
        print("⚠️ STT Warning: $e");
        // Continue even if STT fails
      }

      notifyListeners();
      print('✅ Recording started successfully');
    } catch (e) {
      _lastError = "Could not start recording: $e";
      _isRecording = false;
      print('❌ Failed to start recording: $e');
      notifyListeners();
      rethrow;
    }
  }

  /// Stop recording and process the audio
  Future<void> stopRecording() async {
    if (!_isRecording) return;

    print('🛑 Stopping recording...');
    _isRecording = false;
    _isProcessing = true;
    notifyListeners();

    try {
      // Stop services
      File? audioFile = await _emotionService.stopRecording();
      await _sttService.stopListening();

      if (audioFile != null) {
        _hasRecording = true;
        _lastRecordedFilePath = audioFile.path;

        // Get transcribed text
        String userText = _sttService.finalText;
        if (userText.isEmpty) userText = _liveTranscribedText;
        if (userText.isEmpty) userText = "(No speech detected)";
        _liveTranscribedText = userText;

        print('📝 Transcribed text: "$userText"');

        // Process the complete pipeline
        await _processAudioPipeline(audioFile, userText);
      } else {
        throw Exception("No audio file received from recording service");
      }
    } catch (e) {
      _lastError = "Processing Error: $e";
      print('❌ Processing failed: $e');
    } finally {
      _isProcessing = false;
      if (_mounted) notifyListeners();
    }
  }

  /// Complete audio processing pipeline
  Future<void> _processAudioPipeline(
      File audioFile, String originalText) async {
    final startTime = DateTime.now();

    try {
      print('🔄 Processing audio pipeline...');

      // Step 1: Emotion Detection from Audio
      print('🎯 Detecting emotion from audio...');
      final emotionResult = await _emotionService.analyzeAudio(audioFile);

      if (emotionResult.hasError) {
        throw Exception("Emotion detection failed: ${emotionResult.error}");
      }

      String detectedEmotion = emotionResult.emotion;
      print(
          '😊 Detected emotion: $detectedEmotion (${(emotionResult.confidence * 100).toInt()}%)');

      // Step 2: Translation (if needed)
      String englishText = originalText;
      String? translatedText;

      if (currentLangCode != 'en' && originalText != "(No speech detected)") {
        print('🌐 Translating to English...');
        try {
          englishText = await _translationService.translate(originalText,
              from: currentLangCode, to: 'en');
          translatedText = englishText;
          print('✅ Translation: "$englishText"');
        } catch (e) {
          print('⚠️ Translation failed, using original text: $e');
          englishText = originalText;
        }
      }

      // Step 3: Get AI advice from Gemini
      print('🤖 Getting AI advice...');
      String englishAdvice;
      try {
        englishAdvice = await _geminiService.getConversationalAdvice(
          userSpeech: englishText,
          detectedEmotion: detectedEmotion,
          language: 'English',
        );
        print('💡 Received advice: "$englishAdvice"');
      } catch (e) {
        print('⚠️ Gemini failed, using fallback advice: $e');
        englishAdvice = _getFallbackAdvice(detectedEmotion, originalText);
      }

      // Step 4: Translate advice back (if needed)
      String finalAdvice = englishAdvice;
      if (currentLangCode != 'en') {
        print('🌐 Translating advice back to user language...');
        try {
          finalAdvice = await _translationService.translate(englishAdvice,
              from: 'en', to: currentLangCode);
          print('✅ Translated advice: "$finalAdvice"');
        } catch (e) {
          print('⚠️ Advice translation failed, using English: $e');
          finalAdvice = englishAdvice;
        }
      }

      // Step 5: Create enhanced result
      final processingTime =
          DateTime.now().difference(startTime).inMilliseconds;

      _lastResult = AudioEmotionResult.success(
        emotion: emotionResult.emotion,
        confidence: emotionResult.confidence,
        allEmotions: emotionResult.allEmotions,
        transcribedText: originalText,
        originalLanguage: _selectedLanguage,
        translatedText: translatedText,
        audioFilePath: audioFile.path,
        audioDuration: _recordingDuration,
        processingTimeMs: processingTime,
      );

      _friendlyResponse = finalAdvice;
      _clearError();

      print('✅ Audio pipeline completed successfully');

      // Step 6: Speak the advice
      await speakAdvice(finalAdvice);
    } catch (e) {
      print("❌ Pipeline failed: $e");
      _lastError = "Could not analyze: $e";
      _lastResult = AudioEmotionResult.error(
        "Analysis failed: $e",
        language: _selectedLanguage,
        audioPath: audioFile.path,
      );
    }
  }

  /// Analyze uploaded audio file
  Future<void> analyzeAudioFile(File audioFile) async {
    if (_isRecording || _isProcessing) return;

    print('📁 Analyzing uploaded audio file: ${audioFile.path}');
    _clearState();
    _isProcessing = true;
    _hasRecording = true;
    _lastRecordedFilePath = audioFile.path;
    _liveTranscribedText = "(Uploaded File - Speech detection in progress...)";
    notifyListeners();

    try {
      // For uploaded files, we don't have real-time transcription,
      // so we'll use a placeholder and focus on emotion detection
      await _processAudioPipeline(
          audioFile, "I uploaded an audio file for analysis.");
    } catch (e) {
      _lastError = "File analysis failed: $e";
      print('❌ File analysis failed: $e');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Play the last recorded audio
  Future<void> playLastRecording() async {
    if (_lastRecordedFilePath == null ||
        !File(_lastRecordedFilePath!).existsSync()) {
      _lastError = "No recording to play";
      notifyListeners();
      return;
    }

    try {
      print('🔊 Playing last recording...');
      // Implementation depends on your audio player
      // This is a placeholder - you might want to use just_audio or similar
      print(
          '📱 Audio playback not implemented - file at: $_lastRecordedFilePath');
    } catch (e) {
      _lastError = "Playback failed: $e";
      print('❌ Playback failed: $e');
      notifyListeners();
    }
  }

  /// Speak the AI advice
  Future<void> speakAdvice([String? customText]) async {
    final textToSpeak = customText ?? _friendlyResponse;
    if (textToSpeak == null || textToSpeak.isEmpty) return;

    try {
      print('🔊 Speaking advice in $currentLocaleId...');
      await _ttsService.speak(textToSpeak, currentLocaleId);
    } catch (e) {
      print('⚠️ TTS failed: $e');
    }
  }

  /// Stop TTS if currently speaking
  Future<void> stopSpeaking() async {
    if (_isSpeaking) {
      await _ttsService.stop();
    }
  }

  /// Clear all state and results
  void _clearState() {
    _lastResult = null;
    _friendlyResponse = null;
    _clearError();
    _audioData = [];
    _recordingDuration = Duration.zero;
    _liveTranscribedText = "";
  }

  /// Clear error state
  void _clearError() {
    _lastError = null;
  }

  /// Public methods to clear results
  void clearResults() {
    _clearState();
    notifyListeners();
  }

  void clearRecording() {
    _clearState();
    _hasRecording = false;
    _lastRecordedFilePath = null;
    notifyListeners();
  }

  /// Helper methods for language codes
  String _getLangCode(String language) {
    switch (language) {
      case 'हिंदी':
        return 'hi';
      case 'ગુજરાતી':
        return 'gu';
      default:
        return 'en';
    }
  }

  String _getLocaleId(String language) {
    switch (language) {
      case 'हिंदी':
        return 'hi_IN';
      case 'ગુજરાતી':
        return 'gu_IN';
      default:
        return 'en_US';
    }
  }

  /// Fallback advice when Gemini fails
  String _getFallbackAdvice(String emotion, String userText) {
    if (_selectedLanguage == 'हिंदी') {
      switch (emotion.toLowerCase()) {
        case 'happy':
          return "खुशी की यह भावना बहुत अच्छी है! इस खुशी को अपने दोस्तों के साथ साझा करें।";
        case 'sad':
          return "मैं समझ सकता हूँ कि आप उदास हैं। गहरी सांस लें, यह समय भी बीत जाएगा।";
        case 'angry':
          return "गुस्से में गहरी सांस लें और अपने आप को शांत रखने की कोशिश करें।";
        default:
          return "आपकी भावनाएं सामान्य हैं। धैर्य रखें, आप अकेले नहीं हैं।";
      }
    } else if (_selectedLanguage == 'ગુજરાતી') {
      switch (emotion.toLowerCase()) {
        case 'happy':
          return "આ ખુશીની લાગણી ખૂબ સરસ છે! આ આનંદને તમારા મિત્રો સાથે વહેંચો।";
        case 'sad':
          return "હું સમજી શકું છું કે તમે ઉદાસ છો। ઊંડો શ્વાસ લો, આ સમય પણ પસાર થઈ જશે।";
        case 'angry':
          return "ગુસ્સામાં ઊંડો શ્વાસ લો અને તમારી જાતને શાંત રાખવાનો પ્રયાસ કરો।";
        default:
          return "તમારી લાગણીઓ સામાન્ય છે. ધીરજ રાખો, તમે એકલા નથી।";
      }
    } else {
      switch (emotion.toLowerCase()) {
        case 'happy':
          return "What a wonderful feeling! Enjoy this moment and share it with people you care about.";
        case 'sad':
          return "I understand you're feeling down. Take deep breaths - this feeling will pass.";
        case 'angry':
          return "I can sense your frustration. Try taking deep breaths and finding a calm space.";
        case 'fear':
          return "You're stronger than you know. Try the 5-4-3-2-1 grounding technique to center yourself.";
        default:
          return "Your feelings are valid. Remember, you have the strength to navigate through this.";
      }
    }
  }

  // Widget lifecycle management
  bool _mounted = true;

  @override
  void dispose() {
    _mounted = false;
    _ttsService.dispose();
    _emotionService.dispose();
    super.dispose();
  }
}
