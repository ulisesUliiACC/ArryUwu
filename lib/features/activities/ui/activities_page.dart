import 'package:arryuwu/features/activities/data/activity.dart';
import 'package:arryuwu/features/activities/ui/widgets/surprise_dialog.dart';
import 'package:arryuwu/features/activities/ui/widgets/tinted_circle.dart';
import 'package:arryuwu/ui/theme/app_tokens.dart';
import 'package:arryuwu/ui/widgets/entrance.dart';
import 'package:arryuwu/ui/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Pestaña "Juntos": ideas de citas, accesos rápidos y el botón "Sorpréndanme".
class ActivitiesPage extends StatefulWidget {
  const ActivitiesPage({super.key});

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage> {
  ActivityCategory? _filter;

  Future<void> _surprise() async {
    final picked = await showSurpriseDialog(context);
    if (picked != null && mounted) context.push('/activity', extra: picked.title);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final visible = _filter == null ? activities : activities.where((a) => a.category == _filter).toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
          children: [
            // Encabezado
            Entrance(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Juntos', style: text.headlineMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Ideas para su próxima cita y cosas para hacer en pareja.', style: text.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            Entrance(index: 1, child: _SurpriseBanner(onTap: _surprise)),
            const SizedBox(height: AppSpacing.xl),

            // Accesos rápidos
            Entrance(index: 2, child: Text('Para ustedes', style: text.titleLarge)),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _Shortcut(
                    index: 3,
                    icon: Icons.forum_rounded,
                    color: AppColors.lavenderDeep,
                    label: 'Preguntas',
                    onTap: () => context.push('/questions'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _Shortcut(
                    index: 4,
                    icon: Icons.photo_library_rounded,
                    color: AppColors.pinkDeep,
                    label: 'Recuerdos',
                    onTap: () => context.push('/memories'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _Shortcut(
                    index: 5,
                    icon: Icons.brush_rounded,
                    color: AppColors.success,
                    label: 'Lienzo',
                    onTap: () => context.push('/notes'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Ideas de citas
            Entrance(index: 6, child: Text('Ideas de citas', style: text.titleLarge)),
            const SizedBox(height: AppSpacing.md),
            Entrance(
              index: 7,
              child: SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  children: [
                    _CategoryChip(
                      label: 'Todas',
                      icon: Icons.favorite_rounded,
                      selected: _filter == null,
                      onTap: () => setState(() => _filter = null),
                    ),
                    for (final c in ActivityCategory.values)
                      _CategoryChip(
                        label: c.label,
                        icon: c.icon,
                        selected: _filter == c,
                        onTap: () => setState(() => _filter = _filter == c ? null : c),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (var i = 0; i < visible.length; i++)
              Padding(
                // La llave cambia con el filtro para que las tarjetas vuelvan a aparecer escalonadas.
                key: ValueKey('${_filter?.name}-${visible[i].title}'),
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Entrance(
                  index: 8 + i,
                  child: _ActivityCard(
                    activity: visible[i],
                    onTap: () => context.push('/activity', extra: visible[i].title),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta destacada con degradado y el botón "Sorpréndanme".
class _SurpriseBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _SurpriseBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.lavenderDeep, AppColors.pinkDeep],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppSpacing.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text('¿No saben qué hacer hoy?', style: text.titleLarge?.copyWith(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Dejen que Arry elija una idea al azar para ustedes.',
            style: text.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.92)),
          ),
          const SizedBox(height: AppSpacing.lg),
          Pressable(
            child: FilledButton.icon(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.lavenderDeep,
                minimumSize: const Size(0, 48),
              ),
              icon: const Icon(Icons.casino_rounded),
              label: const Text('Sorpréndanme'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Acceso a otra sección (Preguntas, Recuerdos, Lienzo).
class _Shortcut extends StatelessWidget {
  final int index;
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _Shortcut({
    required this.index,
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Entrance(
      index: index,
      child: Semantics(
        button: true,
        label: 'Abrir $label',
        excludeSemantics: true,
        child: Pressable(
          child: _SoftCard(
            onTap: onTap,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.sm),
            child: Column(
              children: [
                TintedCircle(icon: icon, color: color, size: 48),
                const SizedBox(height: AppSpacing.sm),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label, maxLines: 1, style: Theme.of(context).textTheme.titleMedium),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final fg = selected ? AppColors.lavenderDeep : AppColors.inkMuted;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Semantics(
        selected: selected,
        button: true,
        child: Pressable(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: selected ? AppColors.lavenderSoft : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: selected ? AppColors.lavenderDeep : AppColors.lavenderSoft),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18, color: fg),
                    const SizedBox(width: AppSpacing.xs),
                    Text(label, style: text.labelLarge?.copyWith(color: fg, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Activity activity;
  final VoidCallback onTap;

  const _ActivityCard({required this.activity, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final a = activity;
    return Pressable(
      pressedScale: 0.98,
      child: _SoftCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            TintedCircle(icon: a.icon, color: a.color),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.title, style: text.titleMedium),
                  const SizedBox(height: 2),
                  Text(a.subtitle, style: text.bodyMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _Tag(icon: Icons.schedule_rounded, label: a.duration),
                      _Tag(icon: Icons.payments_outlined, label: a.cost),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta blanca con sombra suave y efecto de tinta al tocarla.
class _SoftCard extends StatelessWidget {
  final VoidCallback onTap;
  final EdgeInsets padding;
  final Widget child;

  const _SoftCard({required this.onTap, required this.padding, required this.child});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSpacing.radiusMd);
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: radius, boxShadow: AppSpacing.softShadow),
      child: Material(
        color: AppColors.surface,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Tag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.inkMuted),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
