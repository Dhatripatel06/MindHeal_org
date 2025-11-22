// File: lib/core/services/tts_service.dart

import 'package:flutter_tts/flutter_tts.dart';
import 'package:logger/logger.dart';

enum TtsState { playing, stopped, paused, continued }

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  final Logger _logger = Logger();
  TtsState _ttsState = TtsState.stopped;
  Function(TtsState)? onStateChanged; // Optional callback for UI updates

  TtsService() {
    _flutterTts.setStartHandler(() {
      _logger.i("TTS Started");
      _updateState(TtsState.playing);
    });

    _flutterTts.setCompletionHandler(() {
      _logger.i("TTS Completed");
      _updateState(TtsState.stopped);
    });

    _flutterTts.setErrorHandler((msg) {
      _logger.e("TTS Error: $msg");
      _updateState(TtsState.stopped);
    });

     _flutterTts.setPauseHandler(() {
      _logger.i("TTS Paused");
      _updateState(TtsState.paused);
    });

    _flutterTts.setContinueHandler(() {
      _logger.i("TTS Continued");
       _updateState(TtsState.playing); // or continued, depending on desired state
    });
  }

  TtsState get ttsState => _ttsState;

  void _updateState(TtsState state) {
    _ttsState = state;
    onStateChanged?.call(state); // Notify listener if set
  }

  Future<void> setLanguage(String languageCode) async {
    // Examples: "en-US", "hi-IN", "gu-IN"
    await _flutterTts.setLanguage(languageCode);
  }

  Future<void> speak(String text, String languageCode) async {
    if (text.isNotEmpty) {
      await setLanguage(languageCode);
      await _flutterTts.setPitch(1.0); // Normal pitch
      await _flutterTts.setSpeechRate(0.5); // Normal rate
      var result = await _flutterTts.speak(text);
      if (result == 1) _updateState(TtsState.playing);
    } else {
      _logger.w("Attempted to speak empty text.");
    }
  }

  Future<void> stop() async {
    var result = await _flutterTts.stop();
    if (result == 1) _updateState(TtsState.stopped);
  }

  Future<void> pause() async {
     var result = await _flutterTts.pause();
     if (result == 1) _updateState(TtsState.paused);
  }

  void dispose() {
    _flutterTts.stop();
  }
}