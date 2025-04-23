import 'package:countdown_days_flutter_app/models/event_data.dart';
import 'package:countdown_days_flutter_app/screens/event_list_screen.dart';
import 'package:countdown_days_flutter_app/services/background_service.dart';
import 'package:countdown_days_flutter_app/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

import 'screens/event_form_screen.dart';
import 'services/notification_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  final db = await DatabaseService.instance.database;

  // Initialize notifications
  await NotificationController.initializeLocalNotifications();
  await NotificationController.initializeIsolateReceivePort();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState() {
    super.initState();

    // Start listening for notification actions
    NotificationController.startListeningNotificationEvents();

    // Check if app was opened from a notification
    _checkForInitialNotificationAction();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Check for initial notification action
  Future<void> _checkForInitialNotificationAction() async {
    final initialAction = NotificationController.initialAction;
    if (initialAction != null) {
      // Small delay to ensure the app is fully initialized
      Future.delayed(Duration(milliseconds: 500), () {
        NotificationController.onActionReceivedImplementationMethod(initialAction);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => EventData(),
      child: MaterialApp(
        title: 'Countdown Days',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        initialRoute: EventListScreen.id,
        routes: {
          EventListScreen.id: (context) => EventListScreen(),
          EventFormScreen.id: (context) => EventFormScreen(),
        },
      ),
    );
  }
}
