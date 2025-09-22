import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final _sb = Supabase.instance.client;
  final _taskController = TextEditingController();

  Future<void> _addTask() async {
    final task = _taskController.text.trim();
    if (task.isEmpty) return;

    try {
      // If you set default auth.uid() in SQL, you can omit user_id here.
      await _sb.from('todos').insert({
        'task': task,
        'is_done': false,
        'user_id': _sb.auth.currentUser!.id,
      });
      _taskController.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding task: $e')));
    }
  }

  Future<void> _toggleTask(int id, bool isDone) async {
    try {
      await _sb.from('todos').update({'is_done': isDone}).eq('id', id);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating task: $e')));
    }
  }

  Future<void> _deleteTask(int id) async {
    try {
      await _sb.from('todos').delete().eq('id', id);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting task: $e')));
    }
  }

  Stream<List<Map<String, dynamic>>> _watchTasks() {
    final userId = _sb.auth.currentUser!.id;
    return _sb
        .from('todos')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Todos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _sb.auth.signOut();
              if (mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    decoration: const InputDecoration(
                      hintText: 'Add a new task...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addTask(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(onPressed: _addTask, child: const Text('Add')),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _watchTasks(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final todos = snapshot.data ?? [];
                if (todos.isEmpty) {
                  return const Center(
                    child: Text('No todos yet. Add one above!'),
                  );
                }

                return ListView.builder(
                  itemCount: todos.length,
                  itemBuilder: (context, index) {
                    final todo = todos[index];
                    final id = todo['id'] as int;
                    final task = (todo['task'] as String?) ?? '';
                    final isDone = (todo['is_done'] as bool?) ?? false;

                    return ListTile(
                      leading: Checkbox(
                        value: isDone,
                        onChanged: (v) => _toggleTask(id, v ?? false),
                      ),
                      title: Text(
                        task,
                        style: TextStyle(
                          decoration: isDone
                              ? TextDecoration.lineThrough
                              : null,
                        ),
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
