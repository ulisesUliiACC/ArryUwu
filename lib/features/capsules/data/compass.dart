import 'dart:async';
import 'dart:math' as math;

import 'package:latlong2/latlong.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Brújula para la vista de cámara: hacia dónde apunta la cámara trasera, en grados (0 = norte, 90 = este).
///
/// Combina acelerómetro (dónde está "arriba") y magnetómetro (dónde está el norte magnético):
/// Este = magnético × arriba, Norte = arriba × Este. La cámara mira hacia -Z del celular, así que el
/// rumbo es el ángulo de -Z proyectado en el plano horizontal. Funciona con el celular de pie o inclinado.
/// No usa servicios de Google, así que sirve en Huawei.
class Compass {
  final _controller = StreamController<double>.broadcast();
  StreamSubscription<AccelerometerEvent>? _accSub;
  StreamSubscription<MagnetometerEvent>? _magSub;

  List<double>? _acc;
  List<double>? _mag;
  double? _heading;

  /// true si el celular no tiene magnetómetro (la vista mostrará solo la flecha por distancia).
  bool unavailable = false;

  Stream<double> get heading => _controller.stream;

  void start() {
    const period = SensorInterval.gameInterval;
    _accSub = accelerometerEventStream(samplingPeriod: period).listen(
      (e) => _acc = _lowPass([e.x, e.y, e.z], _acc, 0.15),
      onError: (_) => unavailable = true,
    );
    _magSub = magnetometerEventStream(samplingPeriod: period).listen(
      (e) {
        _mag = _lowPass([e.x, e.y, e.z], _mag, 0.15);
        _update();
      },
      onError: (_) => unavailable = true,
    );
  }

  void _update() {
    final a = _acc, m = _mag;
    if (a == null || m == null) return;
    final up = _normalize(a);
    if (up == null) return;
    final east = _normalize(_cross(m, up));
    if (east == null) return;
    final north = _cross(up, east);
    // Cámara = (0, 0, -1) en coordenadas del celular.
    final h = (math.atan2(-east[2], -north[2]) * 180 / math.pi + 360) % 360;
    // Suavizado circular (evita saltos entre 359° y 0°).
    _heading = _heading == null ? h : _heading! + _shortestDelta(_heading!, h) * 0.2;
    _heading = (_heading! + 360) % 360;
    _controller.add(_heading!);
  }

  void dispose() {
    _accSub?.cancel();
    _magSub?.cancel();
    _controller.close();
  }

  static List<double> _lowPass(List<double> input, List<double>? prev, double alpha) =>
      prev == null ? input : [for (var i = 0; i < 3; i++) prev[i] + alpha * (input[i] - prev[i])];

  static List<double> _cross(List<double> a, List<double> b) =>
      [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];

  static List<double>? _normalize(List<double> v) {
    final n = math.sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);
    return n < 1e-6 ? null : [v[0] / n, v[1] / n, v[2] / n];
  }

  /// Diferencia más corta de [from] a [to] en grados, en (-180, 180].
  static double _shortestDelta(double from, double to) {
    var d = (to - from) % 360;
    if (d > 180) d -= 360;
    if (d <= -180) d += 360;
    return d;
  }

  /// Rumbo inicial de [from] a [to] en grados (0 = norte).
  static double bearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * math.pi / 180, lat2 = to.latitude * math.pi / 180;
    final dLon = (to.longitude - from.longitude) * math.pi / 180;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  /// Ángulo relativo en (-180, 180]: negativo = la cápsula está a la izquierda.
  static double relative(double bearing, double heading) => _shortestDelta(heading, bearing);
}
