import 'package:flutter/material.dart';

// Tema claro
final ThemeData lightTheme = ThemeData.light().copyWith(
  primaryColor: const Color(0xFF8B93E6), // Color principal
  scaffoldBackgroundColor: const Color(0xFFF2F6FF), // Fondo más claro
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFA5ACEC), // Barra de navegación clara
    titleTextStyle: TextStyle(
      color: Colors.black, // Título oscuro
      fontWeight: FontWeight.bold,
    ),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.black, fontSize: 16),
    bodyMedium:
        TextStyle(color: Color(0xFFA5ACEC), fontSize: 14), // Texto secundario
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFFBFC5F3), // Fondo de la barra inferior
    selectedItemColor: Color(0xFF8B93E6), // Icono seleccionado
    unselectedItemColor: Color(0xFFA5ACEC), // Icono no seleccionado
  ),
);

// Tema oscuro
final ThemeData darkTheme = ThemeData.dark().copyWith(
  primaryColor: const Color(0xFF8B93E6), // Color principal
  scaffoldBackgroundColor: const Color(0xFF1A1A1A), // Fondo oscuro
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1A1A1A), // Barra de navegación oscura
    titleTextStyle: TextStyle(
      color: Colors.white, // Título en blanco
      fontWeight: FontWeight.bold,
    ),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
    bodyMedium:
        TextStyle(color: Color(0xFF9F7BFF), fontSize: 14), // Texto secundario
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFF1A1A1A), // Fondo de la barra inferior
    selectedItemColor: Color(0xFF8B93E6), // Icono seleccionado
    unselectedItemColor: Color(0xFFBFC5F3), // Icono no seleccionado
  ),
);
