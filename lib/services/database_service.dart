import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/event_model.dart';

class DatabaseService {
  static const String _databaseName = 'countdown_events.db';
  static const int _databaseVersion = 2;

  // Table names
  static const String tableEvents = 'events';
  static const String tableRepeatConfigs = 'repeat_configs';
  static const String tableNotifications = 'notifications';

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
      isRepeating INTEGER NOT NULL DEFAULT 0,
      allowNotifications INTEGER NOT NULL DEFAULT 0,
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

    // Create notifications table
    await db.execute('''
    CREATE TABLE $tableNotifications (
      id TEXT PRIMARY KEY,
      eventId TEXT NOT NULL,
      amount INTEGER NOT NULL,
      unit TEXT NOT NULL,
      isEnabled INTEGER NOT NULL DEFAULT 1,
      FOREIGN KEY (eventId) REFERENCES $tableEvents (id)
    )
  ''');
  }

  // CRUD Operations for Events
  Future<void> insertEvent(Event event) async {
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
          'includeTime': event.includeTime ? 1 : 0,
          'isRepeating': event.isRepeating ? 1 : 0,
          'allowNotifications': event.allowNotifications ? 1 : 0,
          'createdAt': event.createdAt.toIso8601String(),
          'updatedAt': event.updatedAt.toIso8601String(),
          'repeatConfigId': event.repeatConfig != null ? event.id : null,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insert notifications if any
      if (event.allowNotifications && event.notifications.isNotEmpty) {
        for (var notification in event.notifications) {
          await txn.insert(
            tableNotifications,
            {
              'id': notification.id,
              'eventId': event.id,
              'amount': notification.amount,
              'unit': notification.unit.toString(),
              'isEnabled': notification.isEnabled ? 1 : 0,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
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
        event.isRepeating = true;
        event.repeatConfig = RepeatConfig.fromJson(repeatConfigMaps.first);
      }
    }

    // Get notifications for this event
    final List<Map<String, dynamic>> notificationMaps = await db.query(
      tableNotifications,
      where: 'eventId = ?',
      whereArgs: [id],
    );

    if (notificationMaps.isNotEmpty) {
      event.allowNotifications = true;
      event.notifications = notificationMaps.map((map) =>
          NotificationConfig(
            id: map['id'],
            amount: map['amount'],
            unit: FrequencyUnit.values.firstWhere(
                  (e) => e.toString() == map['unit'],
            ),
            isEnabled: map['isEnabled'] == 1,
          )
      ).toList();
    }

    return event;
  }

  Future<List<Event>> getAllEvents() async {
    final Database db = await database;

    final List<Map<String, dynamic>> eventMaps = await db.query(tableEvents);
    final List<Event> events = [];

    for (final eventMap in eventMaps) {
      Event event = Event.fromJson(eventMap);

      // Set isRepeating and allowNotifications from DB values
      event = Event(
        id: event.id,
        title: event.title,
        description: event.description,
        endDate: event.endDate,
        includeTime: event.includeTime,
        isRepeating: eventMap['isRepeating'] == 1,
        allowNotifications: eventMap['allowNotifications'] == 1,
      )
        ..createdAt = event.createdAt
        ..updatedAt = event.updatedAt;

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
            isRepeating: true,
            repeatConfig: RepeatConfig.fromJson(repeatConfigMaps.first),
            allowNotifications: event.allowNotifications,
          );
        }
      }

      // Get notifications for this event
      final List<Map<String, dynamic>> notificationMaps = await db.query(
        tableNotifications,
        where: 'eventId = ?',
        whereArgs: [event.id],
      );

      if (notificationMaps.isNotEmpty) {
        List<NotificationConfig> notifications = notificationMaps.map((map) =>
            NotificationConfig(
              id: map['id'],
              amount: map['amount'],
              unit: FrequencyUnit.values.firstWhere(
                    (e) => e.toString() == map['unit'],
              ),
              isEnabled: map['isEnabled'] == 1,
            )
        ).toList();

        event = Event(
          id: event.id,
          title: event.title,
          description: event.description,
          endDate: event.endDate,
          includeTime: event.includeTime,
          isRepeating: event.isRepeating,
          repeatConfig: event.repeatConfig,
          allowNotifications: true,
          notifications: notifications,
        )
          ..createdAt = event.createdAt
          ..updatedAt = event.updatedAt;
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
        await txn.insert(
          tableRepeatConfigs,
          {
            'id': event.id,
            'interval': event.repeatConfig!.interval,
            'unit': event.repeatConfig!.unit.toString(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } else {
        // Delete any existing repeat config if no longer used
        await txn.delete(
          tableRepeatConfigs,
          where: 'id = ?',
          whereArgs: [event.id],
        );
      }

      // Update event
      await txn.update(
        tableEvents,
        {
          'title': event.title,
          'description': event.description,
          'endDate': event.endDate.toIso8601String(),
          'includeTime': event.includeTime ? 1 : 0,
          'isRepeating': event.isRepeating ? 1 : 0,  // Add this
          'allowNotifications': event.allowNotifications ? 1 : 0,  // Add this
          'updatedAt': DateTime.now().toIso8601String(),
          'repeatConfigId': event.repeatConfig != null ? event.id : null,
        },
        where: 'id = ?',
        whereArgs: [event.id],
      );

      // First delete all existing notifications
      await txn.delete(
        tableNotifications,
        where: 'eventId = ?',
        whereArgs: [event.id],
      );

      // Then insert current notifications if any
      if (event.allowNotifications && event.notifications.isNotEmpty) {
        for (var notification in event.notifications) {
          await txn.insert(
            tableNotifications,
            {
              'id': notification.id,
              'eventId': event.id,
              'amount': notification.amount,
              'unit': notification.unit.toString(),
              'isEnabled': notification.isEnabled ? 1 : 0,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }

  Future<void> deleteEvent(String id) async {
    final Database db = await database;

    await db.transaction((txn) async {
      // Delete notifications
      await txn.delete(
        tableNotifications,
        where: 'eventId = ?',
        whereArgs: [id],
      );

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

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add missing columns to events table
      await db.execute('ALTER TABLE $tableEvents ADD COLUMN isRepeating INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE $tableEvents ADD COLUMN allowNotifications INTEGER NOT NULL DEFAULT 0');

      // Create notifications table
      await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableNotifications (
        id TEXT PRIMARY KEY,
        eventId TEXT NOT NULL,
        amount INTEGER NOT NULL,
        unit TEXT NOT NULL,
        isEnabled INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (eventId) REFERENCES $tableEvents (id)
      )
    ''');
    }
  }
}