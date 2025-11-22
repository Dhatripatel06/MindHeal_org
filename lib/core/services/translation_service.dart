// lib/core/services/translation_service.dart
import 'package:translator/translator.dart';

class TranslationService {
  final GoogleTranslator _translator = GoogleTranslator();

  /// Translates text from a source language to a target language.
  /// Example: translate("नमस्ते", from: 'hi', to: 'en') -> "Hello"
  Future<String> translate(String text, {String from = 'auto', String to = 'en'}) async {
    try {
      if (text.isEmpty) return "";
      if (from == to) return text; // No need to translate
      
      var translation = await _translator.translate(text, from: from, to: to);
      return translation.text;
    } catch (e) {
      print("Translation Error: $e");
      return text; // Return original text on error
    }
  }
}