import 'package:arryuwu/core/api_client.dart';
import 'package:arryuwu/features/capsules/data/capsule.dart';
import 'package:arryuwu/features/capsules/ui/capsule_finder_page.dart';
import 'package:arryuwu/features/capsules/ui/create_capsule_page.dart';
import 'package:arryuwu/features/places/data/location_service.dart';
import 'package:arryuwu/features/places/ui/map_parts.dart';
import 'package:arryuwu/ui/theme/app_tokens.dart';
import 'package:arryuwu/ui/widgets/entrance.dart';
import 'package:arryuwu/ui/widgets/pressable.dart';
import 'package:arryuwu/ui/widgets/state_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Cápsulas de la pareja: mapa arriba y lista con distancia. Tocar una abre la vista de cámara.
class CapsulesPage extends StatefulWidget {
  const CapsulesPage({super.key});

  @override
  State<CapsulesPage> createState() => _CapsulesPageState();
}

class _CapsulesPageState extends State<CapsulesPage> {
  List<Capsule>? _capsules;
  String? _error;
  LatLng? _here;

  @override
  void initState() {
    super.initState();
    _load();
    LocationService.current().then((p) {
      if (mounted) setState(() => _here = p);
    }).catchError((_) {}); // sin ubicación igual se ve la lista, solo sin distancias
  }

  Future<void> _load() async {
    try {
      final list = await CapsuleService.list();
      if (mounted) setState(() {
        _capsules = list;
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _create() async {
    final saved = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const CreateCapsulePage()));
    if (saved == true) {
      _load();
      if (mounted) showAppSnack(context, 'Cápsula escondida. Tu pareja la verá en el mapa 💌');
    }
  }

  Future<void> _find(Capsule c) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => CapsuleFinderPage(capsule: c)));
    _load(); // pudo haberse abierto
  }

  String? _distanceTo(Capsule c) {
    if (_here == null) return null;
    final m = const Distance().as(LengthUnit.Meter, _here!, c.point);
    return m >= 1000 ? '${(m / 1000).toStringAsFixed(1)} km' : '${m.round()} m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cápsulas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        backgroundColor: AppColors.pinkDeep,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.card_giftcard_rounded),
        label: const Text('Esconder cápsula'),
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_error != null && _capsules == null) {
      return AppMessageView(
        icon: Icons.cloud_off_rounded,
        title: 'No pudimos cargar las cápsulas',
        subtitle: _error!,
        action: FilledButton(onPressed: _load, child: const Text('Reintentar')),
      );
    }
    final list = _capsules;
    if (list == null) return const AppLoadingView();
    if (list.isEmpty) {
      return const AppMessageView(
        lottie: 'assets/lottie/heart.json',
        title: 'Aún no hay cápsulas',
        subtitle: 'Esconde un dibujo o una foto en un lugar especial. Tu pareja solo podrá abrirla cuando llegue ahí.',
      );
    }

    final text = Theme.of(context).textTheme;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 96),
        children: [
          Entrance(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: SizedBox(height: 200, child: _map(list)),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < list.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Entrance(
                index: i + 1,
                child: Pressable(
                  child: Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: ListTile(
                      onTap: () => _find(list[i]),
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                      leading: CircleAvatar(
                        backgroundColor: list[i].locked ? AppColors.pink.withValues(alpha: 0.35) : AppColors.lavenderSoft,
                        child: Icon(
                          list[i].locked ? Icons.card_giftcard_rounded : (list[i].mine ? Icons.edit_location_alt_rounded : Icons.lock_open_rounded),
                          color: list[i].locked ? AppColors.pinkDeep : AppColors.lavenderDeep,
                        ),
                      ),
                      title: Text(list[i].placeLabel, style: text.titleMedium),
                      subtitle: Text(
                        [
                          list[i].mine ? 'La escondiste tú' : (list[i].locked ? '¡Sin abrir! De @${list[i].creatorUserName}' : 'Abierta'),
                          if (_distanceTo(list[i]) != null) 'a ${_distanceTo(list[i])}',
                        ].join(' · '),
                      ),
                      trailing: const Icon(Icons.photo_camera_rounded, color: AppColors.lavenderDeep),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _map(List<Capsule> list) {
    final points = [for (final c in list) c.point, if (_here != null) _here!];
    return FlutterMap(
      options: points.length == 1
          ? MapOptions(initialCenter: points.first, initialZoom: 15)
          : MapOptions(
              initialCameraFit: CameraFit.coordinates(coordinates: points, padding: const EdgeInsets.all(48), maxZoom: 16),
              initialCenter: LocationService.defaultCenter,
            ),
      children: [
        ...osmLayers(),
        MarkerLayer(markers: [
          for (final c in list)
            Marker(
              point: c.point,
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () => _find(c),
                child: Container(
                  decoration: BoxDecoration(
                    color: c.locked ? AppColors.pinkDeep : AppColors.lavenderDeep,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Icon(c.locked ? Icons.card_giftcard_rounded : Icons.favorite_rounded, color: Colors.white, size: 18),
                ),
              ),
            ),
          if (_here != null)
            Marker(
              point: _here!,
              width: 20,
              height: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E88E5),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
              ),
            ),
        ]),
        osmAttribution(),
      ],
    );
  }
}
