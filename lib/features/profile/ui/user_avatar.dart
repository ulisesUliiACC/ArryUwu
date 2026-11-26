import 'package:arryuwu/features/home/data/me.dart';
import 'package:arryuwu/features/profile/data/avatars.dart';
import 'package:arryuwu/ui/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Avatar circular de Arry: foto propia, emoji animado predeterminado o la inicial del nombre.
class UserAvatar extends StatelessWidget {
  final AvatarInfo avatar;
  final String initial;
  final double size;
  final bool partner; // true = es el avatar de mi pareja (la foto se pide a otra ruta)
  final bool animate;
  final double borderWidth;

  const UserAvatar({
    super.key,
    required this.avatar,
    required this.initial,
    this.size = 48,
    this.partner = false,
    this.animate = true,
    this.borderWidth = 0,
  });

  @override
  Widget build(BuildContext context) {
    final preset = presetFor(avatar.key);
    Widget child;
    List<Color> colors = const [AppColors.lavenderDeep, AppColors.pinkDeep];

    if (avatar.hasPhoto) {
      child = FutureBuilder(
        future: AvatarService.photo(photoId: avatar.photoId!, partner: partner),
        builder: (context, snap) => snap.hasData
            ? Image.memory(snap.data!, fit: BoxFit.cover, width: size, height: size, gaplessPlayback: true)
            : _Initial(initial: initial, size: size),
      );
    } else if (preset != null) {
      colors = preset.colors;
      child = Padding(
        padding: EdgeInsets.all(size * 0.12),
        child: Lottie.asset(preset.asset, animate: animate, repeat: true, frameRate: FrameRate(30)),
      );
    } else {
      child = _Initial(initial: initial, size: size);
    }

    return Semantics(
      image: true,
      label: preset != null ? 'Avatar: ${preset.label}' : 'Avatar',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
          border: borderWidth > 0 ? Border.all(color: Colors.white, width: borderWidth) : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

class _Initial extends StatelessWidget {
  final String initial;
  final double size;

  const _Initial({required this.initial, required this.size});

  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          initial.isEmpty ? '·' : initial,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontSize: size * 0.42),
        ),
      );
}
