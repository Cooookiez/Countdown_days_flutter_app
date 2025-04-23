import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event_data.dart';
import '../models/event_model.dart';

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  static const String _lastUpdateTimeKey = 'last_repeating_events_update';

  Timer? _updateTimer;

  factory BackgroundService() {
    return _instance;
  }

  BackgroundService._internal();

  /// Initialize the background service
  Future<void> initialize(EventData eventData) async {
    // Cancel any existing timer
    _updateTimer?.cancel();

    // Check for repeating events that need to be updated
    await _checkAndUpdateEvents(eventData);

    // Check if there are any minute or hour based events
    bool hasShortIntervalEvents = eventData.events.any((event) =>
    event.isRepeating &&
        event.repeatConfig != null &&
        (event.repeatConfig!.unit == FrequencyUnit.minutes ||
            event.repeatConfig!.unit == FrequencyUnit.hours));

    // Set up a periodic timer to check again - more frequently if there are short-interval events
    Duration checkInterval = hasShortIntervalEvents
        ? const Duration(minutes: 1)  // Check every minute if we have minute-based events
        : const Duration(hours: 1);   // Otherwise check hourly

    // Set up a periodic timer to check again (every hour)
    _updateTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _checkAndUpdateEvents(eventData);
    });
  }

  /// Check for repeating events that need to be updated
  Future<void> _checkAndUpdateEvents(EventData eventData) async {
    print('Checking for repeating events that need updates...');

    // Check if we need to update (to avoid unnecessary DB operations)
    if (!await _shouldRunUpdate()) {
      print('Skipping update, last update was recent');
      return;
    }

    // Update repeating events that have passed
    await eventData.updateRepeatingEvents();

    // Save the last update time
    await _saveLastUpdateTime();
  }

  /// Check if we should run an update based on last update time
  Future<bool> _shouldRunUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUpdateTime = prefs.getInt(_lastUpdateTimeKey);

    if (lastUpdateTime == null) {
      return true; // First run, should update
    }

    final lastUpdate = DateTime.fromMillisecondsSinceEpoch(lastUpdateTime);
    final now = DateTime.now();

    // Only update if at least 6 hours have passed since last update
    return now.difference(lastUpdate).inHours >= 6;
  }

  /// Save the last update time
  Future<void> _saveLastUpdateTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastUpdateTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Stop the background service
  void dispose() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }
}