import 'package:flutter/material.dart';
import '../models/recording_item.dart';
import '../providers/app_state_provider.dart';
import '../widgets/reminder_picker_dialog.dart';
import 'notification_service.dart';

class ReminderManager {
  static final ReminderManager _instance = ReminderManager._internal();
  factory ReminderManager() => _instance;
  ReminderManager._internal();

  final NotificationService _notificationService = NotificationService();

  /// Initialize - call once at app startup
  Future<void> initialize() async {
    await _notificationService.initialize();
  }

  /// Request permission - call at appropriate time (onboarding or first reminder)
  Future<bool> requestPermission() async {
    return await _notificationService.requestPermission();
  }

  /// Schedule a reminder for an item (used by creation screens)
  Future<void> scheduleReminder(RecordingItem item) async {
    if (item.reminderDateTime == null) return;

    await _notificationService.scheduleReminder(
      itemId: item.id,
      title: 'VoiceBubble Reminder',
      body: _getNotificationBody(item),
      scheduledTime: item.reminderDateTime!,
    );
  }

  /// Show reminder picker and handle the result
  Future<void> showReminderPicker({
    required BuildContext context,
    required RecordingItem item,
    required AppStateProvider appState,
  }) async {
    final selectedDateTime = await ReminderPickerDialog.show(
      context,
      initialDateTime: item.reminderDateTime,
    );

    // User cancelled the dialog - do nothing if no change
    if (selectedDateTime == item.reminderDateTime) {
      return;
    }

    // Handle the reminder change
    await _handleReminderChange(
      context: context,
      item: item,
      appState: appState,
      newDateTime: selectedDateTime,
    );
  }

  /// Handle reminder change (set or remove)
  Future<void> _handleReminderChange({
    required BuildContext context,
    required RecordingItem item,
    required AppStateProvider appState,
    required DateTime? newDateTime,
  }) async {
    if (newDateTime != null) {
      // Setting a reminder
      final result = await _notificationService.scheduleReminder(
        itemId: item.id,
        title: 'VoiceBubble Reminder',
        body: _getNotificationBody(item),
        scheduledTime: newDateTime,
      );

      if (result.success) {
        // Update item with reminder info
        final updatedItem = item.copyWith(
          reminderDateTime: newDateTime,
          reminderNotificationId: result.notificationId,
        );
        await appState.updateRecording(updatedItem);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reminder set for ${_formatDateTime(newDateTime)}'),
              backgroundColor: const Color(0xFF3B82F6),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Failed to set reminder'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      // Removing a reminder
      if (item.reminderNotificationId != null) {
        await _notificationService.cancelReminder(item.reminderNotificationId!);
      } else {
        await _notificationService.cancelReminderByItemId(item.id);
      }

      // Update item to remove reminder info
      final updatedItem = item.copyWith(clearReminder: true);
      await appState.updateRecording(updatedItem);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reminder removed'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Cancel a reminder for an item
  Future<void> cancelReminder(RecordingItem item) async {
    if (item.reminderNotificationId != null) {
      await _notificationService.cancelReminder(item.reminderNotificationId!);
    } else {
      await _notificationService.cancelReminderByItemId(item.id);
    }
    debugPrint('🔕 Cancelled reminder for item: ${item.id}');
  }

  /// Cancel reminder when item is deleted
  Future<void> cancelReminderForDeletedItem(RecordingItem item) async {
    if (item.reminderDateTime == null) return;

    if (item.reminderNotificationId != null) {
      await _notificationService.cancelReminder(item.reminderNotificationId!);
    } else {
      await _notificationService.cancelReminderByItemId(item.id);
    }
    
    debugPrint('🔕 Cancelled reminder for deleted item: ${item.id}');
  }

  /// Get notification body text from item
  String _getNotificationBody(RecordingItem item) {
    final text = item.finalText;
    if (text.isEmpty) return 'Tap to view';
    return text.length > 150 ? '${text.substring(0, 147)}...' : text;
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(dt.year, dt.month, dt.day);

    String dateStr;
    if (dateOnly == today) {
      dateStr = 'today';
    } else if (dateOnly == tomorrow) {
      dateStr = 'tomorrow';
    } else {
      dateStr = '${dt.day}/${dt.month}';
    }

    return '$dateStr at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
