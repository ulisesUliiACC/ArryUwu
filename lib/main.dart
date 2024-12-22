import 'package:flutter/material.dart';
import 'package:arryuwu/auth/ui/login_screen.dart'; // Import LoginPage
import 'package:arryuwu/auth/ui/loading_screen.dart';
import 'package:arryuwu/Home/HomeScreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Set initial route to '/login' to show LoginPage first
      initialRoute: '/',
      routes: {
        '/': (context) => const LoadingScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        // // Add other routes for different screens here (optional)
      },
    );
  }
}
