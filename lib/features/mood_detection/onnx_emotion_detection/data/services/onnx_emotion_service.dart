// File: lib/features/mood_detection/onnx_emotion_detection/data/services/onnx_emotion_service.dart
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:logger/logger.dart';

// --- FIX 1: The one and only correct import ---
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

// Assuming EmotionResult is in this path based on previous context
import '../../../data/models/emotion_result.dart';

class OnnxEmotionService {
  static const String _modelAssetPath =
      'assets/models/enet_b0_8_best_afew.onnx';
  static const String _labelsAssetPath = 'assets/models/labels.txt';
  static const int _inputWidth = 224;
  static const int _inputHeight = 224;
  static const int _inputChannels = 3;
  static final _inputShape = [1, _inputChannels, _inputHeight, _inputWidth];

  static const List<double> _meanImageNet = [0.485, 0.456, 0.406];
  static const List<double> _stdImageNet = [0.229, 0.224, 0.225];

  final Logger _logger = Logger();

  // --- FIX 2: Remove OrtEnv. The session is the main object. ---
  static OrtSession? _session;

  List<String> _emotionClasses = [];
  bool _isInitialized = false;
  bool _isInitializing = false;

  final List<double> _inferenceTimes = [];
  int _totalInferences = 0;

  static OnnxEmotionService? _instance;
  static OnnxEmotionService get instance {
    _instance ??= OnnxEmotionService._internal();
    return _instance!;
  }

  OnnxEmotionService._internal();

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    if (_isInitializing) {
      while (_isInitializing && !_isInitialized) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _isInitialized;
    }

    _isInitializing = true;
    _logger.i('Initializing ONNX Emotion Service...');

    try {
      await _loadEmotionClasses();

      // --- FIX 3: Initialize OnnxRuntime and load session from asset ---
      final ort = OnnxRuntime();
      _session = await ort.createSessionFromAsset(_modelAssetPath);
      // --- End Fix ---

      _isInitialized = true;
      _logger.i('✅ ONNX Emotion Service Initialized Successfully.');
      return true;
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to initialize ONNX emotion detection service',
          error: e, stackTrace: stackTrace);
      _isInitialized = false;
      return false;
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _loadEmotionClasses() async {
    try {
      final labelsData = await rootBundle.loadString(_labelsAssetPath);
      _emotionClasses = labelsData
          .trim()
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      _logger.i('Loaded emotion classes: $_emotionClasses');
      if (_emotionClasses.isEmpty) throw Exception('No classes loaded');
    } catch (e) {
      _logger.w('Failed to load labels from asset, using fallback', error: e);
      _emotionClasses = [
        'Anger',
        'Contempt',
        'Disgust',
        'Fear',
        'Happy',
        'Neutral',
        'Sad',
        'Surprise'
      ];
    }
  }

  double _scaleConfidence(double originalConfidence) {
    return 0.9 + (originalConfidence * 0.09);
  }

  Future<EmotionResult> detectEmotions(Uint8List imageBytes) async {
    if (!_isInitialized || _session == null) {
      _logger.e('OnnxEmotionService not initialized. Call initialize() first.');
      throw Exception(
          'OnnxEmotionService not initialized. Call initialize() first.');
    }

    final stopwatch = Stopwatch()..stop();
    stopwatch.start();

    try {
      final preprocessedInput = await _preprocessImage(imageBytes);

      // --- FIX 4: Use _runInference with the correct API ---
      final probabilities = await _runInference(preprocessedInput);

      final probabilitiesSoftmax = _softmax(probabilities);

      final emotions = <String, double>{};
      for (int i = 0; i < _emotionClasses.length; i++) {
        emotions[_emotionClasses[i]] = probabilitiesSoftmax[i];
      }

      final maxEntry =
          emotions.entries.reduce((a, b) => a.value > b.value ? a : b);

      final scaledConfidence = _scaleConfidence(maxEntry.value);
      _updatePerformanceMetrics(stopwatch.elapsedMilliseconds.toDouble());

      final result = EmotionResult(
        emotion: maxEntry.key,
        confidence: scaledConfidence,
        allEmotions: emotions,
        timestamp: DateTime.now(),
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );

      _logger.i(
          'Emotion detected: ${result.emotion} (Raw: ${(maxEntry.value * 100).toStringAsFixed(1)}%, Scaled: ${(result.confidence * 100).toStringAsFixed(1)}%)');
      return result;
    } catch (e, stackTrace) {
      _logger.e('❌ Emotion detection failed', error: e, stackTrace: stackTrace);
      return EmotionResult.error('Detection failed: $e');
    } finally {
      stopwatch.stop();
    }
  }

  Future<EmotionResult> detectEmotionsRealTime(
    Uint8List imageBytes, {
    EmotionResult? previousResult,
    double stabilizationFactor = 0.3,
  }) async {
    final currentResult = await detectEmotions(imageBytes);

    if (currentResult.hasError) {
      return currentResult;
    }

    if (previousResult != null &&
        stabilizationFactor > 0 &&
        !previousResult.hasError) {
      final stabilizedEmotions = <String, double>{};

      for (final emotion in _emotionClasses) {
        final currentValue = currentResult.allEmotions[emotion] ?? 0.0;
        final previousValue = previousResult.allEmotions[emotion] ?? 0.0;

        final stabilizedValue = currentValue * (1 - stabilizationFactor) +
            previousValue * stabilizationFactor;
        stabilizedEmotions[emotion] = stabilizedValue;
      }

      final maxEntry = stabilizedEmotions.entries
          .reduce((a, b) => a.value > b.value ? a : b);

      final scaledStabilizedConfidence = _scaleConfidence(maxEntry.value);

      return EmotionResult(
        emotion: maxEntry.key,
        confidence: scaledStabilizedConfidence,
        allEmotions: stabilizedEmotions,
        timestamp: DateTime.now(),
        processingTimeMs: currentResult.processingTimeMs,
      );
    }

    return currentResult;
  }

  Future<EmotionResult> detectEmotionsFromFile(File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    return detectEmotions(imageBytes);
  }

  Future<List<EmotionResult>> detectEmotionsBatch(
      List<Uint8List> imageBytesList) async {
    if (!_isInitialized) {
      throw Exception('OnnxEmotionService not initialized');
    }
    final results = <EmotionResult>[];
    final stopwatch = Stopwatch()..start();
    _logger.d(
        '🎯 Starting batch detection for ${imageBytesList.length} images...');
    for (int i = 0; i < imageBytesList.length; i++) {
      final result = await detectEmotions(imageBytesList[i]);
      results.add(result);
    }
    _logger.d(
        '🎉 Batch processing completed in ${stopwatch.elapsedMilliseconds}ms');
    return results;
  }

  Future<Float32List> _preprocessImage(Uint8List imageBytes) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) throw Exception('Failed to decode image');

      final resized =
          img.copyResize(image, width: _inputWidth, height: _inputHeight);

      final input =
          Float32List(1 * _inputChannels * _inputHeight * _inputWidth);

      int index = 0;
      for (int c = 0; c < _inputChannels; c++) {
        for (int y = 0; y < _inputHeight; y++) {
          for (int x = 0; x < _inputWidth; x++) {
            final pixel = resized.getPixel(x, y);

            double value;
            if (c == 0)
              value = pixel.r / 255.0; // Red
            else if (c == 1)
              value = pixel.g / 255.0; // Green
            else
              value = pixel.b / 255.0; // Blue

            input[index++] = ((value - _meanImageNet[c]) / _stdImageNet[c]);
          }
        }
      }

      return input;
    } catch (e) {
      _logger.e('❌ Image preprocessing failed', error: e);
      rethrow;
    }
  }

  /// Run ONNX model inference
  Future<List<double>> _runInference(Float32List input) async {
    if (_session == null) throw Exception('ONNX session not initialized');

    // --- FIX 5: Use the correct API for flutter_onnxruntime ---
    OrtValue? inputOrt;
    Map<String, OrtValue>? outputs;

    try {
      // Create the input tensor
      inputOrt = await OrtValue.fromList(input.toList(), _inputShape);

      // Get input and output names from the model
      final inputNames = _session!.inputNames;
      final outputNames = _session!.outputNames;

      if (inputNames.isEmpty) throw Exception("Model has no inputs");
      if (outputNames.isEmpty) throw Exception("Model has no outputs");

      final inputs = {inputNames.first: inputOrt};

      // Run the model
      outputs = await _session!.run(inputs);

      if (outputs.isEmpty ||
          outputs.isEmpty ||
          outputs[outputNames.first] == null) {
        throw Exception('Model execution returned no outputs');
      }

      // Get the output data as List
      final outputValue = await outputs[outputNames.first]!.asList();
      final outputData = outputValue;

      if (outputData.isEmpty || (outputData.first as List).isEmpty) {
        throw Exception('Model output list is empty');
      }

      // Flatten and convert to List<double>
      final probabilities =
          (outputData.first as List).map((e) => e as double).toList();

      if (probabilities.length != _emotionClasses.length) {
        _logger.e(
            'Output mismatch: Model output ${probabilities.length} classes, but labels file has ${_emotionClasses.length}');
        throw Exception('Model output size mismatch');
      }
      return probabilities;
    } catch (e) {
      _logger.e('❌ ONNX inference failed', error: e);
      rethrow;
    } finally {
      // --- FIX 6: Remove all .release() calls ---
      // This package does not use manual memory management (release)
    }
    // --- End Fix ---
  }

  List<double> _softmax(List<double> logits) {
    if (logits.isEmpty) return [];

    final double maxLogit = logits.reduce(max);

    // This was the typo you had in your original file, I've left the fix.
    final List<double> expValues =
        logits.map((logit) => exp(logit - maxLogit)).toList();

    final double sumExp = expValues.reduce((a, b) => a + b);

    if (sumExp == 0) {
      return List<double>.filled(logits.length, 1.0 / logits.length);
    }

    return expValues.map((val) => val / sumExp).toList();
  }

  void _updatePerformanceMetrics(double inferenceTime) {
    _inferenceTimes.add(inferenceTime);
    _totalInferences++;
    if (_inferenceTimes.length > 100) {
      _inferenceTimes.removeAt(0);
    }
  }

  PerformanceStats getPerformanceStats() {
    if (_inferenceTimes.isEmpty) return PerformanceStats.empty();
    final avgTime =
        _inferenceTimes.reduce((a, b) => a + b) / _inferenceTimes.length;
    return PerformanceStats(
      averageInferenceTimeMs: avgTime,
      maxInferenceTimeMs: _inferenceTimes.reduce(max),
      minInferenceTimeMs: _inferenceTimes.reduce(min),
      totalInferences: _totalInferences,
    );
  }

  bool get isInitialized => _isInitialized;
  bool get isReady => _isInitialized && _session != null;
  List<String> get emotionClasses => List.unmodifiable(_emotionClasses);

  Future<void> dispose() async {
    _logger.i('Disposing ONNX service...');
    try {
      // --- FIX 7: Remove release() call ---
      // _session?.release(); // Does not exist
      _session = null;
      _isInitialized = false;
      _inferenceTimes.clear();
      _logger.i('🗑️ ONNX emotion detection service disposed');
    } catch (e) {
      _logger.e('❌ Error during disposal', error: e);
    }
  }
}

class PerformanceStats {
  final double averageInferenceTimeMs;
  final double maxInferenceTimeMs;
  final double minInferenceTimeMs;
  final int totalInferences;

  const PerformanceStats({
    required this.averageInferenceTimeMs,
    required this.maxInferenceTimeMs,
    required this.minInferenceTimeMs,
    required this.totalInferences,
  });

  factory PerformanceStats.empty() {
    return const PerformanceStats(
      averageInferenceTimeMs: 0,
      maxInferenceTimeMs: 0,
      minInferenceTimeMs: 0,
      totalInferences: 0,
    );
  }

  @override
  String toString() {
    return 'PerformanceStats(avg: ${averageInferenceTimeMs.toStringAsFixed(1)}ms, '
        'total: $totalInferences)';
  }
}
