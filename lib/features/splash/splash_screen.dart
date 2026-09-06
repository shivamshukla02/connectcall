import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/auth_providers.dart';
import '../../routing/app_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;
  bool _delayElapsed = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(AppConstants.splashMinDuration, () {
      _delayElapsed = true;
      _maybeNavigate();
    });
  }

  void _maybeNavigate() {
    if (_navigated || !mounted || !_delayElapsed) return;
    final authState = ref.read(authStateProvider);
    authState.whenData((user) {
      if (_navigated || !mounted) return;
      _navigated = true;
      context.go(user != null ? AppRoutes.home : AppRoutes.login);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Re-check once the auth stream delivers its first real event too,
    // in case it resolves after the minimum splash delay.
    ref.listen(authStateProvider, (_, __) => _maybeNavigate());

    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.call, color: colorScheme.onPrimary, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              AppConstants.appName,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              AppConstants.appTagline,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ],
        ),
      ),
    );
  }
}
