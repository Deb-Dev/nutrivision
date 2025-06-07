import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/usecases/get_meal_suggestions_usecase.dart';
import '../../domain/usecases/create_meal_plan_usecase.dart';
import '../../domain/usecases/generate_grocery_list_usecase.dart';
import '../../domain/repositories/meal_plan_repository.dart';
import '../../domain/repositories/meal_suggestion_repository.dart';
import '../../domain/repositories/grocery_list_repository.dart';
import '../../data/repositories/meal_plan_repository_impl.dart';
import '../../data/repositories/meal_suggestion_repository_impl.dart';
import '../../data/repositories/grocery_list_repository_impl.dart';
import '../../data/services/meal_suggestion_service.dart';
import '../../data/services/single_meal_suggestion_service.dart';
import '../../../../core/di/injection.dart';
import '../../../ai_meal_logging/data/services/gemini_ai_service.dart';

/// Smart Meal Planning Module for setting up all dependencies
class SmartMealPlanningModule {
  static void setup(ProviderContainer container) {
    // Riverpod providers will handle dependency injection
    // This method is kept for consistency with other modules
  }

  /// Register with Injectable
  static void registerWithGetIt() {
    // Services
    if (!getIt.isRegistered<MealSuggestionService>()) {
      getIt.registerLazySingleton<MealSuggestionService>(
        () => MealSuggestionService(
          FirebaseFirestore.instance,
          getIt<GeminiAIService>(),
        ),
      );
    }

    // Repositories
    if (!getIt.isRegistered<MealPlanRepository>()) {
      getIt.registerLazySingleton<MealPlanRepository>(
        () => MealPlanRepositoryImpl(FirebaseFirestore.instance),
      );
    }

    if (!getIt.isRegistered<MealSuggestionRepository>()) {
      getIt.registerLazySingleton<MealSuggestionRepository>(
        () => MealSuggestionRepositoryImpl(
          FirebaseFirestore.instance,
          getIt<MealSuggestionService>(),
        ),
      );
    }

    // Single meal suggestion service
    if (!getIt.isRegistered<SingleMealSuggestionService>()) {
      getIt.registerLazySingleton<SingleMealSuggestionService>(
        () => SingleMealSuggestionService(
          FirebaseFirestore.instance,
          getIt<GeminiAIService>(),
        ),
      );
    }

    if (!getIt.isRegistered<GroceryListRepository>()) {
      getIt.registerLazySingleton<GroceryListRepository>(
        () => GroceryListRepositoryImpl(FirebaseFirestore.instance),
      );
    }

    // Use cases
    if (!getIt.isRegistered<GetMealSuggestionsUseCase>()) {
      getIt.registerLazySingleton<GetMealSuggestionsUseCase>(
        () => GetMealSuggestionsUseCase(getIt<MealSuggestionRepository>()),
      );
    }

    if (!getIt.isRegistered<CreateMealPlanUseCase>()) {
      getIt.registerLazySingleton<CreateMealPlanUseCase>(
        () => CreateMealPlanUseCase(getIt<MealPlanRepository>()),
      );
    }

    if (!getIt.isRegistered<GenerateGroceryListUseCase>()) {
      getIt.registerLazySingleton<GenerateGroceryListUseCase>(
        () => GenerateGroceryListUseCase(
          getIt<GroceryListRepository>(),
          getIt<MealPlanRepository>(),
        ),
      );
    }
  }
}
