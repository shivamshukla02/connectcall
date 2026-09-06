import 'package:go_router/go_router.dart';

import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/home/home_screen.dart';
import '../features/splash/splash_screen.dart';

/// Route names as constants — avoids typo'd string literals in
/// context.go('/soem-typo') scattered across the app.
class AppRoutes {
  AppRoutes._();
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const editProfile = '/edit-profile';
  // contacts, profile, call, incoming-call, history routes are added
  // in Phase 3/4/5 as those features land.
}

/// Kept as a plain GoRouter for Phase 1. In Phase 2 this becomes a
/// Riverpod provider (router_provider.dart) so it can redirect based on
/// live Firebase auth state instead of only the splash screen deciding.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);
