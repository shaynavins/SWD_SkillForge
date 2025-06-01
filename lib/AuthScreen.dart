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
  bool isLogin = true; // Toggle between login and signup

  String? errorMessage;
  bool isLoading = false;

  // Custom colors
  static const primaryColor = Color(0xFF6C63FF);
  static const secondaryColor = Color(0xFF4CAF50);
  static const backgroundColor = Color(0xFFF5F6F9);
  static const textColor = Color(0xFF2D3142);

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
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                // Logo or App Name
                const Icon(
                  Icons.school_rounded,
                  size: 80,
                  color: primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Code App',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  isLogin ? 'Welcome back!' : 'Create your account',
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                // Input Fields
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: "Email",
                          prefixIcon: const Icon(Icons.email_outlined, color: primaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: primaryColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: const Icon(Icons.lock_outline, color: primaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: primaryColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 24),
                // Primary Action Button
                ElevatedButton(
                  onPressed: isLoading ? null : () => isLogin ? login() : signup(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          isLogin ? 'Login' : 'Sign Up',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                // Toggle Button
                TextButton(
                  onPressed: () {
                    setState(() {
                      isLogin = !isLogin;
                      errorMessage = null;
                    });
                  },
                  child: Text(
                    isLogin
                        ? "Don't have an account? Sign Up"
                        : "Already have an account? Login",
                    style: const TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
