import 'package:erpflutter/erp_core/access_control/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Add this import

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _login() async {
    final auth = context.read<AuthService>();
    await auth.login(
      _emailController.text,
      _passwordController.text,
    );
    Navigator.pushReplacementNamed(context, '/folders');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
            ElevatedButton(onPressed: _login, child: const Text('Sign In')),
          ],
        ),
      ),
    );
  }
}