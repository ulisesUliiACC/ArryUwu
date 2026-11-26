import 'package:flutter/material.dart';

/// Ícono dentro de un círculo con el color de la actividad muy suave de fondo.
class TintedCircle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const TintedCircle({super.key, required this.icon, required this.color, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}
