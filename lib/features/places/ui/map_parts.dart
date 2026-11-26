import 'package:arryuwu/ui/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Capa de mapa de OpenStreetMap (sin cuenta ni clave). La política de uso de OSM pide
/// identificar la app y mostrar la atribución, por eso siempre van juntas.
List<Widget> osmLayers() => [
      TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'com.arryuwu.arryuwu',
        maxZoom: 19,
      ),
    ];

Widget osmAttribution() => const SimpleAttributionWidget(
      source: Text('OpenStreetMap'),
      backgroundColor: Color(0xCCFFFFFF),
    );

/// Pin de Arry: un corazón en una gota, con sombra suave.
class HeartPin extends StatelessWidget {
  final double size;

  const HeartPin({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.pinkDeep,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: AppSpacing.softShadow,
          ),
          child: Icon(Icons.favorite_rounded, color: Colors.white, size: size * 0.5),
        ),
        CustomPaint(size: Size(size * 0.3, size * 0.22), painter: _PinTail()),
      ],
    );
  }
}

class _PinTail extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.pinkDeep);
  }

  @override
  bool shouldRepaint(_PinTail oldDelegate) => false;
}
