import 'package:arryuwu/features/memories/data/memory_service.dart';
import 'package:arryuwu/ui/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Imagen del backend que necesita el token (no sirve Image.network directo).
class AuthImage extends StatelessWidget {
  final String url;
  final BoxFit fit;

  const AuthImage(this.url, {super.key, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: MemoryService.image(url),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(snapshot.data!, fit: fit, gaplessPlayback: true);
        }
        return Container(
          color: AppColors.lavenderSoft,
          alignment: Alignment.center,
          child: snapshot.hasError
              ? const Icon(Icons.broken_image_outlined, color: AppColors.inkMuted)
              : const SizedBox(
                  width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
    );
  }
}
