import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/event_data.dart';
import '../models/event_model.dart';
import '../services/notification_controller.dart';

/// Service to handle development-mode specific functionality
class DevModeService {
  static final DevModeService _instance = DevModeService._internal();

  /// Singleton pattern
  factory DevModeService() {
    return _instance;
  }

  DevModeService._internal();

  /// Whether the app is running in development mode
  bool get isDevMode => kDebugMode;

  /// Test sending an immediate notification
  Future<void> testNotification() async {
    if (!isDevMode) return;

    await NotificationController.createNewNotification();
  }

  /// Test scheduling a notification for a specified time in the future
  Future<void> testScheduledNotification({int minutesFromNow = 1}) async {
    if (!isDevMode) return;

    await NotificationController.scheduleNewNotificationExample();
  }

  /// Reset notification badge counter
  Future<void> resetBadgeCounter() async {
    if (!isDevMode) return;

    await NotificationController.resetBadgeCounter();
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (!isDevMode) return;

    await NotificationController.cancelNotifications();
  }

  /// Add demo data to the app
  Future<void> addDemoData(EventData eventData) async {
    if (!isDevMode) return;

    // Create a variety of sample events to demonstrate different features
    final now = DateTime.now();

    // Demo event 1: Simple upcoming birthday (no time)
    final birthday = Event(
      id: 'demo_birthday_${DateTime.now().millisecondsSinceEpoch}',
      title: 'John\'s Birthday',
      description: 'Don\'t forget to buy a gift!',
      endDate: DateTime(now.year, now.month + 1, 15), // Next month, day 15
      includeTime: false,
      isRepeating: true,
      repeatConfig: RepeatConfig(
        interval: 1,
        unit: FrequencyUnit.years,
      ),
      allowNotifications: true,
      notifications: [
        NotificationConfig(
          id: 'notify_1_${DateTime.now().millisecondsSinceEpoch}',
          amount: 1,
          unit: FrequencyUnit.days,
        ),
        NotificationConfig(
          id: 'notify_2_${DateTime.now().millisecondsSinceEpoch}',
          amount: 1,
          unit: FrequencyUnit.weeks,
        ),
      ],
    );

    // Demo event 2: Conference with specific time
    final conference = Event(
      id: 'demo_conference_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Flutter Conference',
      description: 'Annual Flutter developer conference with workshops and networking',
      endDate: DateTime(now.year, now.month, now.day + 14, 9, 0), // Two weeks from now, 9 AM
      includeTime: true,
      isRepeating: false,
      allowNotifications: true,
      notifications: [
        NotificationConfig(
          id: 'notify_3_${DateTime.now().millisecondsSinceEpoch}',
          amount: 1,
          unit: FrequencyUnit.days,
        ),
        NotificationConfig(
          id: 'notify_4_${DateTime.now().millisecondsSinceEpoch}',
          amount: 2,
          unit: FrequencyUnit.hours,
        ),
      ],
    );

    // Demo event 3: Weekly team meeting
    final teamMeeting = Event(
      id: 'demo_meeting_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Team Standup',
      description: 'Weekly progress update with the development team',
      endDate: DateTime(now.year, now.month, now.day + 2, 10, 30), // Day after tomorrow, 10:30 AM
      includeTime: true,
      isRepeating: true,
      repeatConfig: RepeatConfig(
        interval: 1,
        unit: FrequencyUnit.weeks,
      ),
      allowNotifications: true,
      notifications: [
        NotificationConfig(
          id: 'notify_5_${DateTime.now().millisecondsSinceEpoch}',
          amount: 15,
          unit: FrequencyUnit.minutes,
        ),
      ],
    );

    // Demo event 4: Upcoming vacation
    final vacation = Event(
      id: 'demo_vacation_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Summer Vacation',
      description: 'Two weeks in Hawaii - don\'t forget sunscreen!',
      endDate: DateTime(now.year, 7, 15), // July 15th
      includeTime: false,
      isRepeating: false,
      allowNotifications: true,
      notifications: [
        NotificationConfig(
          id: 'notify_6_${DateTime.now().millisecondsSinceEpoch}',
          amount: 1,
          unit: FrequencyUnit.months,
        ),
        NotificationConfig(
          id: 'notify_7_${DateTime.now().millisecondsSinceEpoch}',
          amount: 1,
          unit: FrequencyUnit.weeks,
        ),
        NotificationConfig(
          id: 'notify_8_${DateTime.now().millisecondsSinceEpoch}',
          amount: 1,
          unit: FrequencyUnit.days,
        ),
      ],
    );

    // Demo event 5: Bill payment (monthly)
    final billPayment = Event(
      id: 'demo_bill_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Rent Payment Due',
      description: 'Monthly rent payment',
      endDate: DateTime(now.year, now.month + 1, 1), // 1st of next month
      includeTime: false,
      isRepeating: true,
      repeatConfig: RepeatConfig(
        interval: 1,
        unit: FrequencyUnit.months,
      ),
      allowNotifications: true,
      notifications: [
        NotificationConfig(
          id: 'notify_9_${DateTime.now().millisecondsSinceEpoch}',
          amount: 3,
          unit: FrequencyUnit.days,
        ),
      ],
    );

    // Demo event 6: Custom event with very soon end date
    final soonEvent = Event(
      id: 'demo_soon_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Quick Coffee Break',
      description: 'Take a coffee break to refresh',
      endDate: DateTime(now.year, now.month, now.day, now.hour, now.minute + 30), // 30 minutes from now
      includeTime: true,
      isRepeating: false,
      allowNotifications: true,
      notifications: [
        NotificationConfig(
          id: 'notify_10_${DateTime.now().millisecondsSinceEpoch}',
          amount: 5,
          unit: FrequencyUnit.minutes,
        ),
      ],
    );

    // Add all demo events to the database
    final events = [birthday, conference, teamMeeting, vacation, billPayment, soonEvent];

    for (final event in events) {
      await eventData.addEvent(event);
    }
  }
}