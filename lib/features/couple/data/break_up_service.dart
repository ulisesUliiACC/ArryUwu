import 'package:arryuwu/core/api_client.dart';
import 'package:share_plus/share_plus.dart';

/// Terminar el lazo con la pareja y la copia de respaldo previa.
class BreakUpService {
  static final ApiClient _api = ApiClient.instance;

  /// Descarga la copia (ZIP con recuerdos, cápsulas y lienzo) y abre el menú para guardarla
  /// o enviarla (Archivos, Drive, WhatsApp...). Devuelve true si el usuario la compartió/guardó.
  static Future<bool> downloadAndShareCopy() async {
    final bytes = await _api.getBytes('/api/me/export', timeout: const Duration(minutes: 2));
    final date = DateTime.now().toIso8601String().substring(0, 10);
    final result = await SharePlus.instance.share(ShareParams(
      files: [XFile.fromData(bytes, mimeType: 'application/zip', name: 'arry-copia-$date.zip')],
      fileNameOverrides: ['arry-copia-$date.zip'],
      subject: 'Copia de Arry',
    ));
    return result.status == ShareResultStatus.success;
  }

  /// Rompe el lazo. Con [deleteData] borra para siempre lo propio y lo compartido.
  static Future<String> breakUp({required bool deleteData}) async {
    final data = await _api.delete('/api/me/partner?deleteData=$deleteData');
    return (data as Map<String, dynamic>)['message'] as String? ?? 'El lazo terminó.';
  }
}
