import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ✅ use package imports (pubspec name must be "todo_app")
import 'package:todo_app/pages/login_page.dart';
import 'package:todo_app/pages/todo_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    await dotenv.load(fileName: 'assets/env/app.env');
  }

  final url = kIsWeb
      ? const String.fromEnvironment('SUPABASE_URL')
      : (dotenv.env['SUPABASE_URL'] ?? '');
  final anonKey = kIsWeb
      ? const String.fromEnvironment('SUPABASE_ANON_KEY')
      : (dotenv.env['SUPABASE_ANON_KEY'] ?? '');

  await Supabase.initialize(url: url, anonKey: anonKey);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Supabase Todo App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // ❌ no const inside builders/home
      routes: {
        '/login': (context) => LoginPage(),
        '/todo': (context) => TodoPage(),
      },
      home: session == null ? LoginPage() : TodoPage(),
    );
  }
}
