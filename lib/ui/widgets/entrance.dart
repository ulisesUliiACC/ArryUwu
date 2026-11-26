import 'package:flutter/material.dart';

/// Aparece con un desvanecido y un pequeño deslizamiento hacia arriba.
/// Con [index] se escalonan varios elementos (70 ms entre cada uno).
class Entrance extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration baseDelay;

  const Entrance({super.key, required this.child, this.index = 0, this.baseDelay = Duration.zero});

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  late final Animation<double> _curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.baseDelay + Duration(milliseconds: 70 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(_curve),
        child: widget.child,
      ),
    );
  }
}
