import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:speech_to_text/speech_to_text.dart';

const _kListenChannelId = 'promptus_wake_word';
const _kAlertChannelId = 'promptus_wake_fullscreen'; // max importance for full-screen intent
const _kNotifId = 9001;
const _kAlertId = 9002;

Future<void> initWakeWordService() async {
  final notifPlugin = FlutterLocalNotificationsPlugin()
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  await notifPlugin?.createNotificationChannel(const AndroidNotificationChannel(
    _kListenChannelId,
    'Promptus Wake Word',
    description: 'Listening for the Promptus wake word',
    importance: Importance.low,
    playSound: false,
    enableVibration: false,
  ));

  // max importance + full-screen intent = app opens automatically (like an alarm)
  await notifPlugin?.createNotificationChannel(const AndroidNotificationChannel(
    _kAlertChannelId,
    'Promptus Wake Alert',
    description: 'Opens the app when wake word is detected',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  ));

  await FlutterBackgroundService().configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onWakeWordServiceStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: _kListenChannelId,
      initialNotificationTitle: 'Promptus Wake Word',
      initialNotificationContent: 'Listening for "Promptus"…',
      foregroundServiceNotificationId: _kNotifId,
      foregroundServiceTypes: [AndroidForegroundType.microphone],
    ),
    iosConfiguration: IosConfiguration(autoStart: false),
  );
}

@pragma('vm:entry-point')
void onWakeWordServiceStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final stt = SpeechToText();
  final notif = FlutterLocalNotificationsPlugin();
  await notif.initialize(const InitializationSettings(
    android: AndroidInitializationSettings('@drawable/ic_notification'),
  ));

  service.on('stop').listen((_) async {
    await stt.stop();
    service.stopSelf();
  });

  final available = await stt.initialize(
    onError: (_) {},
    onStatus: (status) {
      // Restart listening whenever the recognizer finishes an utterance
      if (status == SpeechToText.doneStatus || status == 'notListening') {
        Future.delayed(const Duration(milliseconds: 600),
            () => _listen(stt, notif));
      }
    },
  );

  if (!available) {
    service.stopSelf();
    return;
  }

  _listen(stt, notif);
}

void _listen(SpeechToText stt, FlutterLocalNotificationsPlugin notif) {
  if (stt.isListening) return;
  stt.listen(
    onResult: (result) {
      final words = result.recognizedWords.toLowerCase();
      // "Promptus" is decoded by Google Speech as "prompt", "prompt us", etc.
      if (words.contains('prompt')) {
        _fireWakeAlert(notif);
      }
    },
    listenFor: const Duration(seconds: 30),
    pauseFor: const Duration(seconds: 5),
    listenOptions: SpeechListenOptions(
      partialResults: true,
      cancelOnError: false,
    ),
  );
}

void _fireWakeAlert(FlutterLocalNotificationsPlugin notif) {
  notif.show(
    _kAlertId,
    'Promptus',
    'Wake word detected — opening app…',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        _kAlertChannelId,
        'Promptus Wake Alert',
        importance: Importance.max,
        priority: Priority.max,
        // fullScreenIntent: true makes Android open the app automatically
        // when screen is off/idle; shows as heads-up when screen is on.
        fullScreenIntent: true,
        autoCancel: true,
        playSound: true,
        enableVibration: true,
      ),
    ),
  );
}
