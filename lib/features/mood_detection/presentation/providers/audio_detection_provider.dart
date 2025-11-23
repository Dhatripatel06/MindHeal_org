import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mental_wellness_app/core/services/gemini_adviser_service.dart';
import 'package:mental_wellness_app/core/services/live_speech_transcription_service.dart';
import 'package:mental_wellness_app/core/services/translation_service.dart';
import 'package:mental_wellness_app/core/services/tts_service.dart';
import 'package:mental_wellness_app/features/mood_detection/data/models/emotion_result.dart';
import 'package:mental_wellness_app/features/mood_detection/data/services/wav2vec2_emotion_service.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioDetectionProvider extends ChangeNotifier {
  final Wav2Vec2EmotionService _emotionService =
      Wav2Vec2EmotionService.instance;
  final LiveSpeechTranscriptionService _sttService =
      LiveSpeechTranscriptionService();
  final TranslationService _translationService = TranslationService();
  final GeminiAdviserService _geminiService = GeminiAdviserService();
  final TtsService _ttsService = TtsService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isInitialized = false;
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _hasRecording = false;

  EmotionResult? _lastResult;
  String? _friendlyResponse;
  String? _lastError;
  List<double> _audioData = [];
  Duration _recordingDuration = Duration.zero;

  String _liveTranscribedText = "";
  String? _lastRecordedFilePath;
  String _selectedLanguage = 'English';

  bool get isRecording => _isRecording;
  bool get isProcessing => _isProcessing;
  bool get isInitialized => _isInitialized;
  bool get hasRecording => _hasRecording || _lastRecordedFilePath != null;
  String? get lastError => _lastError;
  String? get error => _lastError;
  EmotionResult? get lastResult => _lastResult;
  String? get friendlyResponse => _friendlyResponse;
  List<double> get audioData => _audioData;
  Duration get recordingDuration => _recordingDuration;
  String get selectedLanguage => _selectedLanguage;
  String get liveTranscribedText => _liveTranscribedText;
  String? get audioFilePath => _lastRecordedFilePath;

  // Get the user speech text for advice (formatted)
  String get userSpeechForAdvice {
    if (_liveTranscribedText.isNotEmpty &&
        !_liveTranscribedText.startsWith("(") &&
        _liveTranscribedText.trim().isNotEmpty) {
      return _liveTranscribedText.trim();
    }
    return "";
  }

  // Language Code mapping
  String get currentLangCode => _selectedLanguage == 'हिंदी'
      ? 'hi'
      : (_selectedLanguage == 'ગુજરાતી' ? 'gu' : 'en');
  String get currentLocaleId => _selectedLanguage == 'हिंदी'
      ? 'hi_IN'
      : (_selectedLanguage == 'ગુજરાતી' ? 'gu_IN' : 'en_US');

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Listeners
    _sttService.addListener(() {
      _liveTranscribedText = _sttService.liveWords;
      if (_mounted) notifyListeners();
    });

    _emotionService.audioDataStream.listen((data) {
      _audioData = data;
      if (_mounted) notifyListeners();
    });

    _emotionService.recordingDurationStream.listen((duration) {
      _recordingDuration = duration;
      if (_mounted) notifyListeners();
    });

    _isInitialized = true;
  }

  void setLanguage(String language) {
    _selectedLanguage = language;
    notifyListeners();
  }

  Future<void> startRecording() async {
    if (_isRecording) return;
    _clearState();
    _isRecording = true;
    _isProcessing = false;

    try {
      await _emotionService.startRecording();
      try {
        await _sttService.startListening(currentLocaleId);
      } catch (e) {
        print("STT Warning: $e");
      }
      notifyListeners();
    } catch (e) {
      _lastError = "Could not start: $e";
      _isRecording = false;
      notifyListeners();
    }
  }

  Future<void> stopRecording() async {
    if (!_isRecording) return;
    _isRecording = false;
    _isProcessing = true;
    notifyListeners();

    try {
      // 1. Stop Audio
      File? audioFile = await _emotionService.stopRecording();
      await _sttService.stopListening();

      if (audioFile != null) {
        _hasRecording = true;
        _lastRecordedFilePath = audioFile.path;

        // 2. Get Text
        String userText = _sttService.finalText;
        if (userText.isEmpty) userText = _liveTranscribedText;
        if (userText.isEmpty) userText = "(No speech detected)";
        _liveTranscribedText = userText;

        // 3. Run Full Pipeline
        print('🚀 About to start friend pipeline...');
        await _processFriendPipeline(audioFile, userText);
        print('✅ Friend pipeline completed successfully');
      }
    } catch (e) {
      _lastError = "Processing Error: $e";
      print('❌ stopRecording failed: $e');
    } finally {
      _isProcessing = false;
      if (_mounted) notifyListeners();
    }
  }

  // 🔥 THE REALITY LOGIC 🔥
  Future<void> _processFriendPipeline(
      File audioFile, String originalText) async {
    try {
      print('🔄 Starting emotion detection pipeline...');
      print('📁 Audio file: ${audioFile.path}');
      print('📝 Original text: "$originalText"');

      // A. Detect Tone (Emotion) from Audio
      print('🎯 Calling emotion analysis...');
<<<<<<< HEAD
      String detectedEmotion = 'neutral';
      try {
        _lastResult = await _emotionService.analyzeAudio(audioFile);
        detectedEmotion = _lastResult?.emotion ?? 'neutral';

        print(
            '😊 Emotion detected: $detectedEmotion (confidence: ${_lastResult?.confidence})');
        if (_lastResult?.hasError == true) {
          print('❌ Emotion analysis error: ${_lastResult?.error}');
        }
      } catch (e) {
        print('❌ Emotion service failed: $e');
        _lastError = 'Audio analysis failed: $e';
        _lastResult = null;
        return;
=======
      _lastResult = await _emotionService.analyzeAudio(audioFile);
      String detectedEmotion = _lastResult?.emotion ?? 'neutral';

      print(
          '😊 Emotion detected: $detectedEmotion (confidence: ${_lastResult?.confidence})');
      if (_lastResult?.hasError == true) {
        print('❌ Emotion analysis error: ${_lastResult?.error}');
>>>>>>> fa1579f25fa1e75e62cc0d2cf1bea0415b0ae7a5
      }

      // B. Translate Input to English (if needed)
      String englishText = originalText;
      if (currentLangCode != 'en') {
        englishText = await _translationService.translate(originalText,
            from: currentLangCode, to: 'en');
      }

      // C. Consult Gemini (The Friend)
      // It sees: "I am tired" (Text) + "SAD" (Tone)
      String englishAdvice = await _geminiService.getConversationalAdvice(
        userSpeech: englishText,
        detectedEmotion: detectedEmotion,
        language: 'English', // Get English response first for stability
      );

      // D. Translate Response back to User Language
      String finalResponse = englishAdvice;
      if (currentLangCode != 'en') {
        finalResponse = await _translationService.translate(englishAdvice,
            from: 'en', to: currentLangCode);
      }

      _friendlyResponse = finalResponse;

      // Note: TTS removed from automatic pipeline - user can access via Advice dialog
    } catch (e) {
      print("Pipeline Failed: $e");
      _lastError = "Could not analyze: $e";
    }
  }

  // Helper for file uploads
  Future<void> analyzeAudioFile(File audioFile) async {
    _clearState();
<<<<<<< HEAD

    print('🚀 Starting analyzeAudioFile with: ${audioFile.path}');
    print('📊 File exists: ${await audioFile.exists()}');

    // Basic check - ensure file exists
    if (!await audioFile.exists()) {
      _lastError = 'Selected file no longer exists.';
      if (_mounted) notifyListeners();
      return;
    }

=======
>>>>>>> fa1579f25fa1e75e62cc0d2cf1bea0415b0ae7a5
    _isProcessing = true;
    _hasRecording = true;
    _lastRecordedFilePath = audioFile.path;
    _liveTranscribedText = "(Uploaded File)";
    notifyListeners();

<<<<<<< HEAD
    try {
      await _processFriendPipeline(audioFile, "I uploaded an audio file.");
      print('✅ Pipeline completed successfully');
    } catch (e) {
      print('❌ Pipeline failed: $e');
      _lastError = 'Processing failed: $e';
    }
=======
    await _processFriendPipeline(audioFile, "I uploaded an audio file.");
>>>>>>> fa1579f25fa1e75e62cc0d2cf1bea0415b0ae7a5
    _isProcessing = false;
    notifyListeners();
  }

  void _clearState() {
    _lastResult = null;
    _friendlyResponse = null;
    _lastError = null;
    _audioData = [];
    _recordingDuration = Duration.zero;
    _liveTranscribedText = "";
  }

  void clearResults() => _clearState();
<<<<<<< HEAD

=======
  
>>>>>>> fa1579f25fa1e75e62cc0d2cf1bea0415b0ae7a5
  void clearRecording() {
    _clearState();
    _hasRecording = false;
    _lastRecordedFilePath = null;
    if (_mounted) notifyListeners();
  }

  /// Speak the provided advice text
  Future<void> speakAdvice([String? adviceText]) async {
    final textToSpeak = adviceText ?? _friendlyResponse;
    if (textToSpeak == null || textToSpeak.isEmpty) {
      print('No advice text to speak');
      return;
    }

    try {
      print('🔊 Speaking advice: "$textToSpeak"');
      await _ttsService.speak(textToSpeak, currentLocaleId);
    } catch (e) {
      print('⚠️ TTS failed: $e');
      _lastError = "Speech failed: $e";
      if (_mounted) notifyListeners();
    }
  }

  /// Play the last recorded audio file
  Future<void> playLastRecording() async {
    if (_lastRecordedFilePath == null) {
      _lastError = 'No recording available to play';
      notifyListeners();
      return;
    }

    try {
      print('Playing recording: $_lastRecordedFilePath');
<<<<<<< HEAD

      // Use audio player to play the recorded file
      await _audioPlayer.play(UrlSource('file://$_lastRecordedFilePath'));

=======
      
      // Use audio player to play the recorded file
      await _audioPlayer.play(DeviceFileSource(_lastRecordedFilePath!));
      
>>>>>>> fa1579f25fa1e75e62cc0d2cf1bea0415b0ae7a5
      // Show success feedback
      _lastError = null;
      if (_mounted) notifyListeners();
    } catch (e) {
      print('Failed to play recording: $e');
      _lastError = 'Failed to play recording: $e';
      if (_mounted) notifyListeners();
    }
  }

  /// Get fresh advice from Gemini for the current emotion
  Future<String> getFreshAdvice([String? customText]) async {
    if (_lastResult == null) {
      throw Exception('No emotion result available');
    }

    final textToAnalyze = customText ??
        (liveTranscribedText.isNotEmpty
            ? liveTranscribedText
            : "I shared an audio recording");

    try {
      final advice = await _geminiService.getConversationalAdvice(
        userSpeech: textToAnalyze,
        detectedEmotion: _lastResult!.emotion,
        language: _selectedLanguage,
      );

      // Update the friendly response with fresh advice
      _friendlyResponse = advice;
      if (_mounted) notifyListeners();

      return advice;
    } catch (e) {
      print('Failed to get fresh advice: $e');
      throw Exception('Failed to get advice: $e');
    }
  }

  bool _mounted = true;
<<<<<<< HEAD

=======
  
>>>>>>> fa1579f25fa1e75e62cc0d2cf1bea0415b0ae7a5
  @override
  void dispose() {
    _mounted = false;
    _audioPlayer.dispose();
    super.dispose();
  }
}
