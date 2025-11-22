// lib/core/services/live_speech_transcription_service.dart
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class LiveSpeechTranscriptionService extends ChangeNotifier {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  String _lastWords = "";
  String _currentLocaleId = 'en-US';

  bool get isListening => _isListening;
  String get liveWords => _lastWords;
  String get finalText => _lastWords; // The final result after stopping

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      _isInitialized = await _speechToText.initialize(
        onError: (error) => print("STT Error: $error"),
        onStatus: _statusListener,
      );
      print("LiveSpeechTranscriptionService Initialized: $_isInitialized");
    } catch (e) {
      print("Error initializing STT: $e");
      _isInitialized = false;
    }
    notifyListeners();
  }

  Future<void> startListening(String localeId) async {
    if (!_isInitialized || _isListening) return;

    // Check if locale is available
    var locales = await _speechToText.locales();
    var selectedLocale = locales.firstWhere(
      (l) => l.localeId == localeId,
      orElse: () => locales.firstWhere(
        (l) => l.localeId.startsWith(localeId.split('_').first), // e.g., 'en'
        orElse: () => locales.firstWhere((l) => l.localeId == 'en-US'), // Fallback
      ),
    );
    _currentLocaleId = selectedLocale.localeId;
    
    print("Starting to listen in locale: $_currentLocaleId");
    _lastWords = ""; // Clear last result
    notifyListeners();

    try {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        localeId: _currentLocaleId,
        listenFor: const Duration(minutes: 5), // Max recording time
        pauseFor: const Duration(seconds: 10), // Auto-stop after 10s of silence
      );
      _isListening = true;
    } catch (e) {
      print("Error starting STT: $e");
      _isListening = false;
    }
    notifyListeners();
  }

  Future<void> stopListening() async {
    if (!_isListening) return;
    try {
      await _speechToText.stop();
      _isListening = false;
    } catch (e) {
      print("Error stopping STT: $e");
      // It might be already stopped
      _isListening = false;
    }
    notifyListeners();
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    _lastWords = result.recognizedWords;
    notifyListeners();
  }

  void _statusListener(String status) {
    print("STT Status: $status");
    if (status == 'notListening' || status == 'done') {
      _isListening = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _speechToText.stop();
    super.dispose();
  }
}