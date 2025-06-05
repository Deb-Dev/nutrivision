import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/nutrition_goals.dart';
import '../../domain/repositories/favorite_meals_repository.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/result.dart';

/// States for favorite meals
enum FavoriteMealsStatus { initial, loading, loaded, updating, updated, error }

/// State for favorite meals provider
class FavoriteMealsState {
  final FavoriteMealsStatus status;
  final List<FavoriteMeal>? meals;
  final String? errorMessage;

  const FavoriteMealsState({
    this.status = FavoriteMealsStatus.initial,
    this.meals,
    this.errorMessage,
  });

  FavoriteMealsState copyWith({
    FavoriteMealsStatus? status,
    List<FavoriteMeal>? meals,
    String? errorMessage,
  }) {
    return FavoriteMealsState(
      status: status ?? this.status,
      meals: meals ?? this.meals,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Provider for favorite meals
@injectable
class FavoriteMealsNotifier extends StateNotifier<FavoriteMealsState> {
  final FavoriteMealsRepository _repository;

  FavoriteMealsNotifier(this._repository) : super(const FavoriteMealsState());

  /// Load all favorite meals for a user
  Future<void> loadFavoriteMeals(String userId) async {
    state = state.copyWith(status: FavoriteMealsStatus.loading);

    final result = await _repository.getFavoriteMeals(userId: userId);

    result.fold(
      (failure) => state = state.copyWith(
        status: FavoriteMealsStatus.error,
        errorMessage: failure.message,
      ),
      (meals) => state = state.copyWith(
        status: FavoriteMealsStatus.loaded,
        meals: meals,
      ),
    );
  }

  /// Create a new favorite meal
  Future<void> createFavoriteMeal(String userId, FavoriteMeal meal) async {
    state = state.copyWith(status: FavoriteMealsStatus.updating);

    final result = await _repository.createFavoriteMeal(
      userId: userId,
      name: meal.name,
      foodItems: meal.foodItems,
      nutrition: meal.nutrition,
      mealType: meal.mealType,
      imageUrl: meal.imageUrl,
      notes: meal.notes,
    );

    result.fold(
      (failure) => state = state.copyWith(
        status: FavoriteMealsStatus.error,
        errorMessage: failure.message,
      ),
      (_) async {
        await loadFavoriteMeals(userId);
        state = state.copyWith(status: FavoriteMealsStatus.updated);
      },
    );
  }

  /// Update an existing favorite meal
  Future<void> updateFavoriteMeal(String userId, FavoriteMeal meal) async {
    state = state.copyWith(status: FavoriteMealsStatus.updating);

    final result = await _repository.updateFavoriteMeal(
      userId: userId,
      updatedMeal: meal,
    );

    result.fold(
      (failure) => state = state.copyWith(
        status: FavoriteMealsStatus.error,
        errorMessage: failure.message,
      ),
      (_) async {
        await loadFavoriteMeals(userId);
        state = state.copyWith(status: FavoriteMealsStatus.updated);
      },
    );
  }

  /// Delete a favorite meal
  Future<void> deleteFavoriteMeal(String userId, String mealId) async {
    state = state.copyWith(status: FavoriteMealsStatus.updating);

    final result = await _repository.deleteFavoriteMeal(
      userId: userId,
      favoriteMealId: mealId,
    );

    result.fold(
      (failure) => state = state.copyWith(
        status: FavoriteMealsStatus.error,
        errorMessage: failure.message,
      ),
      (_) async {
        await loadFavoriteMeals(userId);
        state = state.copyWith(status: FavoriteMealsStatus.updated);
      },
    );
  }

  /// Log a favorite meal to meal history
  Future<Result<String>> logFavoriteMeal(String userId, String mealId) async {
    state = state.copyWith(status: FavoriteMealsStatus.updating);

    final result = await _repository.logFavoriteMeal(
      userId: userId,
      favoriteMealId: mealId,
      loggedAt: DateTime.now(),
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          status: FavoriteMealsStatus.error,
          errorMessage: failure.message,
        );
      },
      (_) async {
        await loadFavoriteMeals(userId);
        state = state.copyWith(status: FavoriteMealsStatus.updated);
      },
    );

    return result;
  }
}

/// Provider for favorite meals
final favoriteMealsProvider =
    StateNotifierProvider<FavoriteMealsNotifier, FavoriteMealsState>((ref) {
      return getIt<FavoriteMealsNotifier>();
    });

/// Check if a meal is in favorites based on name
final isMealFavoriteProvider = FutureProvider.autoDispose.family<bool, String>(
  (ref, mealName) async {
    final favoritesState = ref.watch(favoriteMealsProvider);
    final favorites = favoritesState.meals;

    // If we don't have the meals loaded yet, return false
    if (favorites == null) {
      return false;
    }

    // Check if any favorite has the same name
    return favorites.any((meal) => meal.name.toLowerCase() == mealName.toLowerCase());
  },
);
