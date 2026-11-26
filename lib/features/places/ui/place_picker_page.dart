import 'package:arryuwu/features/memories/data/memory.dart';
import 'package:arryuwu/features/places/data/location_service.dart';
import 'package:arryuwu/features/places/ui/map_parts.dart';
import 'package:arryuwu/ui/theme/app_tokens.dart';
import 'package:arryuwu/ui/widgets/app_button.dart';
import 'package:arryuwu/ui/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Elegir el lugar de un recuerdo: tocar el mapa o usar la ubicación actual, y ponerle nombre.
/// Devuelve un [MemoryPlace] con Navigator.pop, o null si se cancela.
class PlacePickerPage extends StatefulWidget {
  final MemoryPlace? initial;

  const PlacePickerPage({super.key, this.initial});

  @override
  State<PlacePickerPage> createState() => _PlacePickerPageState();
}

class _PlacePickerPageState extends State<PlacePickerPage> with SingleTickerProviderStateMixin {
  final _map = MapController();
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late LatLng? _point = widget.initial?.point;
  bool _locating = false;

  // Animación de "caída" del pin cada vez que se coloca.
  late final AnimationController _drop =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 450));

  @override
  void initState() {
    super.initState();
    if (_point == null) {
      _useMyLocation(silent: true); // intenta centrar en donde estás, sin molestar si falla
    } else {
      _drop.value = 1;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _drop.dispose();
    _map.dispose();
    super.dispose();
  }

  void _place(LatLng p, {bool move = false}) {
    HapticFeedback.selectionClick();
    setState(() => _point = p);
    _drop.forward(from: 0);
    if (move) _map.move(p, 16);
  }

  Future<void> _useMyLocation({bool silent = false}) async {
    setState(() => _locating = true);
    try {
      final here = await LocationService.current();
      if (!mounted) return;
      _place(here, move: true);
    } on LocationException catch (e) {
      if (!mounted || silent) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
        action: e.openSettings
            ? SnackBarAction(label: 'Ajustes', onPressed: LocationService.openSettings)
            : null,
      ));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _save() {
    Navigator.pop(context, MemoryPlace(point: _point, name: _name.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('¿Dónde fue?')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _point ?? LocationService.defaultCenter,
              initialZoom: _point == null ? 12 : 16,
              onTap: (_, p) => _place(p),
            ),
            children: [
              ...osmLayers(),
              if (_point != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _point!,
                    width: 60,
                    height: 72,
                    alignment: Alignment.topCenter,
                    child: AnimatedBuilder(
                      animation: _drop,
                      builder: (_, child) {
                        final t = Curves.bounceOut.transform(_drop.value);
                        return Transform.translate(offset: Offset(0, -40 * (1 - t)), child: child);
                      },
                      child: const HeartPin(),
                    ),
                  ),
                ]),
              osmAttribution(),
            ],
          ),

          // Botón "mi ubicación"
          Positioned(
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            child: FloatingActionButton.small(
              heroTag: 'here',
              tooltip: 'Usar mi ubicación',
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.lavenderDeep,
              onPressed: _locating ? null : _useMyLocation,
              child: _locating
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location_rounded),
            ),
          ),

          // Hoja inferior con nombre y guardar
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(AppSpacing.lg),
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                boxShadow: AppSpacing.softShadow,
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _point == null ? 'Toca el mapa para marcar el lugar' : 'Lugar marcado 💜',
                      style: text.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _name,
                      label: 'Nombre del lugar (opcional)',
                      icon: Icons.place_outlined,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppPrimaryButton(
                      label: 'Guardar lugar',
                      icon: Icons.check_rounded,
                      onPressed: _point == null && _name.text.trim().isEmpty ? null : _save,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
