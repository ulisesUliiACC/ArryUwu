import 'package:flutter/material.dart';
import 'package:arryuwu/menu/menu.dart';
import 'package:arryuwu/colors/palette.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const Center(child: Text("Página de Inicio", style: TextStyle(fontSize: 24))),
    const Center(child: Text("Página de Buscar", style: TextStyle(fontSize: 24))),
    const Center(child: Text("Página de Favoritos", style: TextStyle(fontSize: 24))),
    const Center(child: Text("Página de Perfil", style: TextStyle(fontSize: 24))),
  ];

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getTitle(),
          style: const TextStyle(color: Palette.primary),
        ),
        centerTitle: true,
        backgroundColor: Palette.white,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: MenuScreen(
        currentIndex: _currentIndex,
        onTabChanged: _onTabChanged,
      ),
    );
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return "Inicio";
      case 1:
        return "Buscar";
      case 2:
        return "Favoritos";
      case 3:
        return "Perfil";
      default:
        return "";
    }
  }
}
