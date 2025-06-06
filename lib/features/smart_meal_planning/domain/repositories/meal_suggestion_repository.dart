import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/meal_suggestion.dart';

/// Repository interface for meal suggestion operations
abstract class MealSuggestionRepository {
  /// Get a meal suggestion by ID
  Future<Either<Failure, MealSuggestion>> getMealSuggestionById(String id);

  /// Get meal suggestions based on user preferences and nutritional needs
  Future<Either<Failure, List<MealSuggestion>>> getMealSuggestions(
    String userId,
    String mealType,
    Map<String, dynamic> preferences,
    Map<String, dynamic> nutritionalRequirements,
  );

  /// Save a meal suggestion (mark as favorite)
  Future<Either<Failure, MealSuggestion>> saveMealSuggestion(
    MealSuggestion suggestion,
  );

  /// Delete a meal suggestion from saved/favorites
  Future<Either<Failure, bool>> deleteMealSuggestion(String id);

  /// Get favorite/saved meal suggestions for a user
  Future<Either<Failure, List<MealSuggestion>>> getFavoriteMealSuggestions(
    String userId,
  );

  /// Rate a meal suggestion
  Future<Either<Failure, MealSuggestion>> rateMealSuggestion(
    String id,
    double rating,
  );

  /// Get meal suggestions for a specific cuisine
  Future<Either<Failure, List<MealSuggestion>>> getMealSuggestionsByCuisine(
    String userId,
    String cuisine,
    String mealType,
  );

  /// Get popular meal suggestions
  Future<Either<Failure, List<MealSuggestion>>> getPopularMealSuggestions(
    String mealType,
    int limit,
  );

  /// Get meal suggestions similar to a given meal
  Future<Either<Failure, List<MealSuggestion>>> getSimilarMealSuggestions(
    String mealId,
    int limit,
  );
}
