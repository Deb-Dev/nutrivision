import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nutrivision/features/auth/presentation/providers/auth_notifier_simple.dart';
import 'package:nutrivision/features/auth/presentation/providers/profile_setup_provider.dart';
import 'package:nutrivision/features/auth/domain/entities/user.dart';
import 'package:nutrivision/core/navigation/main_tab_navigator.dart';
import 'package:nutrivision/features/auth/presentation/pages/sign_in_page.dart';
import 'package:nutrivision/features/auth/presentation/pages/profile_setup_page.dart';

/// Modern authentication wrapper using Riverpod
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return switch (authState) {
      AuthInitial() => const _LoadingPage(),
      AuthLoading() => const _LoadingPage(),
      AuthAuthenticated(user: final _, profile: final profile) =>
        _AuthenticatedHandler(profile: profile),
      AuthUnauthenticated() => const SignInPage(),
      AuthError(failure: final failure) => _ErrorPage(failure: failure),
    };
  }
}

/// Handler for authenticated users to check if profile setup is complete
class _AuthenticatedHandler extends ConsumerWidget {
  final UserProfile? profile;

  const _AuthenticatedHandler({this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // First check if profile is null - fast path to setup
    if (profile == null) {
      return const ProfileSetupPage();
    }

    // If we have a profile, check complete setup status
    final setupCompletedAsync = ref.watch(profileSetupCompletedProvider);

    return setupCompletedAsync.when(
      data: (setupCompleted) {
        if (setupCompleted) {
          return const MainTabNavigator();
        } else {
          return const ProfileSetupPage();
        }
      },
      loading: () => const _LoadingPage(),
      error: (_, __) =>
          const ProfileSetupPage(), // Default to setup page on error
    );
  }
}

/// Loading page widget
class _LoadingPage extends StatelessWidget {
  const _LoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

/// Error page widget
class _ErrorPage extends StatelessWidget {
  final dynamic failure;

  const _ErrorPage({required this.failure});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Authentication Error',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              failure.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Try to restart the authentication flow
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading page widget
class _LoadingPage extends StatelessWidget {
  const _LoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

/// Error page widget
class _ErrorPage extends StatelessWidget {
  final dynamic failure;

  const _ErrorPage({required this.failure});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Authentication Error',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              failure.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Try to restart the authentication flow
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
