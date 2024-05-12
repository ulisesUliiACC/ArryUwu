import 'package:flutter/material.dart';
import 'package:arryuwu/auth/ui/login_screen.dart'; // Import LoginPage


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
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        // Add other routes for different screens here (optional)
      },
    );
  }


}
