import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// User domain entity
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String email,
    String? displayName,
    String? photoUrl,
    required bool emailVerified,
    required DateTime createdAt,
    DateTime? lastSignIn,
    UserProfile? profile,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

/// User profile information
@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String firstName,
    required String lastName,
    required int age,
    required String gender,
    required double height,
    required double weight,
    required String activityLevel,
    required List<String> dietaryPreferences,
    required List<String> allergies,
    required String dietaryGoal,
    required bool profileCompleted,
    DateTime? updatedAt,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}
