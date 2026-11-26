import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'token_storage.dart';

/// Error de la API con un mensaje listo para mostrar al usuario.
class ApiException implements Exception {
  final int? statusCode;
  final String message;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Se lanza cuando la sesión venció y no se pudo renovar: hay que volver al login.
class SessionExpiredException extends ApiException {
  SessionExpiredException()
      : super('Tu sesión expiró. Inicia sesión de nuevo.', statusCode: 401);
}

/// Archivo para enviar en una petición multipart.
class UploadFile {
  final String field;
  final Uint8List bytes;
  final String filename;

  UploadFile({required this.field, required this.bytes, required this.filename});
}

/// Cliente HTTP del backend.
/// - Agrega `Authorization: Bearer <token>` a las peticiones autenticadas.
/// - Si el backend responde 401, renueva el token con /auth/refresh-token y reintenta una vez.
/// - Convierte las respuestas de error ({"error": "..."} o {campo: mensaje}) en [ApiException].
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  final http.Client _http = http.Client();
  Future<bool>? _refreshing; // evita renovar el token dos veces en paralelo

  /// Se llama cuando la sesión venció y no se pudo renovar (el AuthController manda al login).
  void Function()? onSessionExpired;

  Future<dynamic> get(String path) async => _json(await _execute(() => _jsonRequest('GET', path)));

  Future<dynamic> post(String path, {Object? body, bool auth = true}) async =>
      _json(await _execute(() => _jsonRequest('POST', path, body: body), auth: auth));

  Future<dynamic> put(String path, {Object? body}) async =>
      _json(await _execute(() => _jsonRequest('PUT', path, body: body)));

  Future<dynamic> delete(String path) async => _json(await _execute(() => _jsonRequest('DELETE', path)));

  /// Descarga binaria autenticada (p. ej. fotos de recuerdos).
  Future<Uint8List> getBytes(String path, {Duration? timeout}) async =>
      (await _execute(() => _jsonRequest('GET', path), timeout: timeout)).bodyBytes;

  /// POST multipart/form-data con campos de texto y archivos.
  Future<dynamic> postMultipart(String path,
      {Map<String, String> fields = const {}, List<UploadFile> files = const []}) async {
    return _json(await _execute(() {
      final request = http.MultipartRequest('POST', _uri(path))..fields.addAll(fields);
      for (final f in files) {
        request.files.add(http.MultipartFile.fromBytes(f.field, f.bytes, filename: f.filename));
      }
      return request;
    }, timeout: const Duration(seconds: 60)));
  }

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  http.BaseRequest _jsonRequest(String method, String path, {Object? body}) {
    final request = http.Request(method, _uri(path))
      ..headers['Content-Type'] = 'application/json';
    if (body != null) request.body = jsonEncode(body);
    return request;
  }

  /// Envía la petición (construida de nuevo en cada intento) y maneja auth, refresh y errores.
  Future<http.Response> _execute(http.BaseRequest Function() build,
      {bool auth = true, bool retried = false, Duration? timeout}) async {
    final request = build();
    if (auth) {
      final token = await TokenStorage.accessToken;
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
    }

    final http.Response response;
    try {
      response = await http.Response.fromStream(
          await _http.send(request).timeout(timeout ?? ApiConfig.timeout));
    } on TimeoutException {
      throw ApiException('El servidor tardó demasiado en responder.');
    } on Exception {
      // SocketException / ClientException (sin dart:io para que también compile en web)
      throw ApiException('No se pudo conectar con el servidor. Revisa tu conexión.');
    }

    if (response.statusCode == 401 && auth && !retried) {
      if (await _refreshTokens()) {
        return _execute(build, auth: auth, retried: true, timeout: timeout);
      }
      await TokenStorage.clear();
      onSessionExpired?.call();
      throw SessionExpiredException();
    }

    if (response.statusCode >= 200 && response.statusCode < 300) return response;
    throw ApiException(_errorMessage(_decode(response), response.statusCode),
        statusCode: response.statusCode);
  }

  Future<bool> _refreshTokens() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _doRefresh() async {
    final refreshToken = await TokenStorage.refreshToken;
    if (refreshToken == null) return false;
    try {
      final data = await post('/auth/refresh-token',
          body: {'refreshToken': refreshToken}, auth: false);
      await TokenStorage.save(
        accessToken: data['token'],
        refreshToken: data['refreshToken'],
        username: data['username'],
      );
      return true;
    } on ApiException {
      return false;
    }
  }

  static dynamic _json(http.Response response) => _decode(response);

  static dynamic _decode(http.Response response) {
    if (response.body.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      return response.body;
    }
  }

  static String _errorMessage(dynamic decoded, int status) {
    if (decoded is Map) {
      if (decoded['error'] is String) return decoded['error'];
      // Errores de validación: {"email": "Debe ser válido", ...}
      final messages = decoded.values.whereType<String>();
      if (messages.isNotEmpty) return messages.join('\n');
    }
    if (decoded is String && decoded.isNotEmpty) return decoded;
    return 'Error inesperado ($status).';
  }
}
