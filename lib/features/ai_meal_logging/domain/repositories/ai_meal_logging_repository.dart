import 'dart:io';
import 'package:dartz/dartz.dart';
import '../entities/ai_meal_recognition.dart';
import '../../../../core/error/failures.dart';

/// Repository interface for AI meal logging functionality
abstract class AIMealLoggingRepository {
  /// Analyze a meal photo using AI and return recognized food items
  Future<Either<Failure, AIMealRecognitionResult>> analyzeMealPhoto({
    required File imageFile,
    String? mealType,
  });

  /// Save an AI-analyzed meal log to the database
  Future<Either<Failure, AIMealLog>> logAIMeal({
    required List<ConfirmedMealItem> confirmedItems,
    required String imageId,
    required AIMealRecognitionResult originalAnalysis,
    required String mealType,
    String? notes,
  });

  /// Get AI meal logs for a specific date range
  Future<Either<Failure, List<AIMealLog>>> getAIMealLogs({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get AI meal log by ID
  Future<Either<Failure, AIMealLog>> getAIMealLogById(String id);

  /// Update an existing AI meal log
  Future<Either<Failure, AIMealLog>> updateAIMealLog({
    required String id,
    required List<ConfirmedMealItem> confirmedItems,
    String? notes,
  });

  /// Delete an AI meal log
  Future<Either<Failure, Unit>> deleteAIMealLog(String id);

  /// Search food database for manual corrections
  Future<Either<Failure, List<FoodItem>>> searchFoodDatabase(String query);

  /// Get food item details by ID for corrections
  Future<Either<Failure, FoodItem>> getFoodItemById(String foodId);
}

/// Food item from the database for corrections and additions
class FoodItem {
  final String id;
  final String name;
  final String brand;
  final Map<String, double> nutritionPer100g;
  final List<String> servingSizes;

  const FoodItem({
    required this.id,
    required this.name,
    required this.brand,
    required this.nutritionPer100g,
    required this.servingSizes,
  });
}
