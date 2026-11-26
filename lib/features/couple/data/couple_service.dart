import 'package:arryuwu/core/api_client.dart';

/// Código de invitación recién generado.
class Invitation {
  final String code;
  final DateTime expiresAt;

  Invitation({required this.code, required this.expiresAt});

  factory Invitation.fromJson(Map<String, dynamic> json) => Invitation(
        code: json['invitationCode'] as String,
        expiresAt: DateTime.fromMillisecondsSinceEpoch((json['expirationTime'] as num).toInt()),
      );
}

/// Resultado de vincularse con el código de la pareja.
class LinkResult {
  final String? creatorUserName;
  final String? linkedUserName;

  LinkResult({this.creatorUserName, this.linkedUserName});

  factory LinkResult.fromJson(Map<String, dynamic> json) => LinkResult(
        creatorUserName: json['creatorUserName'] as String?,
        linkedUserName: json['linkedUserName'] as String?,
      );
}

/// Vinculación de la pareja con códigos de invitación. Lanza [ApiException] con el mensaje del backend.
class CoupleService {
  /// Código corto (9 caracteres, 5 min) o UUID (1 h) si [short] es false.
  static Future<Invitation> generate({bool short = true}) async {
    final data = await ApiClient.instance.post('/api/invites/generate?isShortCode=$short');
    return Invitation.fromJson(data as Map<String, dynamic>);
  }

  static Future<LinkResult> link(String code) async {
    final data = await ApiClient.instance
        .post('/api/invites/link?invitationCode=${Uri.encodeQueryComponent(code.trim())}');
    return LinkResult.fromJson(data as Map<String, dynamic>);
  }

  /// Devuelve el mensaje de confirmación del backend.
  static Future<String> unlink(String code) async {
    final data = await ApiClient.instance
        .post('/api/invites/unlink?invitationCode=${Uri.encodeQueryComponent(code.trim())}');
    return (data is Map && data['message'] is String) ? data['message'] as String : 'Listo.';
  }
}
