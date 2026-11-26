import 'package:arryuwu/core/api_client.dart';
import 'package:arryuwu/features/auth/data/auth_controller.dart';
import 'package:arryuwu/features/home/data/me.dart';
import 'package:arryuwu/features/profile/ui/avatar_picker_sheet.dart';
import 'package:arryuwu/features/profile/ui/user_avatar.dart';
import 'package:arryuwu/ui/theme/app_tokens.dart';
import 'package:arryuwu/ui/widgets/app_button.dart';
import 'package:arryuwu/ui/widgets/app_text_field.dart';
import 'package:arryuwu/ui/widgets/entrance.dart';
import 'package:arryuwu/ui/widgets/pressable.dart';
import 'package:arryuwu/ui/widgets/state_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Pestaña de perfil: tus datos, tu pareja y la cuenta.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: SafeArea(
        child: me.when(
          loading: () => const AppLoadingView(),
          error: (e, _) => AppMessageView(
            icon: Icons.cloud_off_rounded,
            title: 'No pudimos cargar tu perfil',
            subtitle: e is ApiException ? e.message : 'Inténtalo de nuevo en un momento.',
            action: AppSecondaryButton(label: 'Reintentar', onPressed: () => ref.invalidate(meProvider)),
          ),
          data: (m) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(meProvider);
              await ref.read(meProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
              children: [
                Entrance(child: _Header(me: m)),
                const SizedBox(height: AppSpacing.xl),
                Entrance(index: 1, child: _PartnerCard(partner: m.partner)),
                const SizedBox(height: AppSpacing.xl),
                Entrance(
                  index: 2,
                  child: Text('Tu cuenta', style: Theme.of(context).textTheme.titleMedium),
                ),
                const SizedBox(height: AppSpacing.md),
                Entrance(
                  index: 3,
                  child: _OptionsCard(
                    children: [
                      _OptionTile(
                        icon: Icons.lock_outline_rounded,
                        title: 'Cambiar contraseña',
                        onTap: () => _showChangePassword(context),
                      ),
                      const _OptionTile(
                        icon: Icons.notifications_none_rounded,
                        title: 'Preferencias de avisos',
                        soon: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Entrance(
                  index: 4,
                  child: _OptionsCard(
                    children: [
                      _OptionTile(
                        icon: Icons.logout_rounded,
                        title: 'Cerrar sesión',
                        destructive: true,
                        onTap: () => _confirmLogout(context, ref),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showChangePassword(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (_) => const _ChangePasswordSheet(),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: const Text('¿Cerrar sesión?'),
        content: const Text('Tus recuerdos y los de tu pareja seguirán aquí cuando vuelvas.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    // El router manda solo al login al cambiar la sesión.
    if (ok == true) await ref.read(authProvider.notifier).logout();
  }
}

class _Header extends StatelessWidget {
  final Me me;

  const _Header({required this.me});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final fullName = [me.nombre, me.apellido].where((s) => s != null && s.trim().isNotEmpty).join(' ');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppSpacing.softShadow,
      ),
      child: Column(
        children: [
          // Tocar el avatar abre el selector (emojis animados o foto propia).
          Semantics(
            button: true,
            label: 'Cambiar avatar',
            child: Pressable(
              child: GestureDetector(
                onTap: () => showAvatarPicker(context, me),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    UserAvatar(avatar: me.avatar, initial: me.initial, size: 104),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.lavenderDeep,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.edit_rounded, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            fullName.isNotEmpty ? fullName : me.userName,
            style: text.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('@${me.userName}', style: text.titleMedium?.copyWith(color: AppColors.lavenderDeep)),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mail_outline_rounded, size: 16, color: AppColors.inkMuted),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(me.email, style: text.bodyMedium, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  final Partner? partner;

  const _PartnerCard({required this.partner});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final white = text.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.92));
    final p = partner;

    final content = Row(
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
          child: Icon(p == null ? Icons.link_rounded : Icons.favorite_rounded, color: Colors.white),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p == null ? 'Aún sin pareja vinculada' : p.displayName,
                style: text.titleMedium?.copyWith(color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                p == null
                    ? 'Toca para compartir tu código o escribir el suyo'
                    : [
                        '@${p.userName}',
                        if (p.daysTogether != null)
                          p.daysTogether == 1 ? 'desde hoy' : '${p.daysTogether} días juntos',
                      ].join(' · '),
                style: white,
              ),
            ],
          ),
        ),
        if (p == null) const Icon(Icons.chevron_right_rounded, color: Colors.white),
      ],
    );

    final card = Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.lavenderDeep, AppColors.pinkDeep],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppSpacing.softShadow,
      ),
      child: content,
    );

    if (p != null) return Semantics(label: 'Tu pareja', child: card);
    return Semantics(
      button: true,
      label: 'Vincular con tu pareja',
      child: Pressable(
        child: GestureDetector(onTap: () => context.push('/code'), child: card),
      ),
    );
  }
}

class _OptionsCard extends StatelessWidget {
  final List<Widget> children;

  const _OptionsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: AppSpacing.softShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: Column(children: children),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final bool destructive;
  final bool soon;

  const _OptionTile({
    required this.icon,
    required this.title,
    this.onTap,
    this.destructive = false,
    this.soon = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = destructive ? AppColors.error : (soon ? AppColors.inkMuted : AppColors.lavenderDeep);
    return ListTile(
      enabled: !soon,
      onTap: onTap,
      minTileHeight: 56,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: text.bodyLarge?.copyWith(
          color: destructive ? AppColors.error : (soon ? AppColors.inkMuted : AppColors.ink),
          fontWeight: destructive ? FontWeight.w600 : null,
        ),
      ),
      trailing: soon
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.lavenderSoft,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text('Próximamente', style: text.labelSmall),
            )
          : (destructive ? null : const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted)),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _oldController = TextEditingController();
  final _newController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _oldController.dispose();
    _newController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final data = await ApiClient.instance.post('/auth/update-password', body: {
        'oldPassword': _oldController.text,
        'newPassword': _newController.text,
      });
      if (!mounted) return;
      final message = (data is Map && data['message'] is String) ? data['message'] as String : 'Contraseña actualizada.';
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message), backgroundColor: AppColors.success));
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Cambiar contraseña', style: text.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                Text('Usa al menos 8 caracteres. Tu sesión seguirá abierta.', style: text.bodyMedium),
                const SizedBox(height: AppSpacing.xl),
                AppTextField(
                  controller: _oldController,
                  label: 'Contraseña actual',
                  icon: Icons.lock_outline_rounded,
                  password: true,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.password],
                  enabled: !_loading,
                  validator: (v) => (v == null || v.isEmpty) ? 'Escribe tu contraseña actual' : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _newController,
                  label: 'Contraseña nueva',
                  icon: Icons.lock_reset_rounded,
                  password: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  enabled: !_loading,
                  onSubmitted: (_) => _submit(),
                  validator: (v) {
                    if (v == null || v.length < 8) return 'Debe tener al menos 8 caracteres';
                    if (v == _oldController.text) return 'Debe ser distinta de la actual';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                AppPrimaryButton(label: 'Guardar contraseña', loading: _loading, onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
