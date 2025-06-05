import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

import 'package:nutrivision/core/di/injection.dart';
import 'package:nutrivision/core/error/exception_handler.dart';
import 'package:nutrivision/core/error/failures.dart';
import 'package:nutrivision/core/utils/result.dart';
import 'package:nutrivision/features/auth/domain/entities/user.dart';
import 'package:nutrivision/features/auth/domain/repositories/auth_repository.dart';

part 'auth_repository_impl.g.dart';

/// Firebase implementation of AuthRepository
class AuthRepositoryImpl implements AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl({
    required firebase_auth.FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
  }) : _firebaseAuth = firebaseAuth,
       _firestore = firestore;

  @override
  Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      return firebaseUser != null ? _mapFirebaseUser(firebaseUser) : null;
    });
  }

  @override
  User? get currentUser {
    final firebaseUser = _firebaseAuth.currentUser;
    return firebaseUser != null ? _mapFirebaseUser(firebaseUser) : null;
  }

  @override
  FutureResult<User> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return const Left(Failure.authFailure(message: 'Sign in failed'));
      }

      return Right(_mapFirebaseUser(credential.user!));
    } catch (e) {
      return Left(ExceptionHandler.handleException(e));
    }
  }

  @override
  FutureResult<User> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return const Left(Failure.authFailure(message: 'Sign up failed'));
      }

      return Right(_mapFirebaseUser(credential.user!));
    } catch (e) {
      return Left(ExceptionHandler.handleException(e));
    }
  }

  @override
  FutureResult<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      return const Right(null);
    } catch (e) {
      return Left(ExceptionHandler.handleException(e));
    }
  }

  @override
  FutureResult<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return const Right(null);
    } catch (e) {
      return Left(ExceptionHandler.handleException(e));
    }
  }

  @override
  FutureResult<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        return const Right(null);
      }

      final data = doc.data()!;

      // Check if profile has been completed
      bool profileCompleted = data['profileCompleted'] == true;

      // Check if dietary preferences have been completed
      bool dietaryPreferencesCompleted = false;

      // Extract dietary preferences and allergies from the dietary_info field
      List<String> dietaryPreferences = [];
      List<String> allergies = [];

      if (data.containsKey('dietary_info')) {
        final dietaryInfo = data['dietary_info'] as Map<String, dynamic>;
        // Check if preferencesLastUpdated exists to confirm dietary preferences were saved
        dietaryPreferencesCompleted = dietaryInfo.containsKey(
          'preferencesLastUpdated',
        );

        if (dietaryInfo.containsKey('dietaryPreferences')) {
          dietaryPreferences = List<String>.from(
            dietaryInfo['dietaryPreferences'],
          );
        }
        if (dietaryInfo.containsKey('selectedAllergies')) {
          allergies = List<String>.from(dietaryInfo['selectedAllergies']);
        }
      }

      // If either profile or dietary preferences are not completed, return incomplete profile
      bool setupCompleted = profileCompleted && dietaryPreferencesCompleted;

      // If setup is not complete, return null
      if (!setupCompleted) {
        return const Right(null);
      }

      if (data.containsKey('dietary_info')) {
        final dietaryInfo = data['dietary_info'] as Map<String, dynamic>;
        if (dietaryInfo.containsKey('dietaryPreferences')) {
          dietaryPreferences = List<String>.from(
            dietaryInfo['dietaryPreferences'],
          );
        }
        if (dietaryInfo.containsKey('selectedAllergies')) {
          allergies = List<String>.from(dietaryInfo['selectedAllergies']);
        }
      }

      // Create a profile object with the available data
      return Right(
        UserProfile(
          firstName: data['name']?.toString().split(' ').first ?? '',
          lastName:
              data['name'] != null &&
                  data['name'].toString().split(' ').length > 1
              ? data['name'].toString().split(' ').sublist(1).join(' ')
              : '',
          age: data['age'] ?? 0,
          gender: data['biologicalSex'] ?? '',
          height: (data['height'] ?? 0).toDouble(),
          weight: (data['weight'] ?? 0).toDouble(),
          activityLevel: data['activityLevel'] ?? '',
          dietaryPreferences: dietaryPreferences,
          allergies: allergies,
          dietaryGoal: data['dietaryGoal'] ?? '',
          profileCompleted: profileCompleted,
          updatedAt: data['lastUpdated'] != null
              ? (data['lastUpdated'] as Timestamp).toDate()
              : DateTime.now(),
        ),
      );
    } catch (e) {
      return Left(ExceptionHandler.handleException(e));
    }
  }

  @override
  FutureResult<void> updateUserProfile({
    required String userId,
    required UserProfile profile,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .set(profile.toJson(), SetOptions(merge: true));
      return const Right(null);
    } catch (e) {
      return Left(ExceptionHandler.handleException(e));
    }
  }

  @override
  FutureResult<void> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return const Left(Failure.authFailure(message: 'No user signed in'));
      }

      // Delete user data from Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete Firebase Auth account
      await user.delete();

      return const Right(null);
    } catch (e) {
      return Left(ExceptionHandler.handleException(e));
    }
  }

  User _mapFirebaseUser(firebase_auth.User firebaseUser) {
    return User(
      id: firebaseUser.uid,
      email: firebaseUser.email!,
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      emailVerified: firebaseUser.emailVerified,
      createdAt: firebaseUser.metadata.creationTime!,
      lastSignIn: firebaseUser.metadata.lastSignInTime,
    );
  }
}

/// Provider for AuthRepository
@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepositoryImpl(
    firebaseAuth: getIt<firebase_auth.FirebaseAuth>(),
    firestore: getIt<FirebaseFirestore>(),
  );
}
