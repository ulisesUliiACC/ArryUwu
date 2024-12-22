import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

class MenuScreen extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabChanged;

  const MenuScreen({
    Key? key,
    required this.currentIndex,
    required this.onTabChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: const Center(child: Text('Pantalla de menú ')),
      bottomNavigationBar: SalomonBottomBar(
        currentIndex: currentIndex,
        onTap: onTabChanged,
        items: [
          SalomonBottomBarItem(
            icon: const Icon(Icons.home),
            title: const Text('Inicio'),
            selectedColor: Colors.deepPurple,
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.search),
            title: const Text('Buscar uwu'),
            selectedColor: Colors.deepPurpleAccent,
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.account_circle),
            title: const Text('Perfil uwu'),
            selectedColor: Colors.purple,
          ),
        ],
      ),
    );
  }
}
