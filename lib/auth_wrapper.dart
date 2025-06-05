import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrivision/core/navigation/main_tab_navigator.dart';
import 'package:nutrivision/signin_screen.dart';
import 'package:nutrivision/features/auth/presentation/providers/auth_notifier_simple.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateStreamProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          // Check if user has completed profile setup
          // This is a simplified version - the full implementation would check Firestore
          return const MainTabNavigator(); // Use the new tab navigation
        }
        return const SignInScreen();
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Text('Authentication Error: $error'),
        ),
      ),
    );
  }
}
