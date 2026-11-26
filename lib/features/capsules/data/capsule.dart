import 'dart:typed_data';

import 'package:arryuwu/core/api_client.dart';
import 'package:latlong2/latlong.dart';

/// Cápsula dejada en un lugar real. Si es de mi pareja y no la he abierto, [locked] es true
/// y no trae mensaje ni imagen.
class Capsule {
  final int id;
  final String creatorUserName;
  final bool mine;
  final bool locked;
  final String? message;
  final String? imageUrl;
  final LatLng point;
  final String? placeName;
  final int radiusMeters;
  final DateTime? openedAt;
  final DateTime createdAt;

  Capsule({
    required this.id,
    required this.creatorUserName,
    required this.mine,
    required this.locked,
    required this.message,
    required this.imageUrl,
    required this.point,
    required this.placeName,
    required this.radiusMeters,
    required this.openedAt,
    required this.createdAt,
  });

  String get placeLabel => (placeName != null && placeName!.trim().isNotEmpty) ? placeName! : 'Un lugar especial';

  factory Capsule.fromJson(Map<String, dynamic> j) => Capsule(
        id: j['id'],
        creatorUserName: j['creatorUserName'],
        mine: j['mine'] == true,
        locked: j['locked'] == true,
        message: j['message'],
        imageUrl: j['imageUrl'],
        point: LatLng((j['latitude'] as num).toDouble(), (j['longitude'] as num).toDouble()),
        placeName: j['placeName'],
        radiusMeters: j['radiusMeters'] ?? 60,
        openedAt: j['openedAt'] == null ? null : DateTime.parse(j['openedAt']),
        createdAt: DateTime.parse(j['createdAt']),
      );
}

/// Cápsulas contra /api/capsules.
class CapsuleService {
  static final ApiClient _api = ApiClient.instance;
  static final Map<String, Uint8List> _imageCache = {};

  static Future<List<Capsule>> list() async {
    final data = await _api.get('/api/capsules') as List<dynamic>;
    return data.map((e) => Capsule.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Capsule> create({
    required Uint8List image,
    required String filename,
    required LatLng point,
    String? message,
    String? placeName,
  }) async {
    final data = await _api.postMultipart('/api/capsules', fields: {
      'latitude': point.latitude.toString(),
      'longitude': point.longitude.toString(),
      if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
      if (placeName != null && placeName.trim().isNotEmpty) 'placeName': placeName.trim(),
    }, files: [
      UploadFile(field: 'image', bytes: image, filename: filename),
    ]);
    return Capsule.fromJson(data);
  }

  /// Intenta abrirla desde donde estoy. Si estoy lejos el backend responde 409 con los metros que faltan.
  static Future<Capsule> open(int id, LatLng here, double accuracy) async => Capsule.fromJson(
        await _api.post('/api/capsules/$id/open', body: {
          'latitude': here.latitude,
          'longitude': here.longitude,
          'accuracy': accuracy,
        }),
      );

  static Future<void> delete(int id) => _api.delete('/api/capsules/$id');

  static Future<Uint8List> image(String url) async {
    final cached = _imageCache[url];
    if (cached != null) return cached;
    final bytes = await _api.getBytes(url);
    _imageCache[url] = bytes;
    return bytes;
  }
}
