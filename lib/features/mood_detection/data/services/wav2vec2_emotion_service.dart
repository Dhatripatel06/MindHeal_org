import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart'; // For compute
import 'package:flutter/services.dart';
import 'package:mental_wellness_app/features/mood_detection/data/models/emotion_result.dart';
import 'package:mental_wellness_app/features/mood_detection/data/services/audio_converter_service.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:wav/wav.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

// Top-level function for Isolate (Must be outside class)
List<double> _normalizeAudioTask(List<double> audio) {
  if (audio.isEmpty) return [];
  double sum = 0.0;
  for (var x in audio) sum += x;
  double mean = sum / audio.length;

  double sumSq = 0.0;
  for (var x in audio) {
    double diff = x - mean;
    sumSq += diff * diff;
  }
  double std = sqrt(sumSq / audio.length);
  if (std < 1e-5) std = 1.0;

  return audio.map((x) => (x - mean) / std).toList();
}

class Wav2Vec2EmotionService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioConverterService _converter = AudioConverterService();

  OrtSession? _session;
  List<String>? _labels;
  bool _isInitialized = false;
  bool _isRecording = false;
  Timer? _timer;

  final StreamController<List<double>> _audioDataController =
      StreamController<List<double>>.broadcast();
  final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();

  Stream<List<double>> get audioDataStream => _audioDataController.stream;
  Stream<Duration> get recordingDurationStream => _durationController.stream;

  static final Wav2Vec2EmotionService _instance =
      Wav2Vec2EmotionService._internal();
  factory Wav2Vec2EmotionService() => _instance;
  static Wav2Vec2EmotionService get instance => _instance;
  Wav2Vec2EmotionService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      print("🚀 Initializing Wav2Vec2 Pipeline...");
      final ort = OnnxRuntime();
      _session = await ort
          .createSessionFromAsset('assets/models/wav2vec2_emotion.onnx');

      final labelsData =
          await rootBundle.loadString('assets/models/audio_emotion_labels.txt');
      _labels = labelsData
          .split('\n')
          .where((l) => l.isNotEmpty)
          .map((l) => l.trim().toLowerCase())
          .toList();

      _isInitialized = true;
      print("✅ Wav2Vec2 Ready.");
    } catch (e) {
      print("❌ AI Init Error: $e");
    }
  }

  Future<void> startRecording() async {
    if (_isRecording) return;
    try {
      if (await _recorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final String path =
            '${tempDir.path}/temp_recording_${DateTime.now().millisecondsSinceEpoch}.wav';

        const config = RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        );

        await _recorder.start(config, path: path);
        _isRecording = true;
        _startUpdates();
        print("🎙️ Recording started at 16kHz: $path");
      } else {
        print("⚠️ Microphone permission denied");
      }
    } catch (e) {
      print("❌ Start Recording Error: $e");
      _isRecording = false;
    }
  }

  Future<File?> stopRecording() async {
    _timer?.cancel();
    _isRecording = false;
    try {
      final path = await _recorder.stop();
      if (path != null) {
        return File(path);
      }
      return null;
    } catch (e) {
      print("❌ Stop Recording Error: $e");
      return null;
    }
  }

  void _startUpdates() {
    Duration duration = Duration.zero;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (!_isRecording) {
        timer.cancel();
        return;
      }
      duration += const Duration(milliseconds: 100);
      _durationController.add(duration);

      try {
        final amp = await _recorder.getAmplitude();
        final double normalized =
            pow(10, (amp.current / 20)).toDouble().clamp(0.0, 1.0);
        _audioDataController.add(List.filled(20, normalized));
      } catch (_) {}
    });
  }

  Future<EmotionResult> analyzeAudio(File audioFile) async {
    final startTime = DateTime.now();
    if (!_isInitialized) await initialize();
    if (_session == null) return EmotionResult.error("Model not loaded");

    File? workingFile;
    try {
      // 1. Format Check
      workingFile = await _converter.ensureWavFormat(audioFile);

      // 2. Parse WAV
      final wav = await Wav.readFile(workingFile.path);

      if (wav.channels.isEmpty) return EmotionResult.error("Empty audio file");

      List<double> audioData = wav.channels[0].toList();
      if (audioData.length < 1000)
        return EmotionResult.error("Audio too short");

      // 3. Normalization (Background Thread)
      audioData = await compute(_normalizeAudioTask, audioData);

      // 4. Inference
      final shape = [1, audioData.length];
      final inputTensor = await OrtValue.fromList(audioData, shape);

      final inputName = _session!.inputNames.first;
      final inputs = {inputName: inputTensor};

      final outputs = await _session!.run(inputs);
      if (outputs.isEmpty) throw Exception("No output from AI");

      // 5. Process Outputs
      final outputKey = _session!.outputNames.first;
      final outputOrt = outputs[outputKey];

      final rawOutputList = await outputOrt!.asList();
      final logits =
          (rawOutputList[0] as List).map((e) => (e as num).toDouble()).toList();

      // Softmax
      final expScores = logits.map((s) => exp(s)).toList();
      final sumExp = expScores.reduce((a, b) => a + b);
      final probs = expScores.map((s) => s / sumExp).toList();

      final allEmotions = <String, double>{};
      double maxScore = -1.0;
      int maxIndex = 0;

      for (int i = 0; i < probs.length; i++) {
        if (_labels != null && i < _labels!.length) {
          String label = _labels![i];
          double score = probs[i];
          allEmotions[label] = score;
          if (score > maxScore) {
            maxScore = score;
            maxIndex = i;
          }
        }
      }

      if (workingFile.path != audioFile.path) {
        try {
          await workingFile.delete();
        } catch (e) {
          // Ignore deletion errors during cleanup
          print('Warning: Could not delete temporary file: $e');
        }
      }

      return EmotionResult(
        emotion: _labels![maxIndex],
        confidence: maxScore,
        allEmotions: allEmotions,
        timestamp: DateTime.now(),
        processingTimeMs: DateTime.now().difference(startTime).inMilliseconds,
      );
    } catch (e) {
      print("❌ Analysis Error: $e");
      return EmotionResult.error("Analysis failed: ${e.toString()}");
    }
  }

  void dispose() {
    _timer?.cancel();
    _audioDataController.close();
    _durationController.close();
    _recorder.dispose();
  }
}
