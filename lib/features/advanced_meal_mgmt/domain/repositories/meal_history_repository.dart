import '../../../../core/models/meal_models.dart';
import '../../../../core/utils/result.dart';

/// Repository interface for meal history operations
/// Follows Clean Architecture principles with Result return types for error handling
abstract class MealHistoryRepository {
  /// Retrieves meal history entries for a specific user with optional filtering
  /// Returns grouped meal history organized by date for UI consumption
  Future<Result<GroupedMealHistory>> getMealHistory({
    required String userId,
    MealHistoryFilter? filter,
  });

  /// Retrieves a single meal history entry by ID
  /// Used for detailed view and editing operations
  Future<Result<MealHistoryEntry>> getMealById({
    required String userId,
    required String mealId,
  });

  /// Updates an existing meal history entry
  /// Supports editing of both manual and AI-assisted meals
  Future<Result<MealHistoryEntry>> updateMeal({
    required String userId,
    required MealHistoryEntry updatedMeal,
  });

  /// Deletes a meal history entry
  /// Removes meal from both display and underlying collection
  Future<Result<void>> deleteMeal({
    required String userId,
    required String mealId,
  });

  /// Retrieves nutritional summary for a date range
  /// Used for analytics and progress tracking
  Future<Result<NutritionalSummary>> getNutritionalSummary({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Searches meal history by food name or description
  /// Enables users to find specific meals quickly
  Future<Result<List<MealHistoryEntry>>> searchMealHistory({
    required String userId,
    required String searchQuery,
    int? limit,
  });

  /// Retrieves recent meals for quick re-logging
  /// Returns the most recently logged meals (default: last 10)
  Future<Result<List<MealHistoryEntry>>> getRecentMeals({
    required String userId,
    int limit = 10,
  });
}
