import '../entities/nutrition_goals.dart';
import '../../../../core/utils/result.dart';

/// Repository interface for nutritional goal operations
abstract class NutritionGoalsRepository {
  /// Create a new nutritional goal
  Future<Result<NutritionalGoal>> createGoal({
    required String userId,
    required String name,
    required GoalType type,
    required double targetValue,
    required DateTime startDate,
    DateTime? endDate,
    String? notes,
  });

  /// Get all active goals for a user
  Future<Result<List<NutritionalGoal>>> getActiveGoals({
    required String userId,
  });

  /// Update an existing goal
  Future<Result<NutritionalGoal>> updateGoal({
    required String userId,
    required NutritionalGoal updatedGoal,
  });

  /// Delete a goal
  Future<Result<void>> deleteGoal({
    required String userId,
    required String goalId,
  });

  /// Get goal progress for analytics
  Future<Result<Map<String, double>>> getGoalProgress({
    required String userId,
    required String goalId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get today's meal summary with nutritional information for goal tracking
  Future<Result<AverageNutrition>> getTodaysMealSummary({
    required String userId,
    required DateTime date,
  });
}

/// Repository interface for favorite meals operations
abstract class FavoriteMealsRepository {
  /// Create a new favorite meal
  Future<Result<FavoriteMeal>> createFavoriteMeal({
    required String userId,
    required String name,
    required List<FavoriteFoodItem> foodItems,
    required NutritionalSummary nutrition,
    required String mealType,
    String? imageUrl,
    String? notes,
  });

  /// Get all favorite meals for a user
  Future<Result<List<FavoriteMeal>>> getFavoriteMeals({required String userId});

  /// Get a specific favorite meal
  Future<Result<FavoriteMeal>> getFavoriteMealById({
    required String userId,
    required String favoriteMealId,
  });

  /// Update an existing favorite meal
  Future<Result<FavoriteMeal>> updateFavoriteMeal({
    required String userId,
    required FavoriteMeal updatedMeal,
  });

  /// Delete a favorite meal
  Future<Result<void>> deleteFavoriteMeal({
    required String userId,
    required String favoriteMealId,
  });

  /// Log a favorite meal (adds to meal history)
  Future<Result<String>> logFavoriteMeal({
    required String userId,
    required String favoriteMealId,
    required DateTime loggedAt,
    String? notes,
  });
}

/// Repository interface for nutrition analytics operations
abstract class NutritionAnalyticsRepository {
  /// Generate nutrition report for a time period
  Future<Result<NutritionReport>> generateNutritionReport({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    required AnalyticsPeriod period,
  });

  /// Get daily nutrition data for charts
  Future<Result<List<DailyNutrition>>> getDailyNutritionData({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get meal type distribution
  Future<Result<Map<String, int>>> getMealTypeDistribution({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get top consumed foods
  Future<Result<List<String>>> getTopFoods({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  });
}
