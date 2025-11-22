import 'package:flutter/services.dart';

class AssetDebugService {
  static Future<void> checkAssets() async {
    print('🔍 Checking asset availability...');
    
    // List of assets to check
    final assetsToCheck = [
      'models/fer2013_model_direct.tflite',
      'models/labels.txt',
    ];
    
    for (final asset in assetsToCheck) {
      try {
        final data = await rootBundle.load(asset);
        print('✅ Asset found: $asset (${data.lengthInBytes} bytes)');
      } catch (e) {
        print('❌ Asset missing: $asset - Error: $e');
      }
    }
    
    // Try to read labels file content
    try {
      final labelsContent = await rootBundle.loadString('models/labels.txt');
      print('📝 Labels content: $labelsContent');
    } catch (e) {
      print('❌ Cannot read labels file: $e');
    }
  }
}