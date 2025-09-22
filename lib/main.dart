import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
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

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _sb = Supabase.instance.client;
  final _text = TextEditingController();

  //  CRUD FUNCTIONS

  /// CREATE
  Future<void> _addTask() async {
    final t = _text.text.trim();
    if (t.isEmpty) return;
    await _sb.from('todos').insert({'task': t, 'is_done': false});
    _text.clear();
  }

  /// UPDATE (toggle done)
  Future<void> _toggleTask(int id, bool done) async {
    await _sb.from('todos').update({'is_done': done}).eq('id', id);
  }

  /// DELETE
  Future<void> _deleteTask(int id) async {
    await _sb.from('todos').delete().eq('id', id);
  }

  /// READ (live stream)
  Stream<List<Map<String, dynamic>>> _watchTasks() {
    return _sb
        .from('todos')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => List<Map<String, dynamic>>.from(rows));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  //  UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supabase Todo App')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _text,
                    decoration: const InputDecoration(
                      hintText: 'Add a task…',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addTask(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _addTask, child: const Text('Add')),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _watchTasks(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final todos = snap.data ?? [];
                if (todos.isEmpty) {
                  return const Center(child: Text('No todos yet'));
                }
                return ListView.separated(
                  itemCount: todos.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final t = todos[i];
                    final id = t['id'] as int;
                    final title = (t['task'] as String?) ?? '';
                    final done = (t['is_done'] as bool?) ?? false;

                    return ListTile(
                      title: Text(
                        title,
                        style: TextStyle(
                          decoration: done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      leading: Checkbox(
                        value: done,
                        onChanged: (v) => _toggleTask(id, v ?? false),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteTask(id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
