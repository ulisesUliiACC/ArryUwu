import 'package:arryuwu/features/activities/data/activity.dart';
import 'package:arryuwu/features/activities/ui/widgets/tinted_circle.dart';
import 'package:arryuwu/ui/theme/app_tokens.dart';
import 'package:arryuwu/ui/widgets/app_button.dart';
import 'package:arryuwu/ui/widgets/entrance.dart';
import 'package:arryuwu/ui/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Detalle de una idea de cita: descripción, ideas para hacerla especial y la acción de guardarla como recuerdo.
class ActivityDetailPage extends StatefulWidget {
  final String title;

  const ActivityDetailPage({super.key, required this.title});

  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
  late final Activity _activity = Activity.byTitle(widget.title);
  final Set<int> _done = {};

  void _toggle(int i) {
    HapticFeedback.selectionClick();
    setState(() => _done.contains(i) ? _done.remove(i) : _done.add(i));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final a = _activity;

    return Scaffold(
      appBar: AppBar(title: const Text('Idea de cita')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
        children: [
          // Encabezado de la actividad
          Entrance(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                boxShadow: AppSpacing.softShadow,
              ),
              child: Column(
                children: [
                  TintedCircle(icon: a.icon, color: a.color, size: 88),
                  const SizedBox(height: AppSpacing.lg),
                  Text(a.title, textAlign: TextAlign.center, style: text.headlineMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(a.subtitle, textAlign: TextAlign.center, style: text.bodyMedium),
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _InfoChip(icon: a.category.icon, label: a.category.label),
                      _InfoChip(icon: Icons.schedule_rounded, label: a.duration),
                      _InfoChip(icon: Icons.payments_outlined, label: a.cost),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          Entrance(index: 1, child: Text('De qué se trata', style: text.titleLarge)),
          const SizedBox(height: AppSpacing.sm),
          Entrance(index: 2, child: Text(a.description, style: text.bodyLarge)),
          const SizedBox(height: AppSpacing.xl),

          Entrance(
            index: 3,
            child: Row(
              children: [
                Expanded(child: Text('Para hacerlo especial', style: text.titleLarge)),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    '${_done.length}/${a.ideas.length}',
                    key: ValueKey(_done.length),
                    style: text.labelSmall?.copyWith(color: AppColors.lavenderDeep),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < a.ideas.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Entrance(
                index: 4 + i,
                child: _IdeaTile(label: a.ideas[i], done: _done.contains(i), onTap: () => _toggle(i)),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
          child: AppPrimaryButton(
            label: '¡Lo hicimos! Guardar recuerdo',
            icon: Icons.add_a_photo_rounded,
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push('/memories');
            },
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.lavenderSoft,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.lavenderDeep),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.lavenderDeep)),
        ],
      ),
    );
  }
}

/// Una idea que la pareja puede ir palomeando.
class _IdeaTile extends StatelessWidget {
  final String label;
  final bool done;
  final VoidCallback onTap;

  const _IdeaTile({required this.label, required this.done, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(AppSpacing.radiusMd);
    return Semantics(
      checked: done,
      child: Pressable(
        pressedScale: 0.98,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: done ? AppColors.lavenderSoft : AppColors.surface,
            borderRadius: radius,
            boxShadow: done ? null : AppSpacing.softShadow,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  child: Row(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                        child: Icon(
                          done ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          key: ValueKey(done),
                          color: done ? AppColors.pinkDeep : AppColors.inkMuted,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          label,
                          style: text.bodyLarge?.copyWith(
                            color: done ? AppColors.inkMuted : AppColors.ink,
                            decoration: done ? TextDecoration.lineThrough : null,
                            decorationColor: AppColors.inkMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
