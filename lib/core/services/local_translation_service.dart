// lib/core/services/local_translation_service.dart
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:flutter/foundation.dart';

class LocalTranslationService {
  final _modelManager = OnDeviceTranslatorModelManager();

  /// Maps your app's language codes to ML Kit's language enums.
  TranslateLanguage _codeToLang(String code) {
    switch (code) {
      case 'hi':
        return TranslateLanguage.hindi;
      case 'gu':
        return TranslateLanguage.gujarati;
      case 'en':
      default:
        return TranslateLanguage.english;
    }
  }

  /// Downloads all required language models.
  /// Call this when your app starts or your provider initializes.
  Future<void> downloadAllModels() async {
    debugPrint("Checking translation models...");
    // The model manager takes the BCP-47 string codes directly.
    final modelsToDownload = [
      'hi', // Hindi
      'gu', // Gujarati
      'en', // English
    ];

    for (final model in modelsToDownload) {
      if (await _modelManager.isModelDownloaded(model)) {
        debugPrint("Translation model $model is already downloaded.");
      } else {
        debugPrint("Downloading translation model $model...");
        try {
          await _modelManager.downloadModel(model, isWifiRequired: false);
          debugPrint("Model $model downloaded successfully.");
        } catch (e) {
          debugPrint("Error downloading model $model: $e");
        }
      }
    }
  }

  /// Translates text from a source language to a target language.
  Future<String> translate(String text, {String from = 'auto', String to = 'en'}) async {
    // No need to translate if languages are the same
    if (text.isEmpty || from == to) {
      return text;
    }

    // `auto` (language detection) is not supported by this package.
    // We must provide the 'from' language, which we have (currentLangCode).
    if (from == 'auto') {
       debugPrint("LocalTranslationService requires a 'from' language, but got 'auto'. Returning original text.");
       return text;
    }

    final translator = OnDeviceTranslator(
      sourceLanguage: _codeToLang(from),
      targetLanguage: _codeToLang(to),
    );

    try {
      final translatedText = await translator.translateText(text);
      return translatedText;
    } catch (e) {
      debugPrint("Error during on-device translation: $e");
      return text; // Return original text on error
    } finally {
      // Release resources
      translator.close();
    }
  }
}