import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../theme/app_tokens.dart';

/// Mensaje centrado para estados vacíos o de error, con Lottie y acción opcionales.
class AppMessageView extends StatelessWidget {
  final String? lottie;
  final IconData? icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const AppMessageView({
    super.key,
    this.lottie,
    this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (lottie != null) Lottie.asset(lottie!, width: 140),
            if (icon != null) Icon(icon, size: 56, color: AppColors.lavender),
            const SizedBox(height: AppSpacing.lg),
            Text(title, textAlign: TextAlign.center, style: text.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(subtitle, textAlign: TextAlign.center, style: text.bodyMedium),
            if (action != null) ...[const SizedBox(height: AppSpacing.lg), action!],
          ],
        ),
      ),
    );
  }
}

/// Carga con la animación de la marca.
class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key});

  @override
  Widget build(BuildContext context) =>
      Center(child: Lottie.asset('assets/lottie/loading_animation.json', width: 140));
}

/// Snackbars con el estilo de Arry.
void showAppSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.error : AppColors.ink,
    ));
}
