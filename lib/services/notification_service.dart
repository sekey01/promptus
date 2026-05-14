import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService  extends ChangeNotifier{
  static final NotificationService instance = NotificationService._constructor();
  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  NotificationService._constructor();

  Future<void> init() async {
    // Timezone — must succeed before any scheduling
    tz.initializeTimeZones();
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (e) {
      print('Timezone init error: $e');
    }

    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    // Core plugin init — must succeed for anything to work
    await _notifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Channel creation and permissions are non-critical individually
    try { await _createIOSNotificationCategories(); } catch (_) {}
    try { await _createAndroidNotificationChannels(); } catch (_) {}
    // Permissions run in the background — failures are logged inside _requestPermissions
    _requestPermissions();
  }

  // Handle notification tap and actions
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    print('Action ID: ${response.actionId}');

    // Handle snooze action
    if (response.actionId?.startsWith('snooze_') == true) {

      final taskIdStr = response.actionId!.replaceFirst('snooze_', '');
      final taskId = int.tryParse(taskIdStr);

      if (taskId != null) {
        _snoozeAlarm(taskId);
      }
    }

    // Handle dismiss action (notification is automatically cancelled)
    if (response.actionId?.startsWith('dismiss_') == true) {
      print('Alarm dismissed');
    }
  }

  // Snooze alarm for 5 minutes
  Future<void> _snoozeAlarm(int originalId) async {
    print('Snoozing alarm for task ID: $originalId');

    // Cancel the current notification
    await cancelNotification(originalId);

    // Schedule a new notification 5 minutes from now
    final snoozeTime = DateTime.now().add(const Duration(minutes: 5));

    await scheduleAlarmNotification(
      id: originalId + 10000, // Use different ID for snoozed notification
      title: 'Task Reminder (Snoozed)',
      body: 'Your snoozed task reminder',
      scheduledTime: snoozeTime,
      payload: 'snoozed_task_$originalId',
    );
  }

  // Create iOS notification categories with actions
  Future<void> _createIOSNotificationCategories() async {
    if (Platform.isIOS) {
      final iosImplementation = _notifications
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      if (iosImplementation != null) {
        // Request standard permissions for iOS
        await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

        print('iOS critical notification permissions requested');
      }
    }
  }

  // Create Android notification channels
  Future<void> _createAndroidNotificationChannels() async {
    if (Platform.isAndroid) {
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        // New channel IDs force Android to recreate channels with correct settings.
        // Old channels (task_alarms/task_reminders) had a non-existent sound file
        // cached permanently by Android, causing silent notifications.
        final alarmChannel = AndroidNotificationChannel(
          'promptus_alarms',
          'Promptus Alarms',
          description: 'Alarm-style notifications for task reminders',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: const Color.fromARGB(255, 255, 0, 0),
          vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
        );

        final reminderChannel = AndroidNotificationChannel(
          'promptus_reminders',
          'Promptus Reminders',
          description: 'Notifications for task and note reminders',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
        );

        await androidImplementation.createNotificationChannel(alarmChannel);
        await androidImplementation.createNotificationChannel(reminderChannel);

        print('Android notification channels created with custom alarm sound');
      }
    }
  }

  // Request permissions for both Android and iOS.
  // Each request is isolated so a single failure never blocks the rest.
  Future<bool> _requestPermissions() async {
    bool permissionGranted = false;

    if (Platform.isAndroid) {
      final impl = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (impl != null) {
        // Basic notification permission (Android 13+)
        try {
          permissionGranted = await impl.requestNotificationsPermission() ?? false;
        } catch (e) {
          print('Notification permission error: $e');
        }

        // Exact alarm permission — Android 12 (API 31-32) only; API 33+ uses USE_EXACT_ALARM
        try {
          final canExact = await impl.canScheduleExactNotifications() ?? true;
          if (!canExact) await impl.requestExactAlarmsPermission();
        } catch (e) {
          print('Exact alarm permission error: $e');
        }

        // Full-screen intent permission — Android 14+ only; no-op on lower versions
        try {
          await impl.requestFullScreenIntentPermission();
        } catch (e) {
          print('Full screen intent permission error: $e');
        }

        // Battery optimization exclusion — lets alarms fire when app is killed on OEM devices
        try {
          final status = await Permission.ignoreBatteryOptimizations.status;
          if (!status.isGranted) {
            await Permission.ignoreBatteryOptimizations.request();
          }
        } catch (e) {
          print('Battery optimization permission error: $e');
        }
      }
    } else if (Platform.isIOS) {
      final iosImpl = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosImpl != null) {
        try {
          permissionGranted = await iosImpl.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ?? false;
        } catch (e) {
          print('iOS permission error: $e');
        }
      }
    }

    return permissionGranted;
  }

  // Returns true if exact alarm scheduling is available on this device.
  // On Android 13+ with USE_EXACT_ALARM it's always true.
  // On Android 12 it requires the runtime SCHEDULE_EXACT_ALARM grant.
  Future<bool> _canScheduleExact() async {
    if (!Platform.isAndroid) return true;
    final impl = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await impl?.canScheduleExactNotifications() ?? true;
  }

  // Public method to request permissions
  Future<bool> requestPermissions() async {
    return await _requestPermissions();
  }

  // Check if permissions are granted
  Future<bool> arePermissionsGranted() async {
    if (Platform.isAndroid) {
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        return await androidImplementation.areNotificationsEnabled() ?? false;
      }
    } else if (Platform.isIOS) {
      final iosImplementation = _notifications
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      if (iosImplementation != null) {
        try {
          final settings = await iosImplementation.getActiveNotifications();
          print('iOS notification settings: ${settings.toString()}');

          // For iOS, we'll assume permissions are granted if request was successful
          // This is a workaround for permission checking issues
          return true;
        } catch (e) {
          print('Error checking iOS permissions: $e');
          // Fallback: assume permissions are granted if we can't check
          return true;
        }
      }
    }
    return false;
  }

  // Schedule a regular notification
  Future<bool> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    bool isAlarmStyle = false, // New parameter to choose notification type
  }) async {
    // If alarm style is requested, use the alarm notification
    if (isAlarmStyle) {
      return await scheduleAlarmNotification(
        id: id,
        title: title,
        body: body,
        scheduledTime: scheduledTime,
        payload: payload,
      );
    }

    try {
      // Ensure the scheduled time is at least 5 seconds in the future
      final now = DateTime.now();
      final minimumFutureTime = now.add(const Duration(seconds: 5));

      if (scheduledTime.isBefore(minimumFutureTime)) {
        print('Adjusting notification time to be 5 seconds in the future');
        scheduledTime = minimumFutureTime;
      }

      print('Scheduling regular notification for: $scheduledTime');
      print('Current time: $now');
      print('Time difference: ${scheduledTime.difference(now).inSeconds} seconds');

      // Use alarm audio stream + fullScreenIntent so reminders always popup and ring.
      const androidDetails = AndroidNotificationDetails(
        'promptus_reminders',
        'Promptus Reminders',
        channelDescription: 'Notifications for task and note reminders',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        icon: '@drawable/ic_notification',
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Combined notification details
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final canExact = await _canScheduleExact();
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        details,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: canExact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );

      print('Regular notification scheduled successfully with ID: $id');
      return true;
    } catch (e) {
      print('Error scheduling regular notification: $e');
      return false;
    }
  }

  // Show immediate notification (for testing)
  Future<bool> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    bool skipPermissionCheck = false,
  }) async {
    try {
      // Check if permissions are granted (unless skipped)
      if (!skipPermissionCheck) {
        final permissionsGranted = await arePermissionsGranted();
        if (!permissionsGranted) {
          print('Notification permissions not granted');
          return false;
        }
      }

      const androidDetails = AndroidNotificationDetails(
        'promptus_reminders',
        'Promptus Reminders',
        channelDescription: 'Notifications for task and note reminders',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@drawable/ic_notification', // Use your custom app icon
      );

      // iOS notification details
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default.wav',
      );

      // Combined notification details
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Show the notification immediately
      await _notifications.show(id, title, body, details, payload: payload);

      print('Immediate notification shown successfully');
      return true;
    } catch (e) {
      print('Error showing immediate notification: $e');
      return false;
    }
  }

  // Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
      print('Notification with ID $id cancelled');
    } catch (e) {
      print('Error cancelling notification: $e');
    }
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      print('All notifications cancelled');
    } catch (e) {
      print('Error cancelling all notifications: $e');
    }
  }

  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      final pendingNotifications = await _notifications.pendingNotificationRequests();
      print('Pending notifications: ${pendingNotifications.length}');
      return pendingNotifications;
    } catch (e) {
      print('Error getting pending notifications: $e');
      return [];
    }
  }

  // Test notification permissions and functionality
  Future<void> testNotifications() async {
    print('Testing notification functionality...');

    // Check permissions first
    final permissionsGranted = await arePermissionsGranted();
    print('Permissions granted: $permissionsGranted');

    if (!permissionsGranted) {
      print('Requesting permissions...');
      final granted = await requestPermissions();
      print('Permission request result: $granted');
    }

    // Show immediate test notification
    final immediateSuccess = await showImmediateNotification(
      id: 999,
      title: 'Immediate Test',
      body: 'This should appear immediately!',
      skipPermissionCheck: true,
    );

    print('Immediate notification result: $immediateSuccess');

    // Schedule a test notification for 5 seconds from now
    final futureTime = DateTime.now().add(const Duration(seconds: 5));
    final scheduledSuccess = await scheduleNotification(
      id: 998,
      title: 'Scheduled Test',
      body: 'This should appear in 5 seconds!',
      scheduledTime: futureTime,
    );

    print('Scheduled notification result: $scheduledSuccess');

    // Also try to get notification settings for debugging
    if (Platform.isIOS) {
      final iosImplementation = _notifications
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      if (iosImplementation != null) {
        try {
          final settings = await iosImplementation.requestPermissions();
          print('Detailed iOS settings: ${settings.toString()}');
        } catch (e) {
          print('Error getting iOS settings: $e');
        }
      }
    }
  }

  // Test basic iOS sound first
  Future<void> testBasicIOSSound() async {
    print('Testing basic iOS notification sound...');

    if (!Platform.isIOS) {
      print('Not running on iOS');
      return;
    }

    final testTime = DateTime.now().add(const Duration(seconds: 3));

    try {
      // Test with default system sound first
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        badgeNumber: 1,
        subtitle: 'Sound Test',
      );

      const details = NotificationDetails(iOS: iosDetails);

      await _notifications.zonedSchedule(
        77777,
        'SOUND TEST',
        'Testing default notification sound',
        tz.TZDateTime.from(testTime, tz.local),
        details,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
      );

      print('Basic sound test scheduled for 3 seconds');
    } catch (e) {
      print('Error in basic sound test: $e');
    }
  }

  // Test with maximum settings - should definitely make sound
  Future<void> testMaxVolumeAlarm() async {
    print('Testing MAXIMUM VOLUME alarm...');

    if (!Platform.isIOS) return;

    final testTime = DateTime.now().add(const Duration(seconds: 5));

    try {
      // Request ALL permissions first
      final iosImplementation = _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

      if (iosImplementation != null) {
        await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      // Use working settings without unsupported parameters
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'Alarm.caf', // Built-in iOS alarm sound
        badgeNumber: 1,
        subtitle: 'MAX VOLUME TEST',
        threadIdentifier: 'alarm_test',
      );

      const details = NotificationDetails(iOS: iosDetails);

      await _notifications.zonedSchedule(
        55555,
        '🚨 MAX VOLUME ALARM 🚨',
        'This should be LOUD! Check your silent switch!',
        tz.TZDateTime.from(testTime, tz.local),
        details,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
      );

      print('MAX VOLUME alarm scheduled');
    } catch (e) {
      print('Error in max volume test: $e');
    }
  }

  // Schedule an alarm-style notification that plays until dismissed
  Future<bool> scheduleAlarmNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    try {
      // Ensure the scheduled time is at least 5 seconds in the future
      final now = DateTime.now();
      final minimumFutureTime = now.add(const Duration(seconds: 5));

      if (scheduledTime.isBefore(minimumFutureTime)) {
        print('Adjusting notification time to be 5 seconds in the future');
        scheduledTime = minimumFutureTime;
      }

      print('Scheduling alarm notification for: $scheduledTime');
      print('Current time: $now');
      print('Time difference: ${scheduledTime.difference(now).inSeconds} seconds');

      final androidDetails = AndroidNotificationDetails(
        'promptus_alarms',
        'Promptus Alarms',
        channelDescription: 'Alarm-style notifications for task reminders',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        icon: '@drawable/ic_notification',
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        ongoing: true,
        autoCancel: false,
        timeoutAfter: 60000,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'dismiss_$id',
            'Dismiss',
            cancelNotification: true,
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            'snooze_$id',
            'Snooze 5 min',
            cancelNotification: true,
            showsUserInterface: true,
          ),
        ],
      );

      // iOS notification details with built-in alarm sound (PROVEN TO WORK)
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'Alarm.caf', // Use built-in iOS alarm sound that we know works
        badgeNumber: 1,
        subtitle: 'Task Reminder',
        threadIdentifier: 'task_alarms',
      );

      // Combined notification details
      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final canExact = await _canScheduleExact();
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        details,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: canExact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );

      print('Alarm notification scheduled successfully with ID: $id');
      return true;
    } catch (e) {
      print('Error scheduling alarm notification: $e');
      return false;
    }
  }
}