import 'package:flutter/material.dart';

/// Se encoge un poco al presionarlo: da sensación táctil a botones y tarjetas.
class Pressable extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final double pressedScale;

  const Pressable({super.key, required this.child, this.enabled = true, this.pressedScale = 0.96});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _set(bool value) {
    if (widget.enabled && _pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
