import 'package:arryuwu/auth/data/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  // Tiempo mínimo que se muestra la animación
  static const _minDuration = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _decideRoute();
  }

  /// Si ya hay sesión guardada entra directo al Home; si no, al login.
  Future<void> _decideRoute() async {
    final results = await Future.wait([
      AuthService.hasSession(),
      Future.delayed(_minDuration, () => null),
    ]);
    if (!mounted) return;
    final loggedIn = results.first == true;
    Navigator.pushReplacementNamed(context, loggedIn ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Lottie.asset(
          'assets/lottie/loading_animation.json',
          width: 300,
          height: 300,
          fit: BoxFit.fill,
        ),
      ),
    );
  }
}
