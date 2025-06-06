import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../entities/meal_suggestion.dart';
import '../repositories/meal_suggestion_repository.dart';

/// Parameters for getting meal suggestions
class GetMealSuggestionsParams {
  final String userId;
  final String mealType;
  final Map<String, dynamic> preferences;
  final Map<String, dynamic> nutritionalRequirements;

  GetMealSuggestionsParams({
    required this.userId,
    required this.mealType,
    required this.preferences,
    required this.nutritionalRequirements,
  });
}

/// Use case for getting meal suggestions based on user preferences and nutritional requirements
@injectable
class GetMealSuggestionsUseCase {
  final MealSuggestionRepository repository;

  GetMealSuggestionsUseCase(this.repository);

  Future<Either<Failure, List<MealSuggestion>>> call(
    GetMealSuggestionsParams params,
  ) async {
    return await repository.getMealSuggestions(
      params.userId,
      params.mealType,
      params.preferences,
      params.nutritionalRequirements,
    );
  }
}
