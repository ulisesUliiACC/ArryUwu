import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:arryuwu/colors/palette.dart'; // Paleta de colores

class MenuScreen extends StatelessWidget {
  final Function(int) onTabChanged;
  final int currentIndex;

  const MenuScreen({
    Key? key,
    required this.onTabChanged,
    required this.currentIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SalomonBottomBar(
      currentIndex: currentIndex, // Mostramos el índice activo
      onTap: onTabChanged, // Acción al cambiar de pestaña
      items: [
        SalomonBottomBarItem(
          icon: const Icon(Icons.home),
          title: const Text("Inicio"),
          selectedColor: Palette.primary,
          unselectedColor: Palette.secondary,
        ),
        SalomonBottomBarItem(
          icon: const Icon(Icons.search),
          title: const Text("Actividades"),
          selectedColor: Palette.pinkAccent,
          unselectedColor: Palette.secondary,
        ),
        SalomonBottomBarItem(
          icon: const Icon(Icons.notifications),
          title: const Text("Notificaciones"),
          selectedColor: Palette.primary,
          unselectedColor: Palette.secondary,
        ),
        SalomonBottomBarItem(
          icon: const Icon(Icons.account_circle),
          title: const Text("Perfil"),
          selectedColor: Palette.primary,
          unselectedColor: Palette.secondary,
        ),
      ],
    );
  }
}
