import 'package:arryuwu/menu/menu.dart';
import 'package:flutter/material.dart';
import 'package:arryuwu/Home/Screens/HomePage.dart'; // Pantalla de inicio
import 'package:arryuwu/Home/Screens/ActivityPage.dart'; // Pantalla de actividades
import 'package:arryuwu/Home/Screens/ProfilePage.dart'; // Pantalla de perfil

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // Índice actual del menú

  // Lista de widgets para cada pantalla
  final List<Widget> _screens = const [
    HomePage(), // Pantalla de inicio
    Activitypage(), // Pantalla de actividades
    ProfilePage(), // Pantalla de perfil
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex], // Cambia la pantalla según el índice seleccionado
      bottomNavigationBar: MenuScreen(
        currentIndex: _currentIndex,
        onTabChanged: (int index) {
          setState(() {
            _currentIndex = index; // Cambia el índice al seleccionar una opción
          });
        },
      ),
    );
  }
}
