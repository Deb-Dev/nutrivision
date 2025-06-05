import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_notifier_simple.dart';

/// Provider for current user ID from auth state
/// This is the centralized provider that should be used across all features
final currentUserIdProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.id ?? '';
});

/// Provider to check if user is authenticated
final isUserAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});
