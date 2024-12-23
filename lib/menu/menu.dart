import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:arryuwu/colors/palette.dart';

class MenuScreen extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabChanged;

  const MenuScreen({
    Key? key,
    required this.currentIndex,
    required this.onTabChanged,
  }) : super(key: key);

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.currentIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    widget.onTabChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    return SalomonBottomBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      items: [
        SalomonBottomBarItem(
          icon: const Icon(Icons.home),
          title: const Text("Inicio"),
          selectedColor: Palette.primary,
          unselectedColor: Palette.accent,
        ),
        SalomonBottomBarItem(
          icon: const Icon(Icons.search),
          title: const Text("Buscar"),
          selectedColor: Palette.primary,
          unselectedColor: Palette.accent,
        ),
        SalomonBottomBarItem(
          icon: const Icon(Icons.favorite),
          title: const Text("Favoritos"),
          selectedColor: Palette.primary,
          unselectedColor: Palette.accent,
        ),
        SalomonBottomBarItem(
          icon: const Icon(Icons.account_circle),
          title: const Text("Perfil"),
          selectedColor: Palette.primary,
          unselectedColor: Palette.accent,
        ),
      ],
    );
  }
}
