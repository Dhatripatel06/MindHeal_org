// lib/features/mood_detection/presentation/providers/combined_detection_provider.dart
import 'dart:ui' show Rect;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mental_wellness_app/core/services/gemini_adviser_service.dart';
import '../../data/models/emotion_result.dart';
import 'image_detection_provider.dart';
import 'audio_detection_provider.dart';

class CombinedDetectionProvider extends ChangeNotifier {
  final ImageDetectionProvider _imageProvider;
  final AudioDetectionProvider _audioProvider;
  final GeminiAdviserService _geminiService;

  bool _isAnalyzing = false;
  bool _isVisualEnabled = true;
  bool _isAudioEnabled = true;
  bool _isFusionEnabled = true;
  EmotionResult? _fusedResult;
  double _imageConfidence = 0.0;
  double _audioConfidence = 0.0;

  // Getters
  bool get isAnalyzing => _isAnalyzing;
  bool get isRecording => _audioProvider.isRecording;
  bool get isVisualEnabled => _isVisualEnabled;
  bool get isAudioEnabled => _isAudioEnabled;
  bool get isFusionEnabled => _isFusionEnabled;
  EmotionResult? get fusedResult => _fusedResult;
  EmotionResult? get lastImageResult => _imageProvider.currentResult;
  EmotionResult? get lastAudioResult => _audioProvider.lastResult;
  double get imageConfidence => _imageConfidence;
  double get audioConfidence => _audioConfidence;

  // Constructor
  CombinedDetectionProvider({
    required ImageDetectionProvider imageProvider,
    required AudioDetectionProvider audioProvider,
    required GeminiAdviserService geminiService,
  })  : _imageProvider = imageProvider,
        _audioProvider = audioProvider,
        _geminiService = geminiService;

  // ✅ FIXED: Face detection not in this provider, returning empty
  List<Rect> get detectedFaces => [];

  Map<String, double> get imageEmotions =>
      _imageProvider.currentResult?.allEmotions ?? {};
  List<double> get audioData => _audioProvider.audioData;
  Duration get recordingDuration => _audioProvider.recordingDuration;
  bool get hasAudioRecording => _audioProvider.hasRecording;

  Future<void> startCombinedAnalysis() async {
    if (!_isVisualEnabled && !_isAudioEnabled) return;

    _isAnalyzing = true;
    notifyListeners();

    try {
      if (_isAudioEnabled) {
        await _audioProvider.startRecording();
      }
      _startAnalysisLoop();
    } catch (e) {
      debugPrint('Error starting combined analysis: $e');
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  Future<void> stopAnalysis() async {
    _isAnalyzing = false;

    try {
      if (_audioProvider.isRecording) {
        // --- *** FIX: stopRecording() now triggers analysis internally *** ---
        // The analysis pipeline will run inside _audioProvider.stopRecording()
        await _audioProvider.stopRecording();
        // The line `await _audioProvider.analyzeLastRecording();` is no longer needed.
        // --- *** END FIX *** ---
      }

      if (_isFusionEnabled &&
          _imageProvider.currentResult != null &&
          _audioProvider.lastResult != null) {
        // lastResult will be set by stopRecording()
        _performFusion();
      }
    } catch (e) {
      debugPrint('Error stopping analysis: $e');
    } finally {
      notifyListeners();
    }
  }

  void _startAnalysisLoop() {
    // This loop logic might need adjustment based on when results are actually ready
    Future.delayed(const Duration(seconds: 2), () {
      if (_isAnalyzing) {
        _performPeriodicAnalysis();
        _startAnalysisLoop();
      }
    });
  }

  Future<void> _performPeriodicAnalysis() async {
    // This function is likely for live-streaming, but we'll adapt it
    if (_isVisualEnabled && _imageProvider.currentResult != null) {
      _imageConfidence = _imageProvider.currentResult!.confidence;
    }

    if (_isAudioEnabled && _audioProvider.lastResult != null) {
      _audioConfidence = _audioProvider.lastResult!.confidence;
    }

    if (_isFusionEnabled && _imageConfidence > 0 && _audioConfidence > 0) {
      _performFusion();
    }

    notifyListeners();
  }

  void _performFusion() {
    final imageResult = _imageProvider.currentResult;
    final audioResult = _audioProvider.lastResult;

    if (imageResult == null || audioResult == null) return;

    final fusedEmotions = <String, double>{};
    final allEmotions = <String>{};
    allEmotions
        .addAll(imageResult.allEmotions.keys.map((k) => k.toLowerCase()));
    allEmotions
        .addAll(audioResult.allEmotions.keys.map((k) => k.toLowerCase()));

    for (final emotion in allEmotions) {
      // Handle potential case mismatches (e.g., 'Happy' vs 'happy')
      final imageValue = imageResult.allEmotions[emotion] ??
          imageResult.allEmotions[emotion.capitalize()];
      final audioValue = audioResult.allEmotions[emotion] ??
          audioResult.allEmotions[emotion.capitalize()];

      final imageConfidence = imageValue ?? 0.0;
      final audioConfidence = audioValue ?? 0.0;

      // Simple weighted average
      final fusedConfidence = (imageConfidence * 0.6) + (audioConfidence * 0.4);
      fusedEmotions[emotion] = fusedConfidence;
    }

    final dominantEmotion =
        fusedEmotions.entries.reduce((a, b) => a.value > b.value ? a : b);

    _fusedResult = EmotionResult(
      emotion: dominantEmotion.key,
      confidence: dominantEmotion.value,
      allEmotions: fusedEmotions,
      timestamp: DateTime.now(),
      processingTimeMs: 0, // Combined analysis
    );

    notifyListeners();
  }

  void toggleVisual(bool enabled) {
    _isVisualEnabled = enabled;
    notifyListeners();
  }

  void toggleAudio(bool enabled) {
    _isAudioEnabled = enabled;
    notifyListeners();
  }

  void toggleFusion(bool enabled) {
    _isFusionEnabled = enabled;
    notifyListeners();
  }

  Future<void> analyzeCameraFrame(File frameFile) async {
    if (_isVisualEnabled) {
      await _imageProvider.processImage(frameFile.path);
      if (_imageProvider.currentResult != null) {
        _imageConfidence = _imageProvider.currentResult!.confidence;
      }
      notifyListeners();
    }
  }

  void clearResults() {
    _fusedResult = null;
    _imageProvider.reset();
    _audioProvider.clearResults();
    notifyListeners();
  }
}

// Helper extension to capitalize strings for key matching
extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) return "";
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}
