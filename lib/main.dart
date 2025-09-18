import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    // Load .env only for mobile/desktop
    await dotenv.load(fileName: 'assets/env/app.env');
  }

  final url = kIsWeb
      ? const String.fromEnvironment('SUPABASE_URL')
      : dotenv.env['SUPABASE_URL']!;
  final anonKey = kIsWeb
      ? const String.fromEnvironment('SUPABASE_ANON_KEY')
      : dotenv.env['SUPABASE_ANON_KEY']!;

  await Supabase.initialize(url: url, anonKey: anonKey);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Supabase Todo App")),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final supabase = Supabase.instance.client;

            // Test: fetch all todos
            final response = await supabase.from('todos').select();
            debugPrint("Todos: $response");
          },
          child: const Text("Fetch Todos"),
        ),
      ),
    );
  }
}
