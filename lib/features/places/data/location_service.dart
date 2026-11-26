import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Error de ubicación con un mensaje listo para mostrar.
class LocationException implements Exception {
  final String message;
  final bool openSettings; // true si el usuario debe ir a Ajustes para arreglarlo

  LocationException(this.message, {this.openSettings = false});

  @override
  String toString() => message;
}

/// Ubicación actual del celular.
///
/// Usa el LocationManager de Android directamente (forceLocationManager) en lugar de los servicios
/// de Google, porque muchos Huawei no los tienen.
class LocationService {
  /// Centro por defecto del mapa si no hay ubicación: Ciudad de México.
  static final defaultCenter = LatLng(19.4326, -99.1332);

  static Future<LatLng> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw LocationException('Activa la ubicación del celular para usar tu lugar actual.', openSettings: true);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw LocationException('Necesitamos permiso de ubicación para marcar dónde estás.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationException('El permiso de ubicación está bloqueado. Actívalo en Ajustes.', openSettings: true);
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
          forceLocationManager: true,
          timeLimit: const Duration(seconds: 20),
        ),
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      // Sin señal GPS a tiempo: usa la última conocida si existe.
      final last = await Geolocator.getLastKnownPosition(forceAndroidLocationManager: true);
      if (last != null) return LatLng(last.latitude, last.longitude);
      throw LocationException('No pudimos obtener tu ubicación. Intenta cerca de una ventana o elige en el mapa.');
    }
  }

  static Future<void> openSettings() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }
}
