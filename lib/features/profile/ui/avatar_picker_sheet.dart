import 'package:arryuwu/core/api_client.dart';
import 'package:arryuwu/features/home/data/me.dart';
import 'package:arryuwu/features/profile/data/avatars.dart';
import 'package:arryuwu/features/profile/ui/user_avatar.dart';
import 'package:arryuwu/ui/theme/app_tokens.dart';
import 'package:arryuwu/ui/widgets/app_button.dart';
import 'package:arryuwu/ui/widgets/pressable.dart';
import 'package:arryuwu/ui/widgets/state_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Abre la hoja para elegir avatar: emojis animados, foto propia o quitarlo.
Future<void> showAvatarPicker(BuildContext context, Me me) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
    ),
    builder: (_) => _AvatarPickerSheet(me: me),
  );
}

class _AvatarPickerSheet extends ConsumerStatefulWidget {
  final Me me;

  const _AvatarPickerSheet({required this.me});

  @override
  ConsumerState<_AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends ConsumerState<_AvatarPickerSheet> {
  late String? _selected = widget.me.avatar.key;
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(meProvider);
      await ref.read(meProvider.future);
      if (!mounted) return;
      HapticFeedback.lightImpact();
      Navigator.pop(context);
      showAppSnack(context, done);
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _uploadPhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    await _run(() => AvatarService.uploadPhoto(bytes, file.name), 'Foto de perfil actualizada');
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final current = widget.me.avatar;
    final preview = _selected != null ? AvatarInfo(key: _selected) : current;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.lavenderSoft, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                child: UserAvatar(
                  key: ValueKey('${preview.key}-${preview.photoId}'),
                  avatar: preview,
                  initial: widget.me.initial,
                  size: 104,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Elige tu avatar', style: text.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),

            // Cuadrícula de emojis: solo se anima el elegido (ahorra batería en celulares modestos).
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              children: [
                for (final p in avatarPresets)
                  Semantics(
                    button: true,
                    selected: _selected == p.key,
                    label: p.label,
                    child: Pressable(
                      child: GestureDetector(
                        onTap: _busy
                            ? null
                            : () {
                                HapticFeedback.selectionClick();
                                setState(() => _selected = p.key);
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selected == p.key ? AppColors.lavenderDeep : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: UserAvatar(
                            avatar: AvatarInfo(key: p.key),
                            initial: '',
                            size: 64,
                            animate: _selected == p.key,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            AppPrimaryButton(
              label: 'Usar este avatar',
              loading: _busy,
              onPressed: _selected == null || (_selected == current.key && !current.hasPhoto)
                  ? null
                  : () => _run(() => AvatarService.setPreset(_selected!), '¡Avatar listo!'),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: _busy ? null : _uploadPhoto,
                    icon: const Icon(Icons.photo_camera_back_outlined),
                    label: const Text('Subir mi foto'),
                  ),
                ),
                if (current.hasPhoto || current.hasPreset)
                  Expanded(
                    child: TextButton.icon(
                      onPressed: _busy ? null : () => _run(AvatarService.reset, 'Avatar quitado'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.inkMuted),
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: const Text('Usar mi inicial'),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('Emojis animados: Noto Emoji de Google (CC BY 4.0)',
                textAlign: TextAlign.center, style: text.labelSmall),
          ],
        ),
      ),
    );
  }
}
