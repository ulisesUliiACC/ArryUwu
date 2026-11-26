import 'dart:async';

import 'package:arryuwu/core/api_client.dart';
import 'package:arryuwu/features/couple/data/couple_service.dart';
import 'package:arryuwu/features/home/data/me.dart';
import 'package:arryuwu/features/memories/data/memory_service.dart' show formatFecha;
import 'package:arryuwu/ui/theme/app_tokens.dart';
import 'package:arryuwu/ui/widgets/app_button.dart';
import 'package:arryuwu/ui/widgets/app_text_field.dart';
import 'package:arryuwu/ui/widgets/entrance.dart';
import 'package:arryuwu/ui/widgets/state_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

/// Vincular la cuenta con la pareja: compartir tu código o escribir el suyo.
class LinkPage extends ConsumerStatefulWidget {
  const LinkPage({super.key});

  @override
  ConsumerState<LinkPage> createState() => _LinkPageState();
}

enum _Mode { share, enter }

class _LinkPageState extends ConsumerState<LinkPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  _Mode _mode = _Mode.share;

  Invitation? _invitation;
  DateTime? _generatedAt;
  bool _generating = false;
  bool _autoRegenFailed = false;
  Timer? _ticker;
  int _ticks = 0;

  bool _linking = false;

  /// Nombre de la pareja mientras se muestra la celebración.
  String? _celebrating;

  @override
  void dispose() {
    _ticker?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  // ---------- Compartir tu código ----------

  Future<void> _generate({bool auto = false}) async {
    if (_generating) return;
    setState(() => _generating = true);
    try {
      final inv = await CoupleService.generate();
      if (!mounted) return;
      setState(() {
        _invitation = inv;
        _generatedAt = DateTime.now();
        _autoRegenFailed = false;
      });
      _startTicker();
    } on ApiException catch (e) {
      if (!mounted) return;
      if (auto) setState(() => _autoRegenFailed = true);
      showAppSnack(context, e.message, error: true);
      // 409: ya tiene pareja → /api/me lo reflejará y se muestra el estado vinculado.
      if (e.statusCode == 409) ref.invalidate(meProvider);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticks = 0;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _ticks++;
      final inv = _invitation;
      if (inv != null && !DateTime.now().isBefore(inv.expiresAt)) {
        // Expiró: genera otro una vez; si falla, queda el botón para hacerlo a mano.
        if (!_autoRegenFailed) _generate(auto: true);
      } else if (_ticks % 10 == 0) {
        // Mientras el código está activo, revisa si tu pareja ya lo usó.
        ref.invalidate(meProvider);
      }
      setState(() {});
    });
  }

  Future<void> _copy() async {
    final inv = _invitation;
    if (inv == null) return;
    await Clipboard.setData(ClipboardData(text: inv.code));
    HapticFeedback.selectionClick();
    if (mounted) showAppSnack(context, 'Código copiado. Compártelo con tu pareja 💜');
  }

  // ---------- Escribir el suyo ----------

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final value = data?.text?.trim();
    if (value != null && value.isNotEmpty) _codeController.text = value;
  }

  Future<void> _link() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _linking = true);
    try {
      final result = await CoupleService.link(_codeController.text);
      if (!mounted) return;
      _celebrate(result.creatorUserName);
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _linking = false);
    }
  }

  void _celebrate(String? partnerName) {
    if (_celebrating != null) return;
    _ticker?.cancel();
    HapticFeedback.heavyImpact();
    setState(() => _celebrating = partnerName ?? '');
    ref.invalidate(meProvider);
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Si tu pareja usa tu código mientras lo ves, celebra aquí también.
    ref.listen(meProvider, (prev, next) {
      final partner = next.value?.partner;
      if (_invitation != null && prev?.value?.partner == null && partner != null) {
        _celebrate(partner.displayName);
      }
    });

    final me = ref.watch(meProvider);

    final Widget body;
    if (_celebrating != null) {
      body = _Celebration(key: const ValueKey('celebration'), partnerName: _celebrating!);
    } else {
      body = me.when(
        loading: () => const AppLoadingView(key: ValueKey('loading')),
        error: (e, _) => AppMessageView(
          key: const ValueKey('error'),
          icon: Icons.cloud_off_rounded,
          title: 'No pudimos cargar tus datos',
          subtitle: e is ApiException ? e.message : 'Inténtalo de nuevo en un momento.',
          action: AppSecondaryButton(label: 'Reintentar', onPressed: () => ref.invalidate(meProvider)),
        ),
        data: (m) => m.partner != null
            ? _AlreadyLinked(key: const ValueKey('linked'), partner: m.partner!)
            : _buildLinkForm(context),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Vincular')),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutCubic,
          child: body,
        ),
      ),
    );
  }

  Widget _buildLinkForm(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      key: const ValueKey('form'),
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
      children: [
        Entrance(child: Text('Conecta sus cuentas', style: text.headlineMedium)),
        const SizedBox(height: AppSpacing.xs),
        Entrance(
          index: 1,
          child: Text(
            'Uno comparte su código y el otro lo escribe. Así empiezan a guardar todo juntos.',
            style: text.bodyMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Entrance(
          index: 2,
          child: _ModeSwitch(
            mode: _mode,
            onChanged: (m) {
              FocusScope.of(context).unfocus();
              setState(() => _mode = m);
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Entrance(
          index: 3,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOutCubic,
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(a),
                child: child,
              ),
            ),
            child: _mode == _Mode.share ? _buildShare(context) : _buildEnter(context),
          ),
        ),
      ],
    );
  }

  Widget _buildShare(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final inv = _invitation;
    final now = DateTime.now();
    final expired = inv != null && !now.isBefore(inv.expiresAt);
    final remaining = inv == null || expired ? Duration.zero : inv.expiresAt.difference(now);
    final total = inv == null || _generatedAt == null ? 1 : inv.expiresAt.difference(_generatedAt!).inSeconds;
    final fraction = total <= 0 ? 0.0 : (remaining.inSeconds / total).clamp(0.0, 1.0);

    return _SectionCard(
      key: const ValueKey('share'),
      icon: Icons.qr_code_2_rounded,
      title: 'Comparte tu código',
      subtitle: 'Genera un código y mándaselo a tu pareja. Dura 5 minutos y solo sirve una vez.',
      children: [
        if (inv == null)
          AppPrimaryButton(
            label: 'Generar mi código',
            icon: Icons.auto_awesome_rounded,
            loading: _generating,
            onPressed: _generate,
          )
        else ...[
          Semantics(
            label: 'Tu código es ${inv.code.split('').join(' ')}',
            excludeSemantics: true,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl, horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: expired ? AppColors.background : AppColors.lavenderSoft.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: FittedBox(
                  key: ValueKey(inv.code),
                  fit: BoxFit.scaleDown,
                  child: Text(
                    inv.code,
                    style: text.headlineMedium?.copyWith(
                      letterSpacing: 6,
                      color: expired ? AppColors.inkMuted : AppColors.lavenderDeep,
                      decoration: expired ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.xs),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: AppColors.lavenderSoft,
              color: remaining.inSeconds <= 30 ? AppColors.pinkDeep : AppColors.lavenderDeep,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(expired ? Icons.timer_off_rounded : Icons.timer_outlined, size: 18, color: AppColors.inkMuted),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  expired
                      ? (_generating ? 'Expiró. Generando uno nuevo…' : 'Este código ya expiró')
                      : 'Expira en ${_mmss(remaining)}',
                  style: text.labelSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (expired)
            AppPrimaryButton(
              label: 'Generar uno nuevo',
              icon: Icons.refresh_rounded,
              loading: _generating,
              onPressed: _generate,
            )
          else ...[
            AppPrimaryButton(label: 'Copiar código', icon: Icons.copy_rounded, onPressed: _copy),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: TextButton.icon(
                onPressed: _generating ? null : _generate,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Generar otro'),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.lavender),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(child: Text('Esperando a que tu pareja lo escriba…', style: text.labelSmall)),
              ],
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildEnter(BuildContext context) {
    return _SectionCard(
      key: const ValueKey('enter'),
      icon: Icons.favorite_rounded,
      title: 'Escribe el suyo',
      subtitle: '¿Tu pareja ya generó su código? Escríbelo tal cual, respetando mayúsculas y minúsculas.',
      children: [
        Form(
          key: _formKey,
          child: AppTextField(
            controller: _codeController,
            label: 'Código de tu pareja',
            icon: Icons.vpn_key_outlined,
            textInputAction: TextInputAction.done,
            enabled: !_linking,
            onSubmitted: (_) => _link(),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe el código de tu pareja' : null,
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _linking ? null : _paste,
            icon: const Icon(Icons.content_paste_rounded, size: 18),
            label: const Text('Pegar'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppPrimaryButton(label: 'Vincular', icon: Icons.link_rounded, loading: _linking, onPressed: _link),
      ],
    );
  }

  static String _mmss(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

/// Selector de dos opciones con una píldora que se desliza.
class _ModeSwitch extends StatelessWidget {
  final _Mode mode;
  final ValueChanged<_Mode> onChanged;

  const _ModeSwitch({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget option(_Mode value, String label) {
      final selected = mode == value;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (!selected) HapticFeedback.selectionClick();
              onChanged(value);
            },
            child: SizedBox(
              height: 48,
              child: Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: (text.titleMedium ?? const TextStyle())
                      .copyWith(color: selected ? Colors.white : AppColors.inkMuted),
                  child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: AppSpacing.softShadow,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              alignment: mode == _Mode.share ? Alignment.centerLeft : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.lavenderDeep,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
              ),
            ),
          ),
          Row(children: [option(_Mode.share, 'Mi código'), option(_Mode.enter, 'Su código')]),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _SectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppSpacing.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.pink.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, color: AppColors.pinkDeep),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(title, style: text.titleLarge)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(subtitle, style: text.bodyMedium),
          const SizedBox(height: AppSpacing.xl),
          ...children,
        ],
      ),
    );
  }
}

/// Ya tienen pareja: no tiene caso generar otro código.
class _AlreadyLinked extends StatelessWidget {
  final Partner partner;

  const _AlreadyLinked({super.key, required this.partner});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final white = text.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.92));
    final since = partner.linkedSince;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Entrance(
          child: Container(
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
              children: [
                Lottie.asset('assets/lottie/heart.json', height: 120),
                const SizedBox(height: AppSpacing.md),
                Text('Ya están vinculados',
                    style: text.titleLarge?.copyWith(color: Colors.white), textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Tú y ${partner.displayName}${since != null ? ' desde el ${formatFecha(since.toLocal())}' : ''}',
                  style: white,
                  textAlign: TextAlign.center,
                ),
                if (partner.daysTogether != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      partner.daysTogether == 1 ? 'Hoy empezó su historia' : '${partner.daysTogether} días juntos',
                      style: text.labelSmall?.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Entrance(
          index: 1,
          child: AppSecondaryButton(
            label: 'Volver',
            onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
          ),
        ),
      ],
    );
  }
}

/// Corazones al vincularse; la página se cierra sola después.
class _Celebration extends StatelessWidget {
  final String partnerName;

  const _Celebration({super.key, required this.partnerName});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.6, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.elasticOut,
          builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset('assets/lottie/heart.json', width: 220, repeat: false),
              const SizedBox(height: AppSpacing.lg),
              Text('¡Ya están vinculados!', style: text.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text(
                partnerName.isEmpty
                    ? 'Desde hoy todo lo que guarden será de los dos 💜'
                    : 'Tú y $partnerName: desde hoy todo lo que guarden será de los dos 💜',
                style: text.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
