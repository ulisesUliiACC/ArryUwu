import 'package:arryuwu/core/api_client.dart';
import 'package:arryuwu/features/auth/data/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Avatar de un usuario: un predeterminado animado ([key]), una foto propia ([photoId]) o ninguno (inicial).
class AvatarInfo {
  final String? key;
  final String? photoId;

  const AvatarInfo({this.key, this.photoId});

  static const none = AvatarInfo();

  bool get hasPhoto => photoId != null;
  bool get hasPreset => key != null;

  static AvatarInfo fromJson(Map<String, dynamic>? json) =>
      json == null ? none : AvatarInfo(key: json['key'], photoId: json['photoId']);
}

/// Pareja vinculada (de GET /api/me).
class Partner {
  final String userName;
  final String? nombre;
  final DateTime? linkedSince;
  final AvatarInfo avatar;

  Partner({required this.userName, this.nombre, this.linkedSince, this.avatar = AvatarInfo.none});

  String get displayName => (nombre != null && nombre!.trim().isNotEmpty) ? nombre! : '@$userName';

  String get initial {
    final s = displayName.replaceFirst('@', '');
    return s.isEmpty ? '' : s.substring(0, 1).toUpperCase();
  }

  /// Días que llevan vinculados en Arry (cuenta el primer día).
  int? get daysTogether =>
      linkedSince == null ? null : DateTime.now().difference(linkedSince!).inDays + 1;
}

/// Usuario autenticado y su pareja.
class Me {
  final String userName;
  final String? nombre;
  final String? apellido;
  final String email;
  final AvatarInfo avatar;
  final Partner? partner;

  Me({
    required this.userName,
    this.nombre,
    this.apellido,
    required this.email,
    this.avatar = AvatarInfo.none,
    this.partner,
  });

  String get firstName => (nombre != null && nombre!.trim().isNotEmpty) ? nombre!.split(' ').first : userName;

  String get initial => firstName.isEmpty ? '' : firstName.substring(0, 1).toUpperCase();

  factory Me.fromJson(Map<String, dynamic> json) {
    final p = json['partner'] as Map<String, dynamic>?;
    return Me(
      userName: json['userName'],
      nombre: json['nombre'],
      apellido: json['apellido'],
      email: json['email'],
      avatar: AvatarInfo.fromJson(json['avatar'] as Map<String, dynamic>?),
      partner: p == null
          ? null
          : Partner(
              userName: p['userName'],
              nombre: p['nombre'],
              linkedSince: p['linkedSince'] == null ? null : DateTime.parse(p['linkedSince']),
              avatar: AvatarInfo.fromJson(p['avatar'] as Map<String, dynamic>?),
            ),
    );
  }
}

/// Se recarga solo cuando cambia el usuario con sesión.
final meProvider = FutureProvider<Me>((ref) async {
  ref.watch(authProvider.select((s) => s.username));
  return Me.fromJson(await ApiClient.instance.get('/api/me'));
});
