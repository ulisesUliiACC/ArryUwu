import 'package:arryuwu/core/api_client.dart';
import 'package:arryuwu/core/token_storage.dart';

/// Operaciones de cuenta contra /auth del backend.
class AuthService {
  static final ApiClient _api = ApiClient.instance;

  /// Inicia sesión con correo o nombre de usuario y guarda los tokens.
  static Future<String> login(String usernameOrEmail, String password) async {
    final data = await _api.post('/auth/login', auth: false, body: {
      'usernameOrEmail': usernameOrEmail.trim(),
      'password': password,
    });
    await TokenStorage.save(
      accessToken: data['token'],
      refreshToken: data['refreshToken'],
      username: data['username'],
    );
    return data['username'];
  }

  static Future<void> register({
    required String userName,
    required String nombre,
    required String apellido,
    required String email,
    required String password,
  }) async {
    await _api.post('/auth/register', auth: false, body: {
      'userName': userName.trim(),
      'nombre': nombre.trim(),
      'apellido': apellido.trim(),
      'email': email.trim(),
      'password': password,
    });
  }

  static Future<void> updatePassword(String oldPassword, String newPassword) async {
    await _api.post('/auth/update-password', body: {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    });
  }

  /// Hay sesión si existe un refresh token guardado (el access token se renueva solo).
  static Future<bool> hasSession() async => (await TokenStorage.refreshToken) != null;

  static Future<void> logout() => TokenStorage.clear();
}
