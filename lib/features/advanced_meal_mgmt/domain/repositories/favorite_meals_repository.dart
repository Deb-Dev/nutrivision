import '../entities/nutrition_goals.dart';
import '../../../../core/utils/result.dart';

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

  /// Get most used favorite meals
  Future<Result<List<FavoriteMeal>>> getMostUsedFavoriteMeals({
    required String userId,
    required int limit,
  });

  /// Search favorite meals by name
  Future<Result<List<FavoriteMeal>>> searchFavoriteMeals({
    required String userId,
    required String searchQuery,
  });
}
