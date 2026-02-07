import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class ReminderResult {
  final bool success;
  final String? error;
  final int? notificationId;
  ReminderResult.success(this.notificationId) : success = true, error = null;
  ReminderResult.failure(this.error) : success = false, notificationId = null;
}

/// EXACT copy of FitnessOS WorkoutAlarmService pattern
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const String _channelId = 'voicebubble_reminders';
  static const String _channelName = 'Reminders';
  static const String _channelDescription = 'Reminder notifications';

  /// Initialize - MUST be called from main()
  Future<void> initialize() async {
    if (_initialized) {
      debugPrint('⚠️ NotificationService already initialized');
      return;
    }

    try {
      debugPrint('🔧 Initializing NotificationService...');

      // Initialize timezone
      tz.initializeTimeZones();
      try {
        final timeZoneName = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        debugPrint('🕐 Timezone: $timeZoneName');
      } catch (e) {
        tz.setLocalLocation(tz.UTC);
      }

      // Initialize notification plugin
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      debugPrint('✅ Notification plugin initialized');

      if (Platform.isAndroid) {
      // Get Android plugin for platform-specific setup
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        // Request notification permission (Android 13+)
        final notifGranted = await androidPlugin.requestNotificationsPermission();
        debugPrint('📱 Notification permission granted: $notifGranted');

        // Request exact alarm permission (Android 12+)
        final alarmGranted = await androidPlugin.requestExactAlarmsPermission();
        debugPrint('⏰ Exact alarm permission granted: $alarmGranted');

        // Create notification channel with MAX PRIORITY
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            enableLights: true,
          ),
        );
        debugPrint('✅ Notification channel created');
      }
      } // end Platform.isAndroid

      _initialized = true;
      debugPrint('🎉 NotificationService fully initialized!');
    } catch (e, stack) {
      debugPrint('❌ NotificationService initialization failed: $e');
      debugPrint('Stack: $stack');
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: ${response.payload}');
  }

  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        await androidPlugin.requestExactAlarmsPermission();
        return granted ?? false;
      }
    } else if (Platform.isIOS) {
      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    }
    return false;
  }

  /// Schedule a reminder using zonedSchedule (same as FitnessOS)
  Future<ReminderResult> scheduleReminder({
    required String itemId,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (!_initialized) await initialize();

    if (scheduledTime.isBefore(DateTime.now())) {
      return ReminderResult.failure('Cannot schedule in the past');
    }

    final int notificationId = itemId.hashCode.abs() % 2147483647;

    // Cancel existing
    await _notifications.cancel(notificationId);

    try {
      final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

      debugPrint('📅 Scheduling reminder:');
      debugPrint('   - ID: $notificationId');
      debugPrint('   - Time: $tzScheduledTime');

      await _notifications.zonedSchedule(
        notificationId,
        title,
        body.length > 200 ? '${body.substring(0, 197)}...' : body,
        tzScheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            enableVibration: true,
            visibility: NotificationVisibility.public,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: itemId,
      );

      debugPrint('✅ Reminder scheduled successfully');
      return ReminderResult.success(notificationId);
    } catch (e) {
      debugPrint('❌ Failed to schedule: $e');
      return ReminderResult.failure('Failed to schedule: $e');
    }
  }

  Future<void> cancelReminder(int notificationId) async {
    await _notifications.cancel(notificationId);
    debugPrint('🔕 Cancelled reminder $notificationId');
  }

  Future<void> cancelReminderByItemId(String itemId) async {
    await cancelReminder(itemId.hashCode.abs() % 2147483647);
  }
}
