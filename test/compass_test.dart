import 'package:arryuwu/features/capsules/data/compass.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  final zocalo = LatLng(19.4326, -99.1332);

  test('rumbo hacia el norte, este, sur y oeste', () {
    expect(Compass.bearing(zocalo, LatLng(19.45, -99.1332)), closeTo(0, 0.5));
    expect(Compass.bearing(zocalo, LatLng(19.4326, -99.10)), closeTo(90, 0.5));
    expect(Compass.bearing(zocalo, LatLng(19.40, -99.1332)), closeTo(180, 0.5));
    expect(Compass.bearing(zocalo, LatLng(19.4326, -99.16)), closeTo(270, 0.5));
  });

  test('ángulo relativo cruza bien el norte (359° ↔ 1°)', () {
    expect(Compass.relative(10, 350), closeTo(20, 1e-9)); // a la derecha
    expect(Compass.relative(350, 10), closeTo(-20, 1e-9)); // a la izquierda
    expect(Compass.relative(180, 0), closeTo(180, 1e-9));
  });
}
