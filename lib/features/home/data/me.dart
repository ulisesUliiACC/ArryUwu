import 'package:arryuwu/core/api_client.dart';
import 'package:arryuwu/features/auth/data/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pareja vinculada (de GET /api/me).
class Partner {
  final String userName;
  final String? nombre;
  final DateTime? linkedSince;

  Partner({required this.userName, this.nombre, this.linkedSince});

  String get displayName => (nombre != null && nombre!.trim().isNotEmpty) ? nombre! : '@$userName';

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
  final Partner? partner;

  Me({required this.userName, this.nombre, this.apellido, required this.email, this.partner});

  String get firstName => (nombre != null && nombre!.trim().isNotEmpty) ? nombre!.split(' ').first : userName;

  factory Me.fromJson(Map<String, dynamic> json) {
    final p = json['partner'] as Map<String, dynamic>?;
    return Me(
      userName: json['userName'],
      nombre: json['nombre'],
      apellido: json['apellido'],
      email: json['email'],
      partner: p == null
          ? null
          : Partner(
              userName: p['userName'],
              nombre: p['nombre'],
              linkedSince: p['linkedSince'] == null ? null : DateTime.parse(p['linkedSince']),
            ),
    );
  }
}

/// Se recarga solo cuando cambia el usuario con sesión.
final meProvider = FutureProvider<Me>((ref) async {
  ref.watch(authProvider.select((s) => s.username));
  return Me.fromJson(await ApiClient.instance.get('/api/me'));
});
