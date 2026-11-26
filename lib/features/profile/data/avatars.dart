import 'dart:typed_data';

import 'package:arryuwu/core/api_client.dart';
import 'package:arryuwu/ui/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Avatar predeterminado: emoji animado (Lottie de Noto Animated Emoji, Google, CC BY 4.0)
/// sobre un degradado de la marca. Las claves deben coincidir con AvatarService.PRESETS del backend.
class AvatarPreset {
  final String key;
  final String label;
  final List<Color> colors;

  const AvatarPreset(this.key, this.label, this.colors);

  String get asset => 'assets/avatars/$key.json';
}

const _lav = [AppColors.lavenderSoft, Color(0xFFC9C3F5)];
const _pink = [Color(0xFFFDE2EF), AppColors.pink];
const _mint = [Color(0xFFDDF5EC), Color(0xFFB5E8D5)];
const _peach = [Color(0xFFFFE9D6), Color(0xFFFFCFA8)];
const _sky = [Color(0xFFDDEFFF), Color(0xFFB8DAFF)];

const avatarPresets = <AvatarPreset>[
  AvatarPreset('cat', 'Gatito', _lav),
  AvatarPreset('dog', 'Perrito', _peach),
  AvatarPreset('bunny', 'Conejito', _pink),
  AvatarPreset('bear', 'Osito', _peach),
  AvatarPreset('fox', 'Zorrito', _peach),
  AvatarPreset('panda', 'Panda', _mint),
  AvatarPreset('lion', 'León', _peach),
  AvatarPreset('frog', 'Ranita', _mint),
  AvatarPreset('penguin', 'Pingüino', _sky),
  AvatarPreset('owl', 'Búho', _lav),
  AvatarPreset('unicorn', 'Unicornio', _pink),
  AvatarPreset('octopus', 'Pulpito', _sky),
];

AvatarPreset? presetFor(String? key) {
  for (final p in avatarPresets) {
    if (p.key == key) return p;
  }
  return null;
}

/// Cambios del avatar contra /api/me/avatar. Después de cada uno hay que refrescar meProvider.
class AvatarService {
  static final ApiClient _api = ApiClient.instance;
  static final Map<String, Uint8List> _photoCache = {}; // por photoId: cambia con cada foto nueva

  static Future<void> setPreset(String key) => _api.put('/api/me/avatar', body: {'key': key});

  static Future<void> uploadPhoto(Uint8List bytes, String filename) => _api.postMultipart(
        '/api/me/avatar/photo',
        files: [UploadFile(field: 'photo', bytes: bytes, filename: filename)],
      );

  static Future<void> reset() => _api.delete('/api/me/avatar');

  /// Foto de perfil mía o de mi pareja.
  static Future<Uint8List> photo({required String photoId, required bool partner}) async {
    final cached = _photoCache[photoId];
    if (cached != null) return cached;
    final bytes = await _api.getBytes(partner ? '/api/me/partner/avatar/photo' : '/api/me/avatar/photo');
    _photoCache[photoId] = bytes;
    return bytes;
  }
}
