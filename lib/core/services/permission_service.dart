import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<void> requestPermissions() async {
    await [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
      Permission.sensors,
    ].request();
  }
  
  static Future<bool> checkCameraPermission() async {
    return await Permission.camera.isGranted;
  }
  
  static Future<bool> checkMicrophonePermission() async {
    return await Permission.microphone.isGranted;
  }
}
