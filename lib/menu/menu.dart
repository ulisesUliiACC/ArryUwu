import 'package:flutter/material.dart';
import 'package:fancy_bottom_navigation/fancy_bottom_navigation.dart';

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
      body: const Center(child: Text('Pantalla de menú XD')),
      bottomNavigationBar: FancyBottomNavigation(
        initialSelection: currentIndex,
        activeIconColor: Colors.deepPurple,
        circleColor: Colors.deepPurpleAccent,
        inactiveIconColor: Colors.grey,
        textColor: Colors.deepPurple,
        barBackgroundColor: Colors.white,
        tabs: [
          TabData(
            iconData: Icons.home,
            title: 'Inicio',
          ),
          TabData(
            iconData: Icons.search,
            title: 'Buscar',
          ),
          TabData(
            iconData: Icons.account_circle,
            title: 'Perfil uwu',
          ),
        ],
        onTabChangedListener: (int position) {
          onTabChanged(position);
        },
      ),
    );
  }
}
