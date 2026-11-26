import 'package:arryuwu/Home/Screens/Activity/ActivityPage.dart';
import 'package:arryuwu/Home/Screens/Activity/DetailActivityPage.dart';
import 'package:arryuwu/Home/Screens/Code/CodePage.dart';
import 'package:arryuwu/Home/Screens/Drawer/Drawing.dart';
import 'package:arryuwu/Home/Screens/Notify/NotifyPage.dart';
import 'package:arryuwu/Home/Screens/Profile/ProfilePage.dart';
import 'package:arryuwu/Home/Screens/Questions/QuestionsPage.dart';
import 'package:arryuwu/features/auth/data/auth_controller.dart';
import 'package:arryuwu/features/auth/ui/login_page.dart';
import 'package:arryuwu/features/auth/ui/register_page.dart';
import 'package:arryuwu/features/auth/ui/splash_page.dart';
import 'package:arryuwu/features/home/ui/home_page.dart';
import 'package:arryuwu/features/home/ui/home_shell.dart';
import 'package:arryuwu/features/memories/ui/memories_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Rutas de la app. La redirección decide sola a dónde ir según la sesión:
/// sin saber aún → /splash, sin sesión → /login, con sesión → fuera de las pantallas de acceso.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider).status;
      final loc = state.matchedLocation;
      final onAuthScreen = loc == '/login' || loc == '/register';

      if (auth == AuthStatus.unknown) return loc == '/splash' ? null : '/splash';
      if (auth == AuthStatus.signedOut) return onAuthScreen ? null : '/login';
      if (loc == '/splash' || onAuthScreen) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/login', pageBuilder: (_, s) => _fade(s, const LoginPage())),
      GoRoute(path: '/register', pageBuilder: (_, s) => _slideUp(s, const RegisterPage())),

      // Pestañas con menú inferior; cada una conserva su estado al cambiar.
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, __) => const HomePage())]),
          StatefulShellBranch(routes: [GoRoute(path: '/activities', builder: (_, __) => const ActivityPage())]),
          StatefulShellBranch(routes: [GoRoute(path: '/notifications', builder: (_, __) => const Notifypage())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, __) => const ProfilePage())]),
        ],
      ),

      GoRoute(path: '/memories', builder: (_, __) => const MemoriesPage()),
      GoRoute(path: '/questions', builder: (_, __) => const QuestionsPage()),
      GoRoute(path: '/notes', builder: (_, __) => const DrawingBoard()),
      GoRoute(path: '/code', builder: (_, __) => const CodePage()),
      GoRoute(
        path: '/activity',
        builder: (_, s) => DetailActivityPage(title: s.extra as String? ?? 'Actividades'),
      ),
    ],
  );
});

CustomTransitionPage<void> _fade(GoRouterState state, Widget child) => CustomTransitionPage(
      key: state.pageKey,
      transitionDuration: const Duration(milliseconds: 400),
      child: child,
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut), child: child),
    );

CustomTransitionPage<void> _slideUp(GoRouterState state, Widget child) => CustomTransitionPage(
      key: state.pageKey,
      transitionDuration: const Duration(milliseconds: 350),
      child: child,
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(curved),
            child: child,
          ),
        );
      },
    );
