import 'package:flutter/material.dart';
import 'package:arryuwu/colors/palette.dart'; // Importa la paleta

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // Índice de navegación
  final _pageController = PageController();

  // Método para cambiar de página al seleccionar un ítem del menú
  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.jumpToPage(index); // Cambiar página en PageView
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pantalla de Inicio')),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: const [
          Center(child: Text('Página de Inicio')),
          Center(child: Text('Página de Buscar')),
          Center(child: Text('Página de Perfil')),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped, // Acción al seleccionar un ítem
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Buscar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Perfil',
          ),
        ],
        backgroundColor: Palette.accent, // Fondo de la barra inferior
        selectedItemColor: Palette.white, // Icono seleccionado
        unselectedItemColor: Palette.secondary, // Icono no seleccionado
      ),
    );
  }
}
