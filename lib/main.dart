import 'package:flutter/material.dart';
import 'package:arryuwu/auth/ui/login_screen.dart';
import 'package:arryuwu/auth/ui/loading_screen.dart';
import 'package:arryuwu/Home/HomeScreen.dart';
import 'package:arryuwu/colors/palette.dart'; // Importa la paleta

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
        colorScheme: ColorScheme.fromSeed(seedColor: Palette.primary),
        useMaterial3: true,
        primaryColor: Palette.primary,
        scaffoldBackgroundColor: Palette.background, // Fondo general más claro
        appBarTheme: const AppBarTheme(
          backgroundColor: Palette.secondary, // Barra de navegación en morado claro
          titleTextStyle: TextStyle(
            color: Colors.black, // Título en negro para buen contraste
            fontWeight: FontWeight.bold,
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black, fontSize: 16),
          bodyMedium: TextStyle(color: Palette.secondary, fontSize: 14),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Palette.accent, // Fondo de la barra inferior
          selectedItemColor: Palette.primary, // Icono seleccionado
          unselectedItemColor: Palette.secondary, // Icono no seleccionado
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoadingScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}