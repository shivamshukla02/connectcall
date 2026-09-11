import 'package:go_router/go_router.dart';

import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/home/home_screen.dart';
import '../features/profile/edit_profile_screen.dart';
import '../features/splash/splash_screen.dart';

/// Route names as constants — avoids typo'd string literals in
/// context.go('/soem-typo') scattered across the app.
class AppRoutes {
  AppRoutes._();
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const editProfile = '/home/edit-profile';
  // call, incoming-call, history routes are added in Phase 4/5/7.
}

/// Kept as a plain GoRouter for now. Router only needs auth-state redirects
/// if we want deep-link protection; splash screen already gates entry.
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
      routes: [
        GoRoute(
          path: 'edit-profile',
          builder: (context, state) => const EditProfileScreen(),
        ),
      ],
    ),
  ],
);
