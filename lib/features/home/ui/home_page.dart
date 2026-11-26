import 'package:arryuwu/features/home/data/me.dart';
import 'package:arryuwu/features/memories/data/memory.dart';
import 'package:arryuwu/features/memories/data/memory_service.dart';
import 'package:arryuwu/features/memories/ui/auth_image.dart';
import 'package:arryuwu/features/profile/ui/user_avatar.dart';
import 'package:arryuwu/ui/theme/app_tokens.dart';
import 'package:arryuwu/ui/widgets/entrance.dart';
import 'package:arryuwu/ui/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// El recuerdo más reciente de la pareja (o null si no hay).
final latestMemoryProvider = FutureProvider<Memory?>((ref) async {
  ref.watch(meProvider.select((m) => m.value?.userName));
  final list = await MemoryService.list();
  return list.isEmpty ? null : list.first;
});

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(meProvider);
            ref.invalidate(latestMemoryProvider);
            await ref.read(meProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
            children: [
              // Saludo
              Entrance(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_today(), style: text.labelSmall),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Hola, ${me.value?.firstName ?? ''} 💜',
                            style: text.headlineMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    _Avatar(me: me.value, onTap: () => context.go('/profile')),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Pareja
              Entrance(
                index: 1,
                child: me.when(
                  data: (m) => _CoupleCard(me: m),
                  loading: () => const _CardPlaceholder(height: 132),
                  error: (_, __) => _ErrorCard(onRetry: () => ref.invalidate(meProvider)),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              Entrance(index: 2, child: Text('Para ustedes', style: text.titleLarge)),
              const SizedBox(height: AppSpacing.md),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.5,
                children: [
                  _QuickAction(
                    index: 3,
                    icon: Icons.photo_library_rounded,
                    color: AppColors.pinkDeep,
                    title: 'Recuerdos',
                    subtitle: 'Sus fotos en 3D',
                    onTap: () => context.push('/memories'),
                  ),
                  _QuickAction(
                    index: 4,
                    icon: Icons.forum_rounded,
                    color: AppColors.lavenderDeep,
                    title: 'Preguntas',
                    subtitle: 'Conózcanse más',
                    onTap: () => context.push('/questions'),
                  ),
                  _QuickAction(
                    index: 5,
                    icon: Icons.celebration_rounded,
                    color: const Color(0xFF00796B),
                    title: 'Actividades',
                    subtitle: 'Ideas para salir',
                    onTap: () => context.go('/activities'),
                  ),
                  _QuickAction(
                    index: 6,
                    icon: Icons.brush_rounded,
                    color: const Color(0xFFE65100),
                    title: 'Lienzo',
                    subtitle: 'Dibujen y dejen notas',
                    onTap: () => context.push('/notes'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Último recuerdo
              ref.watch(latestMemoryProvider).maybeWhen(
                    data: (m) => m == null ? const SizedBox.shrink() : Entrance(index: 7, child: _LatestMemory(memory: m)),
                    orElse: () => const SizedBox.shrink(),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  static const _dias = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];

  static String _today() {
    final now = DateTime.now();
    final dia = _dias[now.weekday - 1];
    return '${dia[0].toUpperCase()}${dia.substring(1)}, ${formatFecha(now).replaceFirst(RegExp(r' de \d{4}$'), '')}';
  }
}

class _Avatar extends StatelessWidget {
  final Me? me;
  final VoidCallback onTap;

  const _Avatar({required this.me, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ir a mi perfil',
      child: Pressable(
        child: GestureDetector(
          onTap: onTap,
          child: me == null
              ? const CircleAvatar(radius: 26, backgroundColor: AppColors.lavenderSoft)
              : UserAvatar(avatar: me!.avatar, initial: me!.initial, size: 52),
        ),
      ),
    );
  }
}

/// Tarjeta principal: "Tú ♥ Ana · N días" o la invitación a vincularse.
class _CoupleCard extends StatelessWidget {
  final Me me;

  const _CoupleCard({required this.me});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final white = text.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.92));
    final partner = me.partner;

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
      child: partner == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vincúlate con tu pareja', style: text.titleLarge?.copyWith(color: Colors.white)),
                const SizedBox(height: AppSpacing.xs),
                Text('Comparte tu código o escribe el suyo para empezar a guardar recuerdos juntos.',
                    style: white),
                const SizedBox(height: AppSpacing.lg),
                Pressable(
                  child: FilledButton.icon(
                    onPressed: () => context.push('/code'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.lavenderDeep,
                      minimumSize: const Size(0, 48),
                    ),
                    icon: const Icon(Icons.link_rounded),
                    label: const Text('Vincular'),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                _CoupleAvatars(me: me, partner: partner),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tú y ${partner.displayName}',
                          style: text.titleLarge?.copyWith(color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: AppSpacing.xs),
                      if (partner.daysTogether != null)
                        Text(
                          partner.daysTogether == 1
                              ? 'Hoy empezó su historia en Arry'
                              : '${partner.daysTogether} días juntos en Arry',
                          style: white,
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

/// Tu avatar y el de tu pareja, encimados, con un corazón que late entre los dos.
class _CoupleAvatars extends StatelessWidget {
  final Me me;
  final Partner partner;

  const _CoupleAvatars({required this.me, required this.partner});

  @override
  Widget build(BuildContext context) {
    const size = 52.0;
    return SizedBox(
      width: size * 1.75,
      height: size + 8,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: UserAvatar(avatar: me.avatar, initial: me.initial, size: size, borderWidth: 2),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: UserAvatar(
              avatar: partner.avatar,
              initial: partner.initial,
              size: size,
              partner: true,
              borderWidth: 2,
            ),
          ),
          const Positioned(left: 0, right: 0, bottom: -6, child: Center(child: _Heartbeat())),
        ],
      ),
    );
  }
}

/// Corazón que late suavemente.
class _Heartbeat extends StatefulWidget {
  const _Heartbeat();

  @override
  State<_Heartbeat> createState() => _HeartbeatState();
}

class _HeartbeatState extends State<_Heartbeat> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dos latidos cortos y una pausa, como un corazón real.
    final scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 1.18), weight: 12),
      TweenSequenceItem(tween: Tween(begin: 1.18, end: 1), weight: 12),
      TweenSequenceItem(tween: Tween(begin: 1, end: 1.12), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 1), weight: 14),
      TweenSequenceItem(tween: ConstantTween(1), weight: 52),
    ]).animate(_c);
    // Insignia pequeña entre los dos avatares.
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: AppSpacing.softShadow,
      ),
      child: ScaleTransition(
        scale: scale,
        child: const Icon(Icons.favorite_rounded, color: AppColors.pinkDeep, size: 16),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final int index;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickAction({
    required this.index,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Entrance(
      index: index,
      child: Pressable(
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Icon(icon, color: color),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: text.titleMedium),
                      Text(subtitle, style: text.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
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

class _LatestMemory extends StatelessWidget {
  final Memory memory;

  const _LatestMemory({required this.memory});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Su último recuerdo', style: text.titleLarge),
        const SizedBox(height: AppSpacing.md),
        Pressable(
          child: GestureDetector(
            onTap: () => context.push('/memories'),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AuthImage(memory.photoUrl),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xB3000000)],
                          stops: [0.45, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      bottom: AppSpacing.lg,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(formatFecha(memory.memoryDate),
                              style: text.labelSmall?.copyWith(color: Colors.white70)),
                          if (memory.description != null)
                            Text(memory.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.titleMedium?.copyWith(color: Colors.white)),
                        ],
                      ),
                    ),
                    if (memory.depthReady)
                      Positioned(
                        top: AppSpacing.md,
                        right: AppSpacing.md,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.threed_rotation, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text('3D', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CardPlaceholder extends StatelessWidget {
  final double height;

  const _CardPlaceholder({required this.height});

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.lavenderSoft,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      );
}

class _ErrorCard extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorCard({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(children: [
        const Icon(Icons.cloud_off_rounded, color: AppColors.inkMuted),
        const SizedBox(width: AppSpacing.md),
        const Expanded(child: Text('No pudimos cargar sus datos.')),
        TextButton(onPressed: onRetry, child: const Text('Reintentar')),
      ]),
    );
  }
}
