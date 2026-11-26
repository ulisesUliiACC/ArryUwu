import 'dart:math';

import 'package:arryuwu/features/activities/data/activity.dart';
import 'package:arryuwu/ui/theme/app_tokens.dart';
import 'package:arryuwu/ui/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Abre el diálogo "Sorpréndanme": baraja las ideas como una ruleta y se detiene en una.
/// Devuelve la actividad elegida si la pareja quiere verla, o null si cierran.
Future<Activity?> showSurpriseDialog(BuildContext context) {
  return showGeneralDialog<Activity>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar',
    barrierColor: AppColors.ink.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (_, __, ___) => const _SurpriseDialog(),
    transitionBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack, reverseCurve: Curves.easeInCubic);
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(scale: Tween(begin: 0.8, end: 1.0).animate(curved), child: child),
      );
    },
  );
}

class _SurpriseDialog extends StatefulWidget {
  const _SurpriseDialog();

  @override
  State<_SurpriseDialog> createState() => _SurpriseDialogState();
}

class _SurpriseDialogState extends State<_SurpriseDialog> {
  final _random = Random();
  late Activity _current = activities[_random.nextInt(activities.length)];
  bool _landed = false;
  int _rollId = 0;

  // Cada cambio tarda un poco más que el anterior: la ruleta va frenando.
  static const _steps = [60, 60, 70, 80, 90, 110, 130, 160, 200, 260];

  @override
  void initState() {
    super.initState();
    _roll();
  }

  Future<void> _roll() async {
    final id = ++_rollId;
    setState(() => _landed = false);
    for (final ms in _steps) {
      await Future.delayed(Duration(milliseconds: ms));
      if (!mounted || id != _rollId) return;
      setState(() => _current = _next());
    }
    if (!mounted || id != _rollId) return;
    HapticFeedback.lightImpact();
    setState(() => _landed = true);
  }

  Activity _next() {
    Activity pick;
    do {
      pick = activities[_random.nextInt(activities.length)];
    } while (identical(pick, _current) && activities.length > 1);
    return pick;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final a = _current;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _landed ? '¡Su plan de hoy!' : 'Barajando ideas…',
                    style: text.labelSmall?.copyWith(color: AppColors.lavenderDeep),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AnimatedScale(
                    scale: _landed ? 1.12 : 1,
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.elasticOut,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: a.color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 140),
                        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                        child: Icon(a.icon, key: ValueKey(a.title), color: a.color, size: 44),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 140),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween(begin: const Offset(0, 0.25), end: Offset.zero).animate(anim),
                        child: child,
                      ),
                    ),
                    child: Column(
                      key: ValueKey(a.title),
                      children: [
                        Text(a.title, textAlign: TextAlign.center, style: text.titleLarge),
                        const SizedBox(height: AppSpacing.xs),
                        Text(a.subtitle, textAlign: TextAlign.center, style: text.bodyMedium),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AnimatedOpacity(
                    opacity: _landed ? 1 : 0.4,
                    duration: const Duration(milliseconds: 200),
                    child: Column(
                      children: [
                        AppPrimaryButton(
                          label: 'Ver la idea',
                          icon: Icons.favorite_rounded,
                          onPressed: _landed ? () => Navigator.of(context).pop(a) : null,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextButton.icon(
                          onPressed: _landed ? _roll : null,
                          icon: const Icon(Icons.casino_rounded),
                          label: const Text('Otra, por favor'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
