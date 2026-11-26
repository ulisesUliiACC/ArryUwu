import 'package:arryuwu/ui/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Botón que hay que MANTENER presionado para confirmar una acción seria (no se activa con un toque
/// accidental). Se va llenando mientras se presiona; si se suelta antes, vuelve a vaciarse.
class HoldToConfirmButton extends StatefulWidget {
  final String label;
  final Color color;
  final Duration duration;
  final bool loading;
  final VoidCallback? onConfirmed;

  const HoldToConfirmButton({
    super.key,
    required this.label,
    required this.onConfirmed,
    this.color = AppColors.error,
    this.duration = const Duration(milliseconds: 2500),
    this.loading = false,
  });

  @override
  State<HoldToConfirmButton> createState() => _HoldToConfirmButtonState();
}

class _HoldToConfirmButtonState extends State<HoldToConfirmButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        HapticFeedback.heavyImpact();
        widget.onConfirmed?.call();
        _c.value = 0;
      }
    });

  bool get _enabled => widget.onConfirmed != null && !widget.loading;

  void _down() {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
    _c.forward();
  }

  void _up() {
    if (_c.status != AnimationStatus.completed) _c.animateBack(0, duration: const Duration(milliseconds: 250));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      enabled: _enabled,
      label: '${widget.label}. Mantén presionado para confirmar.',
      child: Listener(
        onPointerDown: (_) => _down(),
        onPointerUp: (_) => _up(),
        onPointerCancel: (_) => _up(),
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => Container(
            height: 56,
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: _enabled ? 0.12 : 0.06),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: widget.color.withValues(alpha: _enabled ? 1 : 0.3), width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _c.value,
                  child: ColoredBox(color: widget.color),
                ),
                Center(
                  child: widget.loading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: widget.color),
                        )
                      : Text(
                          _c.value > 0 ? 'Sigue presionando…' : widget.label,
                          style: text.titleMedium?.copyWith(
                            color: _c.value > 0.5 ? Colors.white : widget.color.withValues(alpha: _enabled ? 1 : 0.4),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
