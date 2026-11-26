import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:arryuwu/ui/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Lienzo sencillo para dibujar el contenido de una cápsula. Fondo transparente: al exportarlo,
/// el dibujo "flota" sobre la cámara.
class DrawingPadController extends ChangeNotifier {
  final strokes = <_Stroke>[];
  Color color = AppColors.pinkDeep;
  double width = 8;
  final _boundaryKey = GlobalKey();

  bool get isEmpty => strokes.isEmpty;

  void _start(Offset p) {
    strokes.add(_Stroke([p], color, width));
    notifyListeners();
  }

  void _extend(Offset p) {
    if (strokes.isEmpty) return;
    strokes.last.points.add(p);
    notifyListeners();
  }

  void setColor(Color c) {
    color = c;
    notifyListeners();
  }

  void undo() {
    if (strokes.isNotEmpty) {
      strokes.removeLast();
      notifyListeners();
    }
  }

  void clear() {
    strokes.clear();
    notifyListeners();
  }

  /// PNG con transparencia del dibujo actual.
  Future<Uint8List> exportPng() async {
    final boundary = _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  }
}

class _Stroke {
  final List<Offset> points;
  final Color color;
  final double width;

  _Stroke(this.points, this.color, this.width);
}

class DrawingPad extends StatelessWidget {
  final DrawingPadController controller;

  const DrawingPad({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) => controller._start(d.localPosition),
      onPanUpdate: (d) => controller._extend(d.localPosition),
      child: RepaintBoundary(
        key: controller._boundaryKey,
        child: CustomPaint(
          size: Size.infinite,
          painter: _PadPainter(controller),
        ),
      ),
    );
  }
}

class _PadPainter extends CustomPainter {
  final DrawingPadController c;

  _PadPainter(this.c) : super(repaint: c);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in c.strokes) {
      final paint = Paint()
        ..color = s.color
        ..strokeWidth = s.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      if (s.points.length == 1) {
        canvas.drawCircle(s.points.first, s.width / 2, paint..style = PaintingStyle.fill);
        continue;
      }
      final path = Path()..moveTo(s.points.first.dx, s.points.first.dy);
      for (var i = 1; i < s.points.length - 1; i++) {
        final mid = Offset.lerp(s.points[i], s.points[i + 1], 0.5)!;
        path.quadraticBezierTo(s.points[i].dx, s.points[i].dy, mid.dx, mid.dy);
      }
      path.lineTo(s.points.last.dx, s.points.last.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_PadPainter old) => false; // repinta con el notifier
}
