import 'package:flutter/material.dart';

import 'pressable.dart';

/// Botón principal de cada pantalla: ancho completo, con estado de carga.
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final child = AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: loading
          ? const SizedBox(
              key: ValueKey('loading'),
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
                Text(label),
              ],
            ),
    );
    return Pressable(
      enabled: onPressed != null && !loading,
      child: FilledButton(onPressed: loading ? null : onPressed, child: child),
    );
  }
}

/// Botón secundario (borde lavanda).
class AppSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const AppSecondaryButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      enabled: onPressed != null,
      child: OutlinedButton(onPressed: onPressed, child: Text(label)),
    );
  }
}
