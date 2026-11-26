import 'dart:typed_data';

import 'package:arryuwu/core/api_client.dart';

import 'memory.dart';

/// Recuerdos de la pareja contra /api/memories.
class MemoryService {
  static final ApiClient _api = ApiClient.instance;

  // Las imágenes no cambian nunca (nombre único en el servidor), así que se guardan en memoria.
  static final Map<String, Uint8List> _imageCache = {};

  static Future<List<Memory>> list() async {
    final data = await _api.get('/api/memories') as List<dynamic>;
    return data.map((e) => Memory.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Memory> get(int id) async =>
      Memory.fromJson(await _api.get('/api/memories/$id'));

  static Future<Memory> create({
    required Uint8List photo,
    required String filename,
    required DateTime date,
    String? description,
  }) async {
    final data = await _api.postMultipart('/api/memories', fields: {
      'memoryDate': _isoDate(date),
      if (description != null && description.trim().isNotEmpty) 'description': description.trim(),
    }, files: [
      UploadFile(field: 'photo', bytes: photo, filename: filename),
    ]);
    return Memory.fromJson(data);
  }

  static Future<void> delete(int id) => _api.delete('/api/memories/$id');

  /// Pide al backend rehacer el efecto 3D; el recuerdo vuelve a PENDING.
  static Future<Memory> regenerateDepth(int id) async {
    _imageCache.remove('/api/memories/$id/depth'); // el mapa nuevo tendrá la misma URL
    return Memory.fromJson(await _api.post('/api/memories/$id/depth'));
  }

  static Future<Uint8List> image(String url) async {
    final cached = _imageCache[url];
    if (cached != null) return cached;
    final bytes = await _api.getBytes(url);
    _imageCache[url] = bytes;
    return bytes;
  }

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

const _meses = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
];

/// "14 de febrero de 2026"
String formatFecha(DateTime d) => '${d.day} de ${_meses[d.month - 1]} de ${d.year}';
