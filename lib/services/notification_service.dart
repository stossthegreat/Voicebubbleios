import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _reminderPrefix = 'reminder_';

// SINGLE GLOBAL INSTANCE
final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

/// MUST be top-level function
@pragma('vm:entry-point')
Future<void> alarmCallback(int id) async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('⏰ ALARM FIRED: $id');

  final prefs = await SharedPreferences.getInstance();
  final data = prefs.getString('$_reminderPrefix$id');
  if (data == null) {
    debugPrint('❌ No data for alarm $id');
    return;
  }

  await prefs.remove('$_reminderPrefix$id');
  final json = jsonDecode(data);

  // Initialize plugin in isolate
  await _notificationsPlugin.initialize(
    const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
  );

  await _notificationsPlugin.show(
    id,
    json['title'],
    json['body'],
    NotificationDetails(
      android: AndroidNotificationDetails(
        'voicebubble_reminders_v2',
        'Reminders',
        importance: Importance.max,
        priority: Priority.max,
        enableVibration: true,
        playSound: true,
        visibility: NotificationVisibility.public,
        vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
      ),
    ),
    payload: json['itemId'],
  );
  debugPrint('✅ Notification shown');
}

class ReminderResult {
  final bool success;
  final String? error;
  final int? notificationId;
  ReminderResult.success(this.notificationId) : success = true, error = null;
  ReminderResult.failure(this.error) : success = false, notificationId = null;
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      tz.setLocalLocation(tz.UTC);
    }

    await AndroidAlarmManager.initialize();

    await _notificationsPlugin.initialize(
      const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          'voicebubble_reminders_v2',
          'Reminders',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
        ));

    _initialized = true;
    debugPrint('✅ NotificationService initialized');
  }

  Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    if (!status.isGranted) return false;
    await Permission.scheduleExactAlarm.request();
    await Permission.ignoreBatteryOptimizations.request();
    return true;
  }

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

    if (!await Permission.notification.isGranted) {
      if (!await requestPermission()) {
        return ReminderResult.failure('Permission denied');
      }
    }

    final int notificationId = itemId.hashCode.abs() % 2147483647;
    await AndroidAlarmManager.cancel(notificationId);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_reminderPrefix$notificationId', jsonEncode({
      'title': title,
      'body': body.length > 200 ? '${body.substring(0, 197)}...' : body,
      'itemId': itemId,
    }));

    final scheduled = await AndroidAlarmManager.oneShotAt(
      scheduledTime,
      notificationId,
      alarmCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      allowWhileIdle: true,
    );

    if (scheduled) {
      debugPrint('🔔 Scheduled for $scheduledTime (ID: $notificationId)');
      return ReminderResult.success(notificationId);
    }
    return ReminderResult.failure('Failed to schedule');
  }

  Future<void> cancelReminder(int notificationId) async {
    await AndroidAlarmManager.cancel(notificationId);
    await _notificationsPlugin.cancel(notificationId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_reminderPrefix$notificationId');
  }

  Future<void> cancelReminderByItemId(String itemId) async {
    await cancelReminder(itemId.hashCode.abs() % 2147483647);
  }

  /// Call this to test if notifications work at all
  Future<void> testNotificationNow() async {
    if (!_initialized) await initialize();

    await _notificationsPlugin.show(
      99999,
      '🔔 Test',
      'Notifications work!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'voicebubble_reminders_v2',
          'Reminders',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
        ),
      ),
    );
    debugPrint('🧪 Test notification sent');
  }
}
