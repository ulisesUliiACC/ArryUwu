import 'package:arryuwu/features/memories/data/memory.dart';
import 'package:arryuwu/features/places/ui/map_parts.dart';
import 'package:arryuwu/ui/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Tarjeta con el lugar de un recuerdo: mapita fijo con el pin y el nombre.
/// Al tocarla abre el mapa completo para moverse con libertad.
class PlaceMapCard extends StatelessWidget {
  final MemoryPlace place;
  final double height;

  const PlaceMapCard({super.key, required this.place, this.height = 140});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: place.hasPoint
            ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => _FullMap(place: place)))
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (place.hasPoint)
              SizedBox(
                height: height,
                child: IgnorePointer(
                  child: FlutterMap(
                    options: MapOptions(initialCenter: place.point!, initialZoom: 15),
                    children: [
                      ...osmLayers(),
                      MarkerLayer(markers: [
                        Marker(
                          point: place.point!,
                          width: 44,
                          height: 54,
                          alignment: Alignment.topCenter,
                          child: const HeartPin(size: 36),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(children: [
                const Icon(Icons.place_rounded, color: AppColors.pinkDeep, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(place.label, style: text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (place.hasPoint) const Icon(Icons.open_in_full_rounded, size: 18, color: AppColors.inkMuted),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullMap extends StatelessWidget {
  final MemoryPlace place;

  const _FullMap({required this.place});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(place.label)),
      body: FlutterMap(
        options: MapOptions(initialCenter: place.point!, initialZoom: 16),
        children: [
          ...osmLayers(),
          MarkerLayer(markers: [
            Marker(
              point: place.point!,
              width: 60,
              height: 72,
              alignment: Alignment.topCenter,
              child: const HeartPin(),
            ),
          ]),
          osmAttribution(),
        ],
      ),
    );
  }
}
