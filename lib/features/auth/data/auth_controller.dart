import 'package:arryuwu/core/api_client.dart';
import 'package:arryuwu/core/token_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_service.dart';

enum AuthStatus { unknown, signedIn, signedOut }

class AuthState {
  final AuthStatus status;
  final String? username;

  const AuthState._(this.status, this.username);

  const AuthState.unknown() : this._(AuthStatus.unknown, null);
  const AuthState.signedIn(String username) : this._(AuthStatus.signedIn, username);
  const AuthState.signedOut() : this._(AuthStatus.signedOut, null);
}

/// Estado de la sesión. El router lo escucha para mandar al login o al Home sin que
/// ninguna pantalla tenga que navegar a mano.
class AuthController extends Notifier<AuthState> {
  /// Tiempo mínimo de la pantalla de inicio, para que la animación se alcance a ver.
  static const splashMinimum = Duration(milliseconds: 2200);

  @override
  AuthState build() {
    ApiClient.instance.onSessionExpired = () => state = const AuthState.signedOut();
    _restore();
    return const AuthState.unknown();
  }

  Future<void> _restore() async {
    final minimum = Future<void>.delayed(splashMinimum);
    final hasSession = await AuthService.hasSession();
    await minimum;
    final username = await TokenStorage.username;
    state = hasSession && username != null ? AuthState.signedIn(username) : const AuthState.signedOut();
  }

  /// Lanza [ApiException] si falla, para que la pantalla muestre el mensaje.
  Future<void> login(String usernameOrEmail, String password) async {
    final username = await AuthService.login(usernameOrEmail, password);
    state = AuthState.signedIn(username);
  }

  Future<void> register({
    required String userName,
    required String nombre,
    required String apellido,
    required String email,
    required String password,
  }) async {
    await AuthService.register(
      userName: userName,
      nombre: nombre,
      apellido: apellido,
      email: email,
      password: password,
    );
    await login(userName, password);
  }

  Future<void> logout() async {
    await AuthService.logout();
    state = const AuthState.signedOut();
  }
}

final authProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);
