import 'package:codeapp/AuthScreen.dart' hide HomeScreen;
import 'package:codeapp/DiscussionPage.dart';
import 'package:codeapp/HomeScreen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:codeapp/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: 'https://nkcltlgzkajpaorloevb.supabase.co', anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5rY2x0bGd6a2FqcGFvcmxvZXZiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc4MjY4MTcsImV4cCI6MjA2MzQwMjgxN30.kQY3lzsTHplU9z75fixDQN186vHGeGDDlMTmH_-tWns');
  runApp(const MainApp());
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthScreen(),
        '/home': (context) => const HomeScreen(),
        '/discussion': (context) => const DiscussionPage(),
      },
    );
  }
}
