import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import 'event_model.dart';

class EventData extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  List<Event> _events = [];

  List<Event> get events => _events;

  // Load all events from database
  Future<void> loadEvents() async {
    print("Loading events..."); // Debug print
    _events = await _db.getAllEvents();
    print("Loaded events: ${_events.length}"); // Debug print
    notifyListeners();
  }

  // Add new event
  Future<void> addEvent(Event event) async {
    print("Adding event: ${event.title}"); // Debug print
    await _db.insertEvent(event);
    _events.add(event);
    print("Events after add: ${_events.length}"); // Debug print
    notifyListeners();
  }

  // Update existing event
  Future<void> updateEvent(Event event) async {
    await _db.updateEvent(event);
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _events[index] = event;
      notifyListeners();
    }
  }

  // Delete event
  Future<void> deleteEvent(String id) async {
    await _db.deleteEvent(id);
    _events.removeWhere((event) => event.id == id);
    notifyListeners();
  }

  // Get single event
  Future<Event?> getEvent(String id) async {
    return await _db.getEvent(id);
  }
}