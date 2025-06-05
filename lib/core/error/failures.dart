import 'package:freezed_annotation/freezed_annotation.dart';

part 'failures.freezed.dart';

/// Base failure class using Freezed for immutable error handling
@freezed
class Failure with _$Failure {
  const factory Failure.serverFailure({
    required String message,
    int? statusCode,
  }) = ServerFailure;

  const factory Failure.networkFailure({required String message}) =
      NetworkFailure;

  const factory Failure.authFailure({required String message, String? code}) =
      AuthFailure;

  const factory Failure.cacheFailure({required String message}) = CacheFailure;

  const factory Failure.aiFailure({required String message, String? code}) =
      AIFailure;

  const factory Failure.validationFailure({
    required String message,
    Map<String, String>? fieldErrors,
  }) = ValidationFailure;

  const factory Failure.unexpectedFailure({
    required String message,
    Object? exception,
  }) = UnexpectedFailure;
}

/// Extension to get user-friendly error messages
extension FailureX on Failure {
  String get userMessage {
    return when(
      serverFailure: (message, statusCode) =>
          'Server error occurred. Please try again later.',
      networkFailure: (message) =>
          'Network connection failed. Please check your internet connection.',
      authFailure: (message, code) =>
          'Authentication failed. Please sign in again.',
      cacheFailure: (message) => 'Local storage error occurred.',
      aiFailure: (message, code) => 'AI recognition failed. Please try again.',
      validationFailure: (message, fieldErrors) => message,
      unexpectedFailure: (message, exception) =>
          'An unexpected error occurred. Please try again.',
    );
  }
}
