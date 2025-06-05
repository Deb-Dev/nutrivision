import 'dart:developer';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../entities/ai_meal_recognition.dart';
import '../repositories/ai_meal_logging_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';

/// Use case for analyzing meal photos with AI
@injectable
class AnalyzeMealPhotoUseCase {
  final AIMealLoggingRepository _repository;

  const AnalyzeMealPhotoUseCase(this._repository);

  Future<Result<AIMealRecognitionResult>> call({
    required File imageFile,
    String? mealType,
  }) async {
    log(
      '🎯 [USE CASE] AnalyzeMealPhotoUseCase.call() - Starting image analysis',
    );
    log('📁 [USE CASE] Image file path: ${imageFile.path}');
    log('🍽️ [USE CASE] Meal type: $mealType');

    // Validate image file
    if (!await imageFile.exists()) {
      log('❌ [USE CASE] Image file does not exist');
      return Left(ValidationFailure(message: 'Image file does not exist'));
    }

    // Check file size (max 10MB)
    final fileSize = await imageFile.length();
    log(
      '📏 [USE CASE] Image file size: $fileSize bytes (${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB)',
    );
    if (fileSize > 10 * 1024 * 1024) {
      log('❌ [USE CASE] Image file too large');
      return Left(
        ValidationFailure(message: 'Image file is too large (max 10MB)'),
      );
    }

    // Check file extension
    final extension = imageFile.path.toLowerCase();
    log('🔧 [USE CASE] Image extension: $extension');
    if (!extension.endsWith('.jpg') &&
        !extension.endsWith('.jpeg') &&
        !extension.endsWith('.png')) {
      log('❌ [USE CASE] Invalid image format');
      return Left(
        ValidationFailure(
          message: 'Invalid image format. Please use JPG or PNG',
        ),
      );
    }

    log('✅ [USE CASE] All validations passed, calling repository...');
    final result = await _repository.analyzeMealPhoto(
      imageFile: imageFile,
      mealType: mealType,
    );

    return result.fold(
      (failure) {
        log('❌ [USE CASE] Repository returned failure: ${failure.message}');
        return Left(failure);
      },
      (success) {
        log(
          '✅ [USE CASE] Repository returned success with ${success.recognizedItems.length} items',
        );
        return Right(success);
      },
    );
  }
}

/// Use case for logging confirmed AI meal
@injectable
class LogAIMealUseCase {
  final AIMealLoggingRepository _repository;

  const LogAIMealUseCase(this._repository);

  Future<Result<AIMealLog>> call({
    required List<ConfirmedMealItem> confirmedItems,
    required String imageId,
    required AIMealRecognitionResult originalAnalysis,
    required String mealType,
    String? notes,
  }) async {
    // Validate confirmed items
    if (confirmedItems.isEmpty) {
      return Left(
        ValidationFailure(message: 'At least one food item must be confirmed'),
      );
    }

    // Validate meal type
    const validMealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];
    if (!validMealTypes.contains(mealType.toLowerCase())) {
      return Left(ValidationFailure(message: 'Invalid meal type'));
    }

    final result = await _repository.logAIMeal(
      confirmedItems: confirmedItems,
      imageId: imageId,
      originalAnalysis: originalAnalysis,
      mealType: mealType,
      notes: notes,
    );

    return result.fold((failure) => Left(failure), (success) => Right(success));
  }
}

/// Use case for getting AI meal logs
@injectable
class GetAIMealLogsUseCase {
  final AIMealLoggingRepository _repository;

  const GetAIMealLogsUseCase(this._repository);

  Future<Result<List<AIMealLog>>> call({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Validate date range
    if (startDate.isAfter(endDate)) {
      return Left(
        ValidationFailure(message: 'Start date must be before end date'),
      );
    }

    // Limit to reasonable date range (max 1 year)
    final daysDifference = endDate.difference(startDate).inDays;
    if (daysDifference > 365) {
      return Left(
        ValidationFailure(message: 'Date range cannot exceed 1 year'),
      );
    }

    final result = await _repository.getAIMealLogs(
      startDate: startDate,
      endDate: endDate,
    );

    return result.fold((failure) => Left(failure), (success) => Right(success));
  }
}

/// Use case for searching food database
@injectable
class SearchFoodDatabaseUseCase {
  final AIMealLoggingRepository _repository;

  const SearchFoodDatabaseUseCase(this._repository);

  Future<Result<List<FoodItem>>> call(String query) async {
    // Validate query
    if (query.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Search query cannot be empty'));
    }

    if (query.trim().length < 2) {
      return Left(
        ValidationFailure(
          message: 'Search query must be at least 2 characters',
        ),
      );
    }

    final result = await _repository.searchFoodDatabase(query.trim());

    return result.fold((failure) => Left(failure), (success) => Right(success));
  }
}

/// Use case for updating AI meal log
@injectable
class UpdateAIMealLogUseCase {
  final AIMealLoggingRepository _repository;

  const UpdateAIMealLogUseCase(this._repository);

  Future<Result<AIMealLog>> call({
    required String id,
    required List<ConfirmedMealItem> confirmedItems,
    String? notes,
  }) async {
    // Validate ID
    if (id.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Meal log ID cannot be empty'));
    }

    // Validate confirmed items
    if (confirmedItems.isEmpty) {
      return Left(
        ValidationFailure(message: 'At least one food item must be confirmed'),
      );
    }

    final result = await _repository.updateAIMealLog(
      id: id,
      confirmedItems: confirmedItems,
      notes: notes,
    );

    return result.fold((failure) => Left(failure), (success) => Right(success));
  }
}
