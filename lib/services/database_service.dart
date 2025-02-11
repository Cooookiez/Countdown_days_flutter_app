import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/event_model.dart';

class DatabaseService {
  static const String _databaseName = 'countdown_events.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String tableEvents = 'events';
  static const String tableRepeatConfigs = 'repeat_configs';

  // Singleton pattern
  DatabaseService._privateConstructor();
  static final DatabaseService instance = DatabaseService._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create events table
    await db.execute('''
      CREATE TABLE $tableEvents (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        endDate TEXT NOT NULL,
        includeTime INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        repeatConfigId TEXT,
        FOREIGN KEY (repeatConfigId) REFERENCES $tableRepeatConfigs (id)
      )
    ''');

    // Create repeat configs table
    await db.execute('''
      CREATE TABLE $tableRepeatConfigs (
        id TEXT PRIMARY KEY,
        interval INTEGER NOT NULL,
        unit TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future database migrations here
  }

  // CRUD Operations for Events
  Future<void> insertEvent(Event event) async {
    print("DB: Inserting event ${event.title}"); // Debug print
    final Database db = await database;

    // Begin transaction
    await db.transaction((txn) async {
      // Insert repeat config if exists
      if (event.repeatConfig != null) {
        await txn.insert(
          tableRepeatConfigs,
          {
            'id': event.id, // Using same ID as event for simplicity
            'interval': event.repeatConfig!.interval,
            'unit': event.repeatConfig!.unit.toString(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Insert event
      await txn.insert(
        tableEvents,
        {
          'id': event.id,
          'title': event.title,
          'description': event.description,
          'endDate': event.endDate.toIso8601String(),
          'includeTime': event.includeTime ? 1 : 0, // SQLite doesn't support boolean
          'createdAt': event.createdAt.toIso8601String(),
          'updatedAt': event.updatedAt.toIso8601String(),
          'repeatConfigId': event.repeatConfig != null ? event.id : null,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<Event?> getEvent(String id) async {
    final Database db = await database;

    final List<Map<String, dynamic>> eventMaps = await db.query(
      tableEvents,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (eventMaps.isEmpty) {
      return null;
    }

    final eventMap = eventMaps.first;
    Event event = Event.fromJson(eventMap);

    // Get repeat config if exists
    if (eventMap['repeatConfigId'] != null) {
      final List<Map<String, dynamic>> repeatConfigMaps = await db.query(
        tableRepeatConfigs,
        where: 'id = ?',
        whereArgs: [eventMap['repeatConfigId']],
      );

      if (repeatConfigMaps.isNotEmpty) {
        event = Event(
          id: event.id,
          title: event.title,
          description: event.description,
          endDate: event.endDate,
          includeTime: event.includeTime,
          repeatConfig: RepeatConfig.fromJson(repeatConfigMaps.first),
        );
      }
    }

    return event;
  }

  Future<List<Event>> getAllEvents() async {
    print("DB: Getting all events"); // Debug print
    final Database db = await database;

    final List<Map<String, dynamic>> eventMaps = await db.query(tableEvents);
    print("DB: Found ${eventMaps.length} events"); // Debug print
    final List<Event> events = [];

    for (final eventMap in eventMaps) {
      Event event = Event.fromJson(eventMap);

      // Get repeat config if exists
      if (eventMap['repeatConfigId'] != null) {
        final List<Map<String, dynamic>> repeatConfigMaps = await db.query(
          tableRepeatConfigs,
          where: 'id = ?',
          whereArgs: [eventMap['repeatConfigId']],
        );

        if (repeatConfigMaps.isNotEmpty) {
          event = Event(
            id: event.id,
            title: event.title,
            description: event.description,
            endDate: event.endDate,
            includeTime: event.includeTime,
            repeatConfig: RepeatConfig.fromJson(repeatConfigMaps.first),
          );
        }
      }

      events.add(event);
    }

    return events;
  }

  Future<void> updateEvent(Event event) async {
    final Database db = await database;

    await db.transaction((txn) async {
      // Update repeat config if exists
      if (event.repeatConfig != null) {
        await txn.update(
          tableRepeatConfigs,
          {
            'interval': event.repeatConfig!.interval,
            'unit': event.repeatConfig!.unit.toString(),
          },
          where: 'id = ?',
          whereArgs: [event.id],
        );
      }

      // Update event - remove repeatConfig from direct table update
      await txn.update(
        tableEvents,
        {
          'id': event.id,
          'title': event.title,
          'description': event.description,
          'endDate': event.endDate.toIso8601String(),
          'includeTime': event.includeTime ? 1 : 0, // Convert boolean to integer
          'createdAt': event.createdAt.toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'repeatConfigId': event.repeatConfig != null ? event.id : null,
        },
        where: 'id = ?',
        whereArgs: [event.id],
      );
    });
  }

  Future<void> deleteEvent(String id) async {
    final Database db = await database;

    await db.transaction((txn) async {
      // Delete repeat config if exists
      await txn.delete(
        tableRepeatConfigs,
        where: 'id = ?',
        whereArgs: [id],
      );

      // Delete event
      await txn.delete(
        tableEvents,
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }
}