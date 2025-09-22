import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'todo_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 1) grab a handle to Supabase
  final _sb = Supabase.instance.client;

  // 2) inputs + simple loading state
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  // 3) tiny helper to show messages
  void _show(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  // 4) login with email/password
  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      final res = await _sb.auth.signInWithPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );
      if (res.user != null && mounted) {
        // go to the todo screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => TodoPage()),
        );
      }
    } on AuthException catch (e) {
      _show(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // 5) create an account (email/password)
  Future<void> _signup() async {
    setState(() => _loading = true);
    try {
      final res = await _sb.auth.signUp(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );
      if (res.user != null) {
        _show('Signed up! (If email confirmation is ON, check your inbox.)');
      }
    } on AuthException catch (e) {
      _show(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login / Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _login,
              child: const Text('Login'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _loading ? null : _signup,
              child: const Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
