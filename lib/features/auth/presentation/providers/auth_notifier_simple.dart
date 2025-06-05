import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../../../core/error/failures.dart';

part 'auth_notifier_simple.g.dart';

/// Simple authentication state without Freezed
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final User user;
  final UserProfile? profile;

  const AuthAuthenticated(this.user, {this.profile});
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final Failure failure;

  const AuthError(this.failure);
}

/// Authentication state notifier
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() {
    // Listen to auth state changes
    ref.listen(authStateStreamProvider, (previous, next) {
      next.when(
        data: (user) {
          if (user != null) {
            _loadUserProfile(user);
          } else {
            state = const AuthUnauthenticated();
          }
        },
        loading: () => state = const AuthLoading(),
        error: (error, _) => state = AuthError(
          error is Failure
              ? error
              : Failure.unexpectedFailure(
                  message: error.toString(),
                  exception: error,
                ),
        ),
      );
    });

    return const AuthInitial();
  }

  /// Sign in with email and password
  Future<void> signIn({required String email, required String password}) async {
    state = const AuthLoading();

    final repository = ref.read(authRepositoryProvider);
    final result = await repository.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    result.fold(
      (failure) => state = AuthError(failure),
      (user) => _loadUserProfile(user),
    );
  }

  /// Sign up with email and password
  Future<void> signUp({required String email, required String password}) async {
    state = const AuthLoading();

    final repository = ref.read(authRepositoryProvider);
    final result = await repository.signUpWithEmailAndPassword(
      email: email,
      password: password,
    );

    result.fold(
      (failure) => state = AuthError(failure),
      (user) => state = AuthAuthenticated(user),
    );
  }

  /// Sign out
  Future<void> signOut() async {
    final repository = ref.read(authRepositoryProvider);
    await repository.signOut();
    state = const AuthUnauthenticated();
  }

  /// Update user profile
  Future<void> updateProfile(UserProfile profile) async {
    final currentState = state;
    if (currentState is! AuthAuthenticated) return;

    state = const AuthLoading();

    final repository = ref.read(authRepositoryProvider);
    final result = await repository.updateUserProfile(
      userId: currentState.user.id,
      profile: profile,
    );

    result.fold(
      (failure) => state = AuthError(failure),
      (_) => state = AuthAuthenticated(currentState.user, profile: profile),
    );
  }

  /// Load user profile
  Future<void> _loadUserProfile(User user) async {
    final repository = ref.read(authRepositoryProvider);
    final result = await repository.getUserProfile(user.id);

    result.fold(
      (failure) => state = AuthAuthenticated(user),
      (profile) => state = AuthAuthenticated(user, profile: profile),
    );
  }
}

/// Provider for auth state stream
@riverpod
Stream<User?> authStateStream(AuthStateStreamRef ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
}

/// Provider for current user
@riverpod
User? currentUser(CurrentUserRef ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState is AuthAuthenticated ? authState.user : null;
}

/// Provider for current user profile
@riverpod
UserProfile? currentUserProfile(CurrentUserProfileRef ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState is AuthAuthenticated ? authState.profile : null;
}

/// Provider to check if user is authenticated
@riverpod
bool isAuthenticated(IsAuthenticatedRef ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState is AuthAuthenticated;
}
