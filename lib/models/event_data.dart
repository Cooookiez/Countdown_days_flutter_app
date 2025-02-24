import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import 'event_model.dart';

enum EventSortType {
  dateAscending,
  dateDescending,
  titleAscending,
  titleDescending,
  createdAtNewest,
  createdAtOldest
}

class EventData extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final NotificationService _notificationService = NotificationService();
  List<Event> _events = [];
  EventSortType _currentSort = EventSortType.dateAscending;

  // Getters
  List<Event> get events => _events;
  EventSortType get currentSort => _currentSort;

  // Sorted events getter
  List<Event> get sortedEvents {
    final sorted = List<Event>.from(_events);

    switch (_currentSort) {
      case EventSortType.dateAscending:
        sorted.sort((a, b) => a.endDate.compareTo(b.endDate));
      case EventSortType.dateDescending:
        sorted.sort((a, b) => b.endDate.compareTo(a.endDate));
      case EventSortType.titleAscending:
        sorted.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case EventSortType.titleDescending:
        sorted.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
      case EventSortType.createdAtNewest:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case EventSortType.createdAtOldest:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    return sorted;
  }

  /// Load all events from database
  Future<void> loadEvents() async {
    print("Loading events..."); // Debug print
    _events = await _db.getAllEvents();
    print("Loaded events: ${_events.length}"); // Debug print

    // Reschedule all notifications for loaded events
    for (final event in _events) {
      if (event.allowNotifications && event.notifications.isNotEmpty) {
        await _notificationService.scheduleEventNotifications(event);
      }
    }

    notifyListeners();
  }

  /// Add new event
  Future<void> addEvent(Event event) async {
    print("Adding event: ${event.title}"); // Debug print
    await _db.insertEvent(event);
    _events.add(event);
    print("Events after add: ${_events.length}"); // Debug print

    // Schedule notifications for the new event
    if (event.allowNotifications && event.notifications.isNotEmpty) {
      await _notificationService.scheduleEventNotifications(event);
    }

    notifyListeners();
  }

  /// Update existing event
  Future<void> updateEvent(Event event) async {
    await _db.updateEvent(event);
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _events[index] = event;

      // Cancel old notifications and schedule new ones
      await _notificationService.cancelEventNotifications(event.id);
      if (event.allowNotifications && event.notifications.isNotEmpty) {
        await _notificationService.scheduleEventNotifications(event);
      }

      notifyListeners();
    }
  }

  /// Delete event
  Future<void> deleteEvent(String id) async {
    await _db.deleteEvent(id);

    // Cancel notifications for the deleted event
    await _notificationService.cancelEventNotifications(id);

    _events.removeWhere((event) => event.id == id);
    notifyListeners();
  }

  /// Get single event
  Future<Event?> getEvent(String id) async {
    return await _db.getEvent(id);
  }

  /// Change sort type
  void setSortType(EventSortType type) {
    _currentSort = type;
    notifyListeners();
  }
}