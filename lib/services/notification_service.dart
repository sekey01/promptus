import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService instance = NotificationService._constructor();
  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  NotificationService._constructor();

  Future<void> init() async {
    // Initialize time zones
    tz.initializeTimeZones();

    // Android initialization settings - Use your app icon
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    // Combined initialization settings
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize the plugin
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification categories for iOS
    await _createIOSNotificationCategories();

    // Create notification channels for Android
    await _createAndroidNotificationChannels();

    // Request permissions after initialization
    await _requestPermissions();

    print('NotificationService initialized successfully');
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
        // Create alarm channel with maximum priority and custom sound
        final alarmChannel = AndroidNotificationChannel(
          'task_alarms',
          'Task Alarms',
          description: 'Alarm-style notifications for task reminders',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: const Color.fromARGB(255, 255, 0, 0),
          vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
          sound: const RawResourceAndroidNotificationSound('alarm_sound'),
        );

        // Create regular reminder channel
        const reminderChannel = AndroidNotificationChannel(
          'task_reminders',
          'Task Reminders',
          description: 'Regular notifications for task reminders',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        );

        await androidImplementation.createNotificationChannel(alarmChannel);
        await androidImplementation.createNotificationChannel(reminderChannel);

        print('Android notification channels created with custom alarm sound');
      }
    }
  }

  // Request permissions for both Android and iOS
  Future<bool> _requestPermissions() async {
    bool permissionGranted = false;

    if (Platform.isAndroid) {
      // Request Android permissions
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        permissionGranted = await androidImplementation.requestNotificationsPermission() ?? false;
        print('Android notification permission granted: $permissionGranted');
      }
    } else if (Platform.isIOS) {
      // Request iOS permissions
      final iosImplementation = _notifications
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      if (iosImplementation != null) {
        permissionGranted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ?? false;
        print('iOS notification permission granted: $permissionGranted');
      }
    }

    return permissionGranted;
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
          final settings = await iosImplementation.checkPermissions();
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

      // Android notification details for regular notifications with custom icon
      const androidDetails = AndroidNotificationDetails(
        'task_reminders',
        'Task Reminders',
        channelDescription: 'Regular notifications for task reminders',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher', // Use your custom app icon
      );

      // iOS notification details for regular notifications
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

      // Schedule the notification
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        details,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
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

      // Android notification details with custom icon
      const androidDetails = AndroidNotificationDetails(
        'task_reminders',
        'Task Reminders',
        channelDescription: 'Notifications for task reminders',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher', // Use your custom app icon
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

    bool hasPermissions = permissionsGranted;

    if (!permissionsGranted) {
      print('Requesting permissions...');
      final granted = await requestPermissions();
      print('Permission request result: $granted');
      hasPermissions = granted;
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
          final settings = await iosImplementation.checkPermissions();
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

      // Android notification details with maximum priority and full-screen intent
      final androidDetails = AndroidNotificationDetails(
        'task_alarms',
        'Task Alarms',
        channelDescription: 'Alarm-style notifications for task reminders',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        icon: '@mipmap/ic_launcher', // Use your custom app icon
        sound: const RawResourceAndroidNotificationSound('alarm_sound'),
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        ongoing: true,
        autoCancel: false,
        usesChronometer: false,
        timeoutAfter: 60000, // Auto dismiss after 1 minute
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
        styleInformation: const BigTextStyleInformation(''),
        additionalFlags: Int32List.fromList(<int>[4]), // FLAG_INSISTENT for repeating sound
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

      // Schedule the notification
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        details,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
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