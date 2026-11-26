import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda los tokens cifrados (Keystore en Android, Keychain en iOS), no en SharedPreferences.
class TokenStorage {
  static const _storage = FlutterSecureStorage();

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _usernameKey = 'username';

  static Future<void> save({
    required String accessToken,
    required String refreshToken,
    required String username,
  }) async {
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
    await _storage.write(key: _usernameKey, value: username);
  }

  static Future<String?> get accessToken => _storage.read(key: _accessKey);
  static Future<String?> get refreshToken => _storage.read(key: _refreshKey);
  static Future<String?> get username => _storage.read(key: _usernameKey);

  static Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _usernameKey);
  }
}
