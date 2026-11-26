import 'package:flutter/material.dart';

/// Permite navegar fuera de un BuildContext (p. ej. mandar al login cuando la sesión expira).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void goToLogin() {
  navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
}
