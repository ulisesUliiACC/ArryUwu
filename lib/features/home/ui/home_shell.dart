import 'package:arryuwu/ui/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

/// Contenedor de las pestañas principales con el menú inferior animado.
class HomeShell extends StatelessWidget {
  final StatefulNavigationShell shell;

  const HomeShell({super.key, required this.shell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
          boxShadow: AppSpacing.softShadow,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            child: SalomonBottomBar(
              currentIndex: shell.currentIndex,
              onTap: (i) {
                HapticFeedback.selectionClick();
                // Tocar la pestaña activa la regresa a su inicio.
                shell.goBranch(i, initialLocation: i == shell.currentIndex);
              },
              selectedItemColor: AppColors.lavenderDeep,
              unselectedItemColor: AppColors.inkMuted,
              items: [
                SalomonBottomBarItem(icon: const Icon(Icons.home_rounded), title: const Text('Inicio')),
                SalomonBottomBarItem(
                  icon: const Icon(Icons.favorite_rounded),
                  title: const Text('Juntos'),
                  selectedColor: AppColors.pinkDeep,
                ),
                SalomonBottomBarItem(icon: const Icon(Icons.notifications_rounded), title: const Text('Avisos')),
                SalomonBottomBarItem(icon: const Icon(Icons.person_rounded), title: const Text('Perfil')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
