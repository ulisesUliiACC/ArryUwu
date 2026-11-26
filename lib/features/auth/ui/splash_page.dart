import 'package:arryuwu/ui/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

/// Pantalla de inicio: degradado suave, corazón animado y el nombre de la app.
/// No navega por sí misma: el router la cambia cuando AuthController sabe si hay sesión.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = CurvedAnimation(parent: _controller, curve: const Interval(0.35, 1, curve: Curves.easeOutCubic));
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.lavenderSoft, AppColors.background, Color(0xFFFDE7F2)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
                child: Lottie.asset('assets/lottie/loading_animation.json', width: 180),
              ),
              const SizedBox(height: AppSpacing.lg),
              FadeTransition(
                opacity: title,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(title),
                  child: Column(
                    children: [
                      Text(
                        'Arry',
                        style: GoogleFonts.poppins(
                          fontSize: 44,
                          fontWeight: FontWeight.w700,
                          color: AppColors.lavenderDeep,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text('Su lugar, solo de ustedes dos',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
