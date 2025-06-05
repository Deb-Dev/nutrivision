import 'package:nutrivision/core/utils/result.dart';
import 'package:nutrivision/features/auth/domain/entities/user.dart';

/// Authentication repository interface
abstract class AuthRepository {
  /// Stream of authentication state changes
  Stream<User?> get authStateChanges;

  /// Current authenticated user
  User? get currentUser;

  /// Sign in with email and password
  FutureResult<User> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Sign up with email and password
  FutureResult<User> signUpWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Sign out
  FutureResult<void> signOut();

  /// Send password reset email
  FutureResult<void> sendPasswordResetEmail(String email);

  /// Get user profile
  FutureResult<UserProfile?> getUserProfile(String userId);

  /// Update user profile
  FutureResult<void> updateUserProfile({
    required String userId,
    required UserProfile profile,
  });

  /// Delete user account
  FutureResult<void> deleteAccount();
}
