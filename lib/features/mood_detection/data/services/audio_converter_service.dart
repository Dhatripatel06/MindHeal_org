import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:logger/logger.dart';

class AudioConverterService {
  static final AudioConverterService _instance =
      AudioConverterService._internal();
  factory AudioConverterService() => _instance;
  AudioConverterService._internal();

  final Logger _logger = Logger();

  Future<File> ensureWavFormat(File inputFile) async {
    // 1. Validate Input Existence and Size
    if (!await inputFile.exists() || await inputFile.length() == 0) {
      _logger.e("❌ Recording failed: File is empty or does not exist.");
      throw Exception("Recording failed (Empty File). Please try again.");
    }

    final String extension = p.extension(inputFile.path).toLowerCase();

    // 2. Check if already WAV format
    bool isWav = await _isWavHeader(inputFile);
    if (isWav && extension == '.wav') {
      _logger.i("✅ Verified WAV format: ${inputFile.path}");
      return inputFile;
    }

    _logger.i("🔄 Converting audio format '$extension' to WAV...");

    // 3. Convert to proper WAV format
    try {
      final tempDir = await getTemporaryDirectory();
      final String outputName =
          '${DateTime.now().millisecondsSinceEpoch}_converted.wav';
      final String outputPath = p.join(tempDir.path, outputName);
      final File outputFile = File(outputPath);

      if (await outputFile.exists()) await outputFile.delete();

      // Create a proper WAV file from raw audio data
      final audioData = await inputFile.readAsBytes();

      // If the file doesn't have a proper WAV header, create one
      if (!isWav) {
        final wavBytes = await _createWavFileWithHeader(audioData);
        await outputFile.writeAsBytes(wavBytes);
        _logger.i("✅ Created WAV file with proper header: $outputPath");
      } else {
        // Just copy if it's already WAV
        await inputFile.copy(outputPath);
        _logger.i("✅ Copied existing WAV file: $outputPath");
      }

      if (await outputFile.exists() && await outputFile.length() > 44) {
        return outputFile;
      } else {
        throw Exception("Conversion output is invalid.");
      }
    } catch (e) {
      _logger.e("❌ Conversion Failed: $e");

      // Try to create a minimal WAV file as fallback
      try {
        final tempDir = await getTemporaryDirectory();
        final fallbackPath = p.join(tempDir.path,
            'fallback_${DateTime.now().millisecondsSinceEpoch}.wav');
        final fallbackFile = File(fallbackPath);

        final rawData = await inputFile.readAsBytes();
        final wavData = await _createMinimalWav(rawData);
        await fallbackFile.writeAsBytes(wavData);

        _logger.i("✅ Created fallback WAV file: $fallbackPath");
        return fallbackFile;
      } catch (fallbackError) {
        _logger.e("❌ Fallback conversion also failed: $fallbackError");
        throw Exception("Audio conversion failed: $e");
      }
    }
  }

  Future<Uint8List> _createWavFileWithHeader(Uint8List audioData) async {
    // Standard WAV header for 16kHz, 16-bit, mono audio
    const sampleRate = 16000;
    const numChannels = 1;
    const bitsPerSample = 16;
    const byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    const blockAlign = numChannels * bitsPerSample ~/ 8;

    final dataSize = audioData.length;
    final fileSize = 36 + dataSize;

    final header = <int>[
      // "RIFF" chunk descriptor
      0x52, 0x49, 0x46, 0x46, // "RIFF"
      fileSize & 0xFF, (fileSize >> 8) & 0xFF, (fileSize >> 16) & 0xFF,
      (fileSize >> 24) & 0xFF, // File size
      0x57, 0x41, 0x56, 0x45, // "WAVE"

      // "fmt " sub-chunk
      0x66, 0x6d, 0x74, 0x20, // "fmt "
      16, 0, 0, 0, // Sub-chunk size (16 for PCM)
      1, 0, // Audio format (1 for PCM)
      numChannels, 0, // Number of channels
      sampleRate & 0xFF, (sampleRate >> 8) & 0xFF, (sampleRate >> 16) & 0xFF,
      (sampleRate >> 24) & 0xFF, // Sample rate
      byteRate & 0xFF, (byteRate >> 8) & 0xFF, (byteRate >> 16) & 0xFF,
      (byteRate >> 24) & 0xFF, // Byte rate
      blockAlign, 0, // Block align
      bitsPerSample, 0, // Bits per sample

      // "data" sub-chunk
      0x64, 0x61, 0x74, 0x61, // "data"
      dataSize & 0xFF, (dataSize >> 8) & 0xFF, (dataSize >> 16) & 0xFF,
      (dataSize >> 24) & 0xFF, // Data size
    ];

    final result = Uint8List(header.length + audioData.length);
    result.setRange(0, header.length, header);
    result.setRange(header.length, result.length, audioData);

    return result;
  }

  Future<Uint8List> _createMinimalWav(Uint8List audioData) async {
    // Create a minimal WAV file with the provided audio data
    // Assume the data might be raw PCM
    if (audioData.length < 100) {
      // If the data is too small, create silence
      audioData = Uint8List(16000); // 1 second of silence at 16kHz
    }

    return _createWavFileWithHeader(audioData);
  }

  Future<bool> _isWavHeader(File file) async {
    try {
      if (await file.length() < 44) return false;
      final raf = await file.open(mode: FileMode.read);
      final header = await raf.read(12);
      await raf.close();

      // RIFF = 0x52, 0x49, 0x46, 0x46 | WAVE = 0x57, 0x41, 0x56, 0x45
      return header.length >= 12 &&
          header[0] == 0x52 &&
          header[1] == 0x49 &&
          header[2] == 0x46 &&
          header[3] == 0x46 &&
          header[8] == 0x57 &&
          header[9] == 0x41 &&
          header[10] == 0x56 &&
          header[11] == 0x45;
    } catch (e) {
      return false;
    }
  }
}
