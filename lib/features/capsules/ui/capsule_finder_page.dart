import 'dart:async';
import 'dart:math' as math;

import 'package:arryuwu/core/api_client.dart';
import 'package:arryuwu/features/capsules/data/capsule.dart';
import 'package:arryuwu/features/capsules/data/compass.dart';
import 'package:arryuwu/features/places/data/location_service.dart';
import 'package:arryuwu/ui/theme/app_tokens.dart';
import 'package:arryuwu/ui/widgets/app_button.dart';
import 'package:arryuwu/ui/widgets/state_views.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:lottie/lottie.dart';

/// Buscar una cápsula con la cámara: la tarjeta flota en la dirección del lugar (GPS + brújula).
/// Lejos muestra una flecha y los metros; dentro del radio se puede abrir.
class CapsuleFinderPage extends StatefulWidget {
  final Capsule capsule;

  const CapsuleFinderPage({super.key, required this.capsule});

  @override
  State<CapsuleFinderPage> createState() => _CapsuleFinderPageState();
}

class _CapsuleFinderPageState extends State<CapsuleFinderPage>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  /// Campo de visión horizontal aproximado de una cámara trasera de celular.
  static const _fovDegrees = 62.0;

  late Capsule _capsule = widget.capsule;
  CameraController? _camera;
  String? _cameraError;
  final _compass = Compass();
  StreamSubscription<double>? _headingSub;
  StreamSubscription<Position>? _positionSub;
  double? _heading;
  Position? _position;
  String? _locationError;
  bool _opening = false;
  bool _justOpened = false;
  late final AnimationController _bob =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _compass.start();
    _headingSub = _compass.heading.listen((h) => setState(() => _heading = h));
    _startLocation();
  }

  Future<void> _initCamera() async {
    try {
      final cams = await availableCameras();
      final back = cams.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => cams.first);
      final controller = CameraController(back, ResolutionPreset.medium, enableAudio: false);
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _camera = controller);
    } on CameraException catch (e) {
      if (mounted) {
        setState(() => _cameraError = e.code == 'CameraAccessDenied'
            ? 'Permite el uso de la cámara para ver la cápsula.'
            : 'No pudimos abrir la cámara.');
      }
    } catch (_) {
      if (mounted) setState(() => _cameraError = 'No pudimos abrir la cámara.');
    }
  }

  Future<void> _startLocation() async {
    try {
      await LocationService.current(); // pide permiso y da una primera posición
      _positionSub = Geolocator.getPositionStream(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 1,
          forceLocationManager: true,
          intervalDuration: const Duration(seconds: 1),
        ),
      ).listen(
        (p) => setState(() {
          _position = p;
          _locationError = null;
        }),
        onError: (_) => setState(() => _locationError = 'Buscando señal de GPS…'),
      );
    } on LocationException catch (e) {
      if (mounted) setState(() => _locationError = e.message);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Suelta la cámara al salir de la app y la recupera al volver.
    final cam = _camera;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _camera = null;
      cam?.dispose();
    } else if (state == AppLifecycleState.resumed && cam == null) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    _headingSub?.cancel();
    _positionSub?.cancel();
    _compass.dispose();
    _bob.dispose();
    super.dispose();
  }

  LatLng? get _here => _position == null ? null : LatLng(_position!.latitude, _position!.longitude);

  double? get _distance =>
      _here == null ? null : const Distance().as(LengthUnit.Meter, _here!, _capsule.point);

  bool get _withinReach {
    final d = _distance;
    if (d == null) return false;
    final slack = math.min(_position!.accuracy, 40.0);
    return d <= _capsule.radiusMeters + slack;
  }

  Future<void> _open() async {
    final here = _here;
    if (here == null) return;
    setState(() => _opening = true);
    try {
      final opened = await CapsuleService.open(_capsule.id, here, _position!.accuracy);
      HapticFeedback.heavyImpact();
      setState(() {
        _capsule = opened;
        _justOpened = true;
      });
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bearing = _here == null ? null : Compass.bearing(_here!, _capsule.point);
    final rel = (bearing != null && _heading != null) ? Compass.relative(bearing, _heading!) : null;
    final inView = rel != null && rel.abs() <= _fovDegrees / 2;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _cameraLayer(),

          // La cápsula flotando en la dirección del lugar.
          if (rel != null && inView)
            AnimatedBuilder(
              animation: _bob,
              builder: (_, child) {
                final x = size.width / 2 + (rel / (_fovDegrees / 2)) * (size.width / 2);
                final y = size.height * 0.42 + math.sin(_bob.value * math.pi) * 10;
                final scale = (1.5 - (_distance ?? 200) / 250).clamp(0.55, 1.35);
                return Positioned(
                  left: x - 90 * scale,
                  top: y - 110 * scale,
                  child: Transform.scale(scale: scale, alignment: Alignment.topLeft, child: child),
                );
              },
              child: _CapsuleCard(capsule: _capsule, celebrate: _justOpened),
            ),

          // Flecha hacia el lugar cuando no está en cuadro.
          if (rel != null && !inView)
            Align(
              alignment: rel < 0 ? Alignment.centerLeft : Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _TurnHint(left: rel < 0),
              ),
            ),

          // Barra superior
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(children: [
                _GlassButton(icon: Icons.arrow_back_rounded, tooltip: 'Volver', onTap: () => Navigator.pop(context)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _GlassPill(
                    child: Text(
                      _capsule.mine ? 'Tu cápsula en ${_capsule.placeLabel}' : 'Cápsula de @${_capsule.creatorUserName}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ]),
            ),
          ),

          // Panel inferior: distancia, estado y botón para abrir.
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _bottomPanel(context, rel),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cameraLayer() {
    final cam = _camera;
    if (_cameraError != null) {
      return Container(
        color: AppColors.ink,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(_cameraError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
      );
    }
    if (cam == null || !cam.value.isInitialized) return const ColoredBox(color: Colors.black);
    final preview = cam.value.previewSize!;
    // La vista previa llega en horizontal: se intercambian ancho y alto y se recorta para llenar.
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(width: preview.height, height: preview.width, child: CameraPreview(cam)),
      ),
    );
  }

  Widget _bottomPanel(BuildContext context, double? rel) {
    final d = _distance;
    final String status;
    if (_locationError != null && d == null) {
      status = _locationError!;
    } else if (d == null) {
      status = 'Buscando tu ubicación…';
    } else if (!_capsule.locked) {
      status = _justOpened ? '¡La encontraste! 💜' : 'Estás a ${_fmt(d)} · ${_capsule.placeLabel}';
    } else if (_withinReach) {
      status = '¡Llegaste! Ábrela 🎁';
    } else {
      status = 'Te faltan ${_fmt(d)}';
    }

    return _GlassPill(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Icon(_capsule.locked ? Icons.lock_rounded : Icons.lock_open_rounded, color: Colors.white),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(status,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            if (_heading == null && !_compass.unavailable)
              const Text('Calibrando…', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
          if (rel != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              rel.abs() <= _fovDegrees / 2 ? 'Está frente a ti' : (rel < 0 ? 'Gira a la izquierda' : 'Gira a la derecha'),
              style: const TextStyle(color: Colors.white70),
            ),
          ],
          if (_heading == null)
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.xs),
              child: Text('Si la dirección falla, mueve el celular dibujando un 8 en el aire.',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ),
          if (_capsule.locked && _withinReach) ...[
            const SizedBox(height: AppSpacing.md),
            AppPrimaryButton(label: 'Abrir cápsula', icon: Icons.card_giftcard_rounded, loading: _opening, onPressed: _open),
          ],
        ],
      ),
    );
  }

  static String _fmt(double m) => m >= 1000 ? '${(m / 1000).toStringAsFixed(1)} km' : '${m.round()} m';
}

/// La tarjeta que flota: cerrada es un regalo; abierta muestra el dibujo/foto y el mensaje.
class _CapsuleCard extends StatelessWidget {
  final Capsule capsule;
  final bool celebrate;

  const _CapsuleCard({required this.capsule, required this.celebrate});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (c, a) => ScaleTransition(
              scale: CurvedAnimation(parent: a, curve: Curves.elasticOut),
              child: c,
            ),
            child: capsule.locked ? _locked() : _open(),
          ),
          if (celebrate)
            IgnorePointer(child: Lottie.asset('assets/lottie/heart.json', width: 220, repeat: false)),
        ],
      ),
    );
  }

  Widget _locked() => Container(
        key: const ValueKey('locked'),
        height: 180,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.lavenderDeep, AppColors.pinkDeep]),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: [BoxShadow(color: AppColors.pinkDeep.withValues(alpha: 0.5), blurRadius: 30)],
        ),
        child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 72),
          SizedBox(height: AppSpacing.sm),
          Text('Algo te espera aquí', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _open() => Container(
        key: const ValueKey('open'),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20)],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: AspectRatio(
              aspectRatio: 1,
              child: FutureBuilder(
                future: CapsuleService.image(capsule.imageUrl!),
                builder: (_, s) => s.hasData
                    ? Image.memory(s.data!, fit: BoxFit.contain)
                    : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
          ),
          if (capsule.message != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(capsule.message!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600)),
          ],
        ]),
      );
}

class _TurnHint extends StatelessWidget {
  final bool left;

  const _TurnHint({required this.left});

  @override
  Widget build(BuildContext context) => _GlassPill(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Icon(left ? Icons.arrow_back_ios_new_rounded : Icons.arrow_forward_ios_rounded,
            color: Colors.white, size: 32),
      );
}

class _GlassPill extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _GlassPill({required this.child, this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10)});

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: child,
      );
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _GlassButton({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.black.withValues(alpha: 0.45),
        shape: const CircleBorder(),
        child: IconButton(tooltip: tooltip, onPressed: onTap, icon: Icon(icon, color: Colors.white)),
      );
}
