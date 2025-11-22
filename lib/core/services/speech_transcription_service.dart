// lib/core/services/speech_transcription_service.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mime/mime.dart';
import 'package:mental_wellness_app/core/config/app_config.dart';
import 'package:http_parser/http_parser.dart' as http_parser; // --- ADD THIS IMPORT ---

class SpeechTranscriptionService {
  final String _apiKey = AppConfig.openAiApiKey;
  final String _apiUrl = 'https://api.openai.com/v1/audio/transcriptions';

  /// Transcribes the given audio file using OpenAI Whisper API.
  /// languageCode is an ISO 639-1 code (e.g., 'en', 'hi', 'gu')
  Future<String> transcribeAudio(File audioFile, String languageCode) async {
    if (_apiKey == 'YOUR_OPENAI_API_KEY' || _apiKey == 'MISSING_OPENAI_KEY') {
      throw Exception('OpenAI API Key not set in AppConfig/.env');
    }

    try {
      var request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
      request.headers['Authorization'] = 'Bearer $_apiKey';
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          audioFile.path,
          // --- FIX: Use the http_parser alias ---
          contentType: http_parser.MediaType.parse(
            lookupMimeType(audioFile.path) ?? 'audio/mpeg',
          ),
        ),
      );
      
      request.fields['model'] = 'whisper-1';
      request.fields['language'] = languageCode; // Pass the user's selected language

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var data = json.decode(responseBody);
        return data['text'] as String;
      } else {
        print("Whisper API Error: $responseBody");
        throw Exception('Failed to transcribe audio. Status: ${response.statusCode}');
      }
    } catch (e) {
      print("Error in transcribeAudio: $e");
      throw Exception('Failed to transcribe audio: $e');
    }
  }
}