import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screens/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Supabase Connection
  await Supabase.initialize(
    url: 'https://ysbbeizoxbwwcwcllycn.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlzYmJlaXpveGJ3d2N3Y2xseWNuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ0NzQwOTMsImV4cCI6MjEwMDA1MDA5M30.7T_XcfSgyVTh4qzMq0g-Yl2tSRlqKe5dr8PaKa3p1Ww',
  );

  // 2. Initialize FFI for local SQLite desktop storage
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // 3. Initialize desktop sizing configurations
  await windowManager.ensureInitialized();
  windowManager.waitUntilReadyToShow().then((_) async {
    // Hide window title bar

    // Set window constraints, maximize it instantly, and open full screen
    await windowManager.focus(); // Fills up the desktop monitor area
    await windowManager.setFullScreen(
      true,
    ); // Enforces absolute full screen overlay mode
    await windowManager.show();
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.light, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}
