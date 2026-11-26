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

  Memory({
    required this.id,
    required this.description,
    required this.memoryDate,
    required this.ownerUserName,
    required this.mine,
    required this.depthStatus,
    required this.photoUrl,
    required this.depthUrl,
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
      );
}
