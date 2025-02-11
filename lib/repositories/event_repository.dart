import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';
import '../models/event_model.dart';

// Repository interface
abstract class EventRepository {
  Future<List<Event>> getAllEvents();
  Future<Event?> getEvent(String id);
  Future<void> saveEvent(Event event);
  Future<void> deleteEvent(String id);
}

// Implementation using Hive
class HiveEventRepository implements EventRepository {
  static const String _boxName = 'events';
  late Box<Map> _box;

  // Initialize Hive and open the box
  Future<void> initialize() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<Map>(_boxName);
  }

  @override
  Future<List<Event>> getAllEvents() async {
    final eventMaps = _box.values.toList();
    return eventMaps
        .map((eventMap) => Event.fromJson(Map<String, dynamic>.from(eventMap)))
        .toList();
  }

  @override
  Future<Event?> getEvent(String id) async {
    final eventMap = _box.get(id);
    if (eventMap == null) return null;
    return Event.fromJson(Map<String, dynamic>.from(eventMap));
  }

  @override
  Future<void> saveEvent(Event event) async {
    await _box.put(event.id, event.toJson());
  }

  @override
  Future<void> deleteEvent(String id) async {
    await _box.delete(id);
  }

  // Close the box when done
  Future<void> dispose() async {
    await _box.close();
  }
}

// Example provider for accessing events throughout the app
class EventProvider extends ChangeNotifier {
  final EventRepository _repository;
  List<Event> _events = [];

  EventProvider(this._repository) {
    _loadEvents();
  }

  List<Event> get events => _events;

  Future<void> _loadEvents() async {
    _events = await _repository.getAllEvents();
    notifyListeners();
  }

  Future<void> addEvent(Event event) async {
    await _repository.saveEvent(event);
    await _loadEvents();
  }

  Future<void> updateEvent(Event event) async {
    await _repository.saveEvent(event);
    await _loadEvents();
  }

  Future<void> deleteEvent(String id) async {
    await _repository.deleteEvent(id);
    await _loadEvents();
  }
}