import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import '../colors/palette.dart';

class MenuScreen extends StatefulWidget {
  final int initialIndex;
  final Function(int) onTabChanged;

  const MenuScreen({
    Key? key,
    required this.initialIndex,
    required this.onTabChanged, required int currentIndex,
  }) : super(key: key);

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    widget.onTabChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (child, animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: Center(
          key: ValueKey<int>(_currentIndex),
          child: Text(
            'Pantalla ${_currentIndex + 1}',
            style: const TextStyle(
              fontSize: 24,
              color: Palette.primary,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
      bottomNavigationBar: SalomonBottomBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          _controller.reverse().then((_) {
            _controller.forward();
            _onTabTapped(index);
          });
        },
        backgroundColor: Palette.primary,
        items: [
          SalomonBottomBarItem(
            icon: AnimatedScale(
              scale: _currentIndex == 0 ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: const Icon(
                Icons.home,
                color: Palette.white,
              ),
            ),
            title: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                'Inicio',
                key: ValueKey<bool>(_currentIndex == 0),
                style: TextStyle(
                  color: Palette.white,
                  fontWeight:
                      _currentIndex == 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            selectedColor: Palette.white,
            unselectedColor: Palette.white,
          ),
          SalomonBottomBarItem(
            icon: AnimatedScale(
              scale: _currentIndex == 1 ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: const Icon(
                Icons.search,
                color: Palette.white,
              ),
            ),
            title: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                'Buscar',
                key: ValueKey<bool>(_currentIndex == 1),
                style: TextStyle(
                  color: Palette.white,
                  fontWeight:
                      _currentIndex == 1 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            selectedColor: Palette.white,
            unselectedColor: Palette.white,
          ),
          SalomonBottomBarItem(
            icon: AnimatedScale(
              scale: _currentIndex == 2 ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: const Icon(
                Icons.person,
                color: Palette.white,
              ),
            ),
            title: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                'Perfil',
                key: ValueKey<bool>(_currentIndex == 2),
                style: TextStyle(
                  color: Palette.white,
                  fontWeight:
                      _currentIndex == 2 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            selectedColor: Palette.white,
            unselectedColor: Palette.white,
          ),
        ],
      ),
    );
  }
}
