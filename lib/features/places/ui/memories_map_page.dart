import 'package:arryuwu/core/api_client.dart';
import 'package:arryuwu/features/memories/data/memory.dart';
import 'package:arryuwu/features/memories/data/memory_service.dart';
import 'package:arryuwu/features/memories/ui/auth_image.dart';
import 'package:arryuwu/features/memories/ui/memory_detail_page.dart';
import 'package:arryuwu/features/places/data/location_service.dart';
import 'package:arryuwu/features/places/ui/map_parts.dart';
import 'package:arryuwu/ui/theme/app_tokens.dart';
import 'package:arryuwu/ui/widgets/state_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Mapa con todos sus recuerdos que tienen lugar: cada pin es la foto en un círculo.
class MemoriesMapPage extends StatefulWidget {
  const MemoriesMapPage({super.key});

  @override
  State<MemoriesMapPage> createState() => _MemoriesMapPageState();
}

class _MemoriesMapPageState extends State<MemoriesMapPage> {
  late Future<List<Memory>> _future = _load();

  Future<List<Memory>> _load() async =>
      (await MemoryService.list()).where((m) => m.place?.hasPoint ?? false).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa de recuerdos')),
      body: FutureBuilder<List<Memory>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            final msg = snap.error is ApiException ? (snap.error as ApiException).message : 'Error inesperado';
            return AppMessageView(
              icon: Icons.cloud_off_rounded,
              title: 'No pudimos cargar el mapa',
              subtitle: msg,
              action: FilledButton(
                onPressed: () => setState(() => _future = _load()),
                child: const Text('Reintentar'),
              ),
            );
          }
          if (!snap.hasData) return const AppLoadingView();
          final memories = snap.data!;
          if (memories.isEmpty) {
            return const AppMessageView(
              lottie: 'assets/lottie/heart.json',
              title: 'Aún no hay lugares',
              subtitle: 'Al crear un recuerdo, toca "Agregar lugar" y aparecerá aquí.',
            );
          }
          return _Map(memories: memories);
        },
      ),
    );
  }
}

class _Map extends StatelessWidget {
  final List<Memory> memories;

  const _Map({required this.memories});

  @override
  Widget build(BuildContext context) {
    final points = memories.map((m) => m.place!.point!).toList();
    final MapOptions options = points.length == 1
        ? MapOptions(initialCenter: points.first, initialZoom: 15)
        : MapOptions(
            initialCameraFit: CameraFit.coordinates(
              coordinates: points,
              padding: const EdgeInsets.all(72),
              maxZoom: 16,
            ),
            initialCenter: LocationService.defaultCenter,
          );

    return FlutterMap(
      options: options,
      children: [
        ...osmLayers(),
        MarkerLayer(
          markers: [
            for (final m in memories)
              Marker(
                point: m.place!.point!,
                width: 64,
                height: 64,
                child: _PhotoPin(memory: m),
              ),
          ],
        ),
        osmAttribution(),
      ],
    );
  }
}

class _PhotoPin extends StatelessWidget {
  final Memory memory;

  const _PhotoPin({required this.memory});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Recuerdo en ${memory.place!.label}, ${formatFecha(memory.memoryDate)}',
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MemoryDetailPage(memory: memory)),
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: AppSpacing.softShadow,
          ),
          child: ClipOval(child: AuthImage(memory.photoUrl)),
        ),
      ),
    );
  }
}
