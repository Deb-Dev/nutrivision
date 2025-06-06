import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/meal_plan.dart';

/// Repository interface for meal plan operations
abstract class MealPlanRepository {
  /// Get a meal plan by ID
  Future<Either<Failure, MealPlan>> getMealPlanById(String id);

  /// Get all meal plans for a user
  Future<Either<Failure, List<MealPlan>>> getUserMealPlans(String userId);

  /// Get the active meal plan for a user (if any)
  Future<Either<Failure, MealPlan?>> getActiveMealPlan(String userId);

  /// Create a new meal plan
  Future<Either<Failure, MealPlan>> createMealPlan(MealPlan mealPlan);

  /// Update an existing meal plan
  Future<Either<Failure, MealPlan>> updateMealPlan(MealPlan mealPlan);

  /// Delete a meal plan
  Future<Either<Failure, bool>> deleteMealPlan(String id);

  /// Set a meal plan as active
  Future<Either<Failure, bool>> setMealPlanActive(String id, String userId);

  /// Get meal plans for a date range
  Future<Either<Failure, List<MealPlan>>> getMealPlansForDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );

  /// Mark a planned meal as completed
  Future<Either<Failure, bool>> markPlannedMealCompleted(
    String mealPlanId,
    DateTime date,
    String mealType,
    String actualMealId,
  );

  /// Generate a new meal plan based on user preferences and nutritional goals
  Future<Either<Failure, MealPlan>> generateMealPlan(
    String userId,
    DateTime startDate,
    DateTime endDate,
    Map<String, dynamic> preferences,
  );
}
