/// URL del backend Spring (auth_ulii).
///
/// Por defecto apunta al emulador de Android (10.0.2.2 = localhost de tu PC).
/// Para un celular físico o web, pásala al ejecutar:
///   flutter run --dart-define=API_URL=http://192.168.1.50:8080
class ApiConfig {
  static const String baseUrl =
      String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8080');

  static const Duration timeout = Duration(seconds: 15);
}
