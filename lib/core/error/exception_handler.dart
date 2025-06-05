import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'failures.dart';

/// Exception handler that converts various exceptions to Failure objects
class ExceptionHandler {
  static Failure handleException(Object exception) {
    if (exception is DioException) {
      return _handleDioException(exception);
    } else if (exception is FirebaseAuthException) {
      return _handleFirebaseAuthException(exception);
    } else if (exception is GenerativeAIException) {
      return _handleGenerativeAIException(exception);
    } else if (exception is SocketException) {
      return const Failure.networkFailure(message: 'No internet connection');
    } else {
      return Failure.unexpectedFailure(
        message: exception.toString(),
        exception: exception,
      );
    }
  }

  static Failure _handleDioException(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const Failure.networkFailure(message: 'Connection timeout');
      case DioExceptionType.badResponse:
        return Failure.serverFailure(
          message: exception.response?.data?['message'] ?? 'Server error',
          statusCode: exception.response?.statusCode,
        );
      case DioExceptionType.cancel:
        return const Failure.networkFailure(message: 'Request was cancelled');
      case DioExceptionType.connectionError:
        return const Failure.networkFailure(message: 'Connection error');
      default:
        return Failure.unexpectedFailure(
          message: exception.message ?? 'Unknown network error',
          exception: exception,
        );
    }
  }

  static Failure _handleFirebaseAuthException(FirebaseAuthException exception) {
    return Failure.authFailure(
      message: exception.message ?? 'Authentication error',
      code: exception.code,
    );
  }

  static Failure _handleGenerativeAIException(GenerativeAIException exception) {
    return Failure.aiFailure(message: exception.message, code: null);
  }
}
