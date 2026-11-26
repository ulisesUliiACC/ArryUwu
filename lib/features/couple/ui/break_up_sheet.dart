import 'package:arryuwu/core/api_client.dart';
import 'package:arryuwu/features/couple/data/break_up_service.dart';
import 'package:arryuwu/features/home/data/me.dart';
import 'package:arryuwu/features/home/ui/home_page.dart';
import 'package:arryuwu/ui/theme/app_tokens.dart';
import 'package:arryuwu/ui/widgets/hold_to_confirm.dart';
import 'package:arryuwu/ui/widgets/state_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hoja para terminar el lazo: copia de respaldo opcional, elegir conservar o eliminar todo,
/// y confirmar manteniendo presionado.
Future<void> showBreakUpSheet(BuildContext context, Partner partner) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
    ),
    builder: (_) => _BreakUpSheet(partner: partner),
  );
}

enum _Mode { keep, deleteAll }

class _BreakUpSheet extends ConsumerStatefulWidget {
  final Partner partner;

  const _BreakUpSheet({required this.partner});

  @override
  ConsumerState<_BreakUpSheet> createState() => _BreakUpSheetState();
}

class _BreakUpSheetState extends ConsumerState<_BreakUpSheet> {
  _Mode _mode = _Mode.keep;
  bool _copying = false;
  bool _copied = false;
  bool _working = false;

  String get _name => widget.partner.displayName;

  Future<void> _downloadCopy() async {
    setState(() => _copying = true);
    try {
      final saved = await BreakUpService.downloadAndShareCopy();
      if (saved && mounted) setState(() => _copied = true);
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    } catch (_) {
      if (mounted) showAppSnack(context, 'No pudimos preparar la copia.', error: true);
    } finally {
      if (mounted) setState(() => _copying = false);
    }
  }

  Future<void> _breakUp() async {
    setState(() => _working = true);
    try {
      await BreakUpService.breakUp(deleteData: _mode == _Mode.deleteAll);
      ref.invalidate(meProvider);
      ref.invalidate(latestMemoryProvider);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(content: Text('El lazo terminó. Cuídate mucho 💜')));
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final deleteAll = _mode == _Mode.deleteAll;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
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
          const Icon(Icons.heart_broken_rounded, size: 56, color: AppColors.pinkDeep),
          const SizedBox(height: AppSpacing.md),
          Text('¿Terminar el lazo con $_name?', style: text.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Está bien cerrar ciclos. Tómate tu tiempo: aquí decides qué pasa con lo que compartieron.',
            style: text.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Copia de respaldo
          Text('Antes de irte', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: _copying || _working ? null : _downloadCopy,
            icon: _copying
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(_copied ? Icons.check_circle_rounded : Icons.download_rounded),
            label: Text(_copied ? 'Copia guardada' : 'Descargar una copia (.zip)'),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('Incluye los recuerdos con sus fotos, las cápsulas abiertas y el lienzo como imagen.',
              style: text.labelSmall),
          const SizedBox(height: AppSpacing.xl),

          // Qué pasa con los datos
          Text('¿Qué pasa con lo compartido?', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          _Choice(
            selected: !deleteAll,
            icon: Icons.inventory_2_outlined,
            color: AppColors.lavenderDeep,
            title: 'Solo romper el lazo',
            subtitle: 'Cada quien conserva lo suyo. Dejan de ver los recuerdos, cápsulas y lienzo del otro.',
            onTap: _working ? null : () => setState(() => _mode = _Mode.keep),
          ),
          const SizedBox(height: AppSpacing.sm),
          _Choice(
            selected: deleteAll,
            icon: Icons.delete_forever_rounded,
            color: AppColors.error,
            title: 'Romper y eliminar todo',
            subtitle: 'Se borran para siempre tus recuerdos y fotos, tus cápsulas, el lienzo compartido '
                'y el registro del lazo. Lo que subió $_name sigue siendo suyo.',
            onTap: _working ? null : () => setState(() => _mode = _Mode.deleteAll),
          ),
          const SizedBox(height: AppSpacing.xl),

          HoldToConfirmButton(
            label: deleteAll ? 'Mantén para borrar y terminar' : 'Mantén para terminar el lazo',
            color: deleteAll ? AppColors.error : AppColors.pinkDeep,
            loading: _working,
            onConfirmed: _working ? null : _breakUp,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: _working ? null : () => Navigator.pop(context),
            child: const Text('Mejor no, volver'),
          ),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _Choice({
    required this.selected,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      selected: selected,
      button: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: selected ? color : AppColors.lavenderSoft, width: selected ? 2 : 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, color: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: text.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(subtitle, style: text.bodyMedium),
                ]),
              ),
              Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? color : AppColors.inkMuted),
            ]),
          ),
        ),
      ),
    );
  }
}
