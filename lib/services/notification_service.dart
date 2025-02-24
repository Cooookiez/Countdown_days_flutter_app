import 'package:awesome_notifications/awesome_notifications.dart';

import '../models/event_model.dart';
import 'notification_controller.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  /// Schedule notifications for an event
  Future<void> scheduleEventNotifications(Event event) async {
    // If notifications are not allowed for this event, return
    if (!event.allowNotifications || event.notifications.isEmpty) {
      return;
    }

    // First, cancel any existing notifications for this event
    await cancelEventNotifications(event.id);

    // Check if notifications are allowed by the system
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      isAllowed = await NotificationController.displayNotificationRationale();
      if (!isAllowed) return; // User denied permission
    }

    // Schedule each notification
    for (final notification in event.notifications) {
      if (!notification.isEnabled) continue;

      // Calculate when the notification should be shown
      final notifyTime = notification.getNotificationTime(event.endDate);

      // Only schedule future notifications
      if (notifyTime.isBefore(DateTime.now())) continue;

      // Create a unique ID for this notification
      final notificationId = int.parse(event.id.substring(0, 8), radix: 16) ^
      int.parse(notification.id.substring(0, 8), radix: 16);

      String timeDisplay = '${notification.amount} ${_formatUnit(notification.unit, notification.amount)}';

      await AwesomeNotifications().createNotification(
        schedule: NotificationCalendar.fromDate(date: notifyTime),
        content: NotificationContent(
          id: notificationId,
          channelKey: 'remainder',
          title: 'Event Reminder: ${event.title}',
          body: '${event.title} is coming up in $timeDisplay${event.description != null ? "\n${event.description}" : ""}',
          notificationLayout: NotificationLayout.Default,
          payload: {
            'eventId': event.id,
            'type': 'event_reminder',
          },
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'VIEW_EVENT',
            label: 'View Details',
          ),
          NotificationActionButton(
            key: 'DISMISS',
            label: 'Dismiss',
            actionType: ActionType.DismissAction,
          ),
        ],
      );
    }
  }

  /// Cancel all notifications for an event
  Future<void> cancelEventNotifications(String eventId) async {
    // Generate a range of potential notification IDs for this event
    final baseId = int.parse(eventId.substring(0, 8), radix: 16);
    final ids = List.generate(100, (index) => baseId ^ index);

    // Cancel each potential notification
    for (final id in ids) {
      await AwesomeNotifications().cancel(id);
    }
  }

  /// Helper to format time units for display
  String _formatUnit(FrequencyUnit unit, int amount) {
    switch (unit) {
      case FrequencyUnit.minutes:
        return amount == 1 ? 'minute' : 'minutes';
      case FrequencyUnit.hours:
        return amount == 1 ? 'hour' : 'hours';
      case FrequencyUnit.days:
        return amount == 1 ? 'day' : 'days';
      case FrequencyUnit.weeks:
        return amount == 1 ? 'week' : 'weeks';
      case FrequencyUnit.months:
        return amount == 1 ? 'month' : 'months';
      case FrequencyUnit.years:
        return amount == 1 ? 'year' : 'years';
    }
  }
}