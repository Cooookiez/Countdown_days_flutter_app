import 'package:countdown_days_flutter_app/models/event_data.dart';
import 'package:countdown_days_flutter_app/screens/event_list_screen.dart';
import 'package:countdown_days_flutter_app/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

import 'screens/event_form_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await DatabaseService.instance.database;
  print("Database initialized: ${await db.getVersion()}"); // Debug print
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
