import 'package:latlong2/latlong.dart';

/// Lugar de un recuerdo: coordenadas (opcionales) y un nombre (opcional).
class MemoryPlace {
  final LatLng? point;
  final String? name;

  const MemoryPlace({this.point, this.name});

  bool get hasPoint => point != null;

  /// Texto para mostrar: el nombre o, si no hay, las coordenadas cortas.
  String get label =>
      (name != null && name!.trim().isNotEmpty)
          ? name!
          : point == null
              ? 'Lugar sin nombre'
              : '${point!.latitude.toStringAsFixed(4)}, ${point!.longitude.toStringAsFixed(4)}';

  static MemoryPlace? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final lat = (json['latitude'] as num?)?.toDouble();
    final lng = (json['longitude'] as num?)?.toDouble();
    return MemoryPlace(
      point: lat != null && lng != null ? LatLng(lat, lng) : null,
      name: json['name'],
    );
  }
}

/// Recuerdo de la pareja tal como lo devuelve GET /api/memories.
class Memory {
  final int id;
  final String? description;
  final DateTime memoryDate;
  final String ownerUserName;
  final bool mine;
  final String depthStatus; // PENDING | READY | FAILED
  final String photoUrl;
  final String? depthUrl;
  final MemoryPlace? place;

  Memory({
    required this.id,
    required this.description,
    required this.memoryDate,
    required this.ownerUserName,
    required this.mine,
    required this.depthStatus,
    required this.photoUrl,
    required this.depthUrl,
    this.place,
  });

  bool get depthReady => depthStatus == 'READY';
  bool get depthPending => depthStatus == 'PENDING';

  factory Memory.fromJson(Map<String, dynamic> json) => Memory(
        id: json['id'],
        description: json['description'],
        memoryDate: DateTime.parse(json['memoryDate']),
        ownerUserName: json['ownerUserName'],
        mine: json['mine'] == true,
        depthStatus: json['depthStatus'],
        photoUrl: json['photoUrl'],
        depthUrl: json['depthUrl'],
        place: MemoryPlace.fromJson(json['place'] as Map<String, dynamic>?),
      );
}
