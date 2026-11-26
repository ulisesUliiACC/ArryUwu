import 'package:arryuwu/Home/Screens/Drawer/Drawing.dart';
import 'package:arryuwu/Home/Screens/Questions/QuestionsPage.dart';
import 'package:arryuwu/Home/Screens/Souvenirs/MyDatesPage.dart';
import 'package:flutter/material.dart';
import 'package:arryuwu/auth/ui/login_screen.dart';
import 'package:arryuwu/auth/ui/loading_screen.dart';
import 'package:arryuwu/Home/HomeScreen.dart';
import 'package:arryuwu/Home/Screens/Activity/DetailActivityPage.dart'; // Importa las pantallas
import 'package:arryuwu/colors/palette.dart'; // Importa la paleta
import 'package:arryuwu/core/navigation.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlyArry Demo',
      navigatorKey: navigatorKey, // para volver al login si la sesión expira
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Palette.primary),
        useMaterial3: true,
        primaryColor: Palette.primary,
        scaffoldBackgroundColor: Palette.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: Palette.secondary,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black, fontSize: 16),
          bodyMedium: TextStyle(color: Palette.secondary, fontSize: 14),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Palette.accent,
          selectedItemColor: Palette.primary,
          unselectedItemColor: Palette.secondary,
        ),
      ),
      initialRoute: '/', // Ruta inicial
      onGenerateRoute: _onGenerateRoute, // Usa onGenerateRoute
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (context) => const LoadingScreen(),
        );
      case '/login':
        return MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        );
      case '/home':
        return MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        );
      case '/questions':
        return MaterialPageRoute(
          builder: (context) => const QuestionsPage(),
        );
      case '/souvenirs':
        return MaterialPageRoute(
          builder: (context) => const MyDatesPage(),
        );
        case '/notas':
          return MaterialPageRoute(
            builder: (context) => DrawingBoard(),
          );
      case '/activityDetail':
        final String? title = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (context) =>
              DetailActivityPage(title: title ?? 'Actividades'),
        );
      default:
        // Manejo de rutas desconocidas (404)
        return MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(
              child: Text('404: Ruta no encontrada'),
            ),
          ),
        );
    }
  }
}
