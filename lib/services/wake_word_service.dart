import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';

class WakeWordService {
  static Future<bool> isRunning() => FlutterBackgroundService().isRunning();

  static Future<bool> hasPermission() async =>
      await Permission.microphone.status == PermissionStatus.granted;

  static Future<void> requestPermission() async =>
      await Permission.microphone.request();

  /// Always true — Google Speech needs no local model download.
  static Future<bool> isModelReady() async => true;

  static Future<void> start() async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      throw const WakeWordError(
          'Microphone permission is required. Grant it and try again.');
    }
    await FlutterBackgroundService().startService();
  }

  static Future<void> stop() async {
    FlutterBackgroundService().invoke('stop');
    await Future.delayed(const Duration(milliseconds: 400));
  }
}

class WakeWordError {
  final String message;
  const WakeWordError(this.message);
}
