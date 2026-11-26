import 'package:flutter/material.dart';

/// Colores de Arry (ver skill arry-design-system). Las pantallas usan estos tokens, no Color(0x…) sueltos.
class AppColors {
  static const lavender = Color(0xFF8B93E6); // marca, decorativo (no para texto)
  static const lavenderDeep = Color(0xFF755DC1); // botones, enlaces, foco
  static const lavenderSoft = Color(0xFFD8DDF9); // chips, fondos suaves
  static const pink = Color(0xFFFAACD8); // acentos románticos (no para texto)
  static const pinkDeep = Color(0xFFC2185B); // acciones de pareja, texto rosa
  static const background = Color(0xFFF2F6FF);
  static const surface = Colors.white;
  static const ink = Color(0xFF2B2840);
  static const inkMuted = Color(0xFF6B6880);
  static const error = Color(0xFFC62828);
  static const success = Color(0xFF2E7D32);
}

/// Espaciado en múltiplos de 4 y radios.
class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  static const radiusSm = 12.0;
  static const radiusMd = 16.0;
  static const radiusLg = 24.0;

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: AppColors.lavenderDeep.withValues(alpha: 0.12),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];
}
