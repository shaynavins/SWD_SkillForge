import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String? errorMessage;
  bool isLoading = false;

  Future<void> login() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final email = 'testuser@example.com';     // <-- hardcoded
    final password = 'Test1234!';             // <-- hardcoded

    print('Attempting login for email: $email');

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = 'Email and password cannot be empty.';
        isLoading = false;
      });
      return;
    }

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      print('Login response: $response');

      if (response.session != null) {
        // Navigate to home screen on successful login
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          errorMessage = 'Login failed: Check your credentials.';
        });
      }
    } catch (e) {
      print('Login error: $e');
      setState(() {
        errorMessage = 'Login error: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

    bool isValidEmail(String email) {
      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
      return emailRegex.hasMatch(email);
    }
  
    Future<void> signup() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final email = 'testuser@example.com';     // <-- hardcoded
    final password = 'Test1234!';             // <-- hardcoded

    print('Attempting signup for email: "$email"');
    print('Email code units: ${email.codeUnits}');

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = 'Email and password cannot be empty.';
        isLoading = false;
      });
      return;
    }

    if (!isValidEmail(email)) {
      setState(() {
        errorMessage = 'Please enter a valid email address.';
        isLoading = false;
      });
      return;
    }

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );
      print('Signup response: $response');

      if (response.user != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signup successful! Please log in.')),
        );
      } else {
        setState(() {
          errorMessage = 'Signup failed.';
        });
      }
    } catch (e) {
      print('Signup error: $e');
      setState(() {
        errorMessage = 'Signup error: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login / Signup")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            if (errorMessage != null)
              Text(errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading ? null : () => login(),
              child: isLoading ? const CircularProgressIndicator() : const Text('Login'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () => signup(),
              child: isLoading ? const CircularProgressIndicator() : const Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
