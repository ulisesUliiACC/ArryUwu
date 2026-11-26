import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Muestra una foto con efecto 3D: inclina el celular (o arrastra el dedo) y la escena se mueve con profundidad.
/// Al abrir hace un pequeño giro automático para que se note el efecto.
class ParallaxView extends StatefulWidget {
  final Uint8List photo;
  final Uint8List depth;
  final double strength;

  const ParallaxView({super.key, required this.photo, required this.depth, this.strength = 0.04});

  @override
  State<ParallaxView> createState() => _ParallaxViewState();
}

class _ParallaxViewState extends State<ParallaxView> with SingleTickerProviderStateMixin {
  static Future<ui.FragmentProgram>? _program;

  ui.FragmentShader? _shader;
  ui.Image? _photo;
  ui.Image? _depth;
  Object? _error;

  final _tilt = ValueNotifier<Offset>(Offset.zero);
  Offset _sensorTarget = Offset.zero;
  Offset _dragOffset = Offset.zero;
  Offset? _baseline;
  StreamSubscription<AccelerometerEvent>? _sensorSub;
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    _load();
    _sensorSub = accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval).listen(
      _onAccelerometer,
      onError: (_) {}, // sin sensor: queda el arrastre con el dedo
      cancelOnError: true,
    );
  }

  Future<void> _load() async {
    try {
      _program ??= ui.FragmentProgram.fromAsset('shaders/parallax.frag');
      final program = await _program!;
      final images = await Future.wait([_decode(widget.photo), _decode(widget.depth)]);
      if (!mounted) return;
      setState(() {
        _shader = program.fragmentShader();
        _photo = images[0];
        _depth = images[1];
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  static Future<ui.Image> _decode(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    return (await codec.getNextFrame()).image;
  }

  void _onAccelerometer(AccelerometerEvent e) {
    final reading = Offset(e.x, e.y);
    _baseline ??= reading; // la posición en que lo sostienes es el "centro"
    final delta = reading - _baseline!;
    _sensorTarget = Offset(
      (-delta.dx / 3.5).clamp(-1.0, 1.0),
      (delta.dy / 3.5).clamp(-1.0, 1.0),
    );
  }

  void _onTick(Duration elapsed) {
    // Intro: un círculo suave durante 1.6 s para enseñar el efecto.
    final t = elapsed.inMilliseconds / 1600.0;
    final intro = t < 1
        ? Offset(math.cos(t * 2 * math.pi), math.sin(t * 2 * math.pi)) * (0.9 * (1 - t))
        : Offset.zero;
    final target = _clampOffset(_sensorTarget + _dragOffset + intro);
    // Suavizado para que no tiemble.
    _tilt.value = Offset.lerp(_tilt.value, target, 0.15)!;
  }

  static Offset _clampOffset(Offset o) => Offset(o.dx.clamp(-1.0, 1.0), o.dy.clamp(-1.0, 1.0));

  @override
  void dispose() {
    _ticker.dispose();
    _sensorSub?.cancel();
    _tilt.dispose();
    _shader?.dispose();
    _photo?.dispose();
    _depth?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Image.memory(widget.photo, fit: BoxFit.cover); // sin efecto, pero se ve la foto
    }
    if (_shader == null) {
      return Image.memory(widget.photo, fit: BoxFit.cover, gaplessPlayback: true);
    }
    return GestureDetector(
      onPanUpdate: (d) {
        final size = context.size ?? const Size(1, 1);
        _dragOffset = _clampOffset(_dragOffset +
            Offset(d.delta.dx / size.width * 3, d.delta.dy / size.height * 3));
      },
      onPanEnd: (_) => _dragOffset = Offset.zero,
      onDoubleTap: () => _baseline = null, // recentra con la posición actual
      child: CustomPaint(
        size: Size.infinite,
        painter: _ParallaxPainter(
          shader: _shader!,
          photo: _photo!,
          depth: _depth!,
          tilt: _tilt,
          strength: widget.strength,
        ),
      ),
    );
  }
}

class _ParallaxPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final ui.Image photo;
  final ui.Image depth;
  final ValueNotifier<Offset> tilt;
  final double strength;

  _ParallaxPainter({
    required this.shader,
    required this.photo,
    required this.depth,
    required this.tilt,
    required this.strength,
  }) : super(repaint: tilt);

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, photo.width.toDouble())
      ..setFloat(3, photo.height.toDouble())
      ..setFloat(4, tilt.value.dx)
      ..setFloat(5, tilt.value.dy)
      ..setFloat(6, strength)
      ..setImageSampler(0, photo)
      ..setImageSampler(1, depth);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_ParallaxPainter old) =>
      old.photo != photo || old.depth != depth || old.shader != shader;
}
