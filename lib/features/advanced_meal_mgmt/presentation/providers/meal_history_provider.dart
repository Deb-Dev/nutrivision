import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/meal_history_repository.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/models/meal_models.dart'; // Core meal models

/// States for meal history
enum MealHistoryStatus { initial, loading, loaded, error }

/// State for meal history provider
class MealHistoryState {
  final MealHistoryStatus status;
  final GroupedMealHistory? groupedMeals;
  final String? errorMessage;
  final MealHistoryFilter filter;
  final bool isFiltering;

  const MealHistoryState({
    this.status = MealHistoryStatus.initial,
    this.groupedMeals,
    this.errorMessage,
    this.filter = const MealHistoryFilter(),
    this.isFiltering = false,
  });

  MealHistoryState copyWith({
    MealHistoryStatus? status,
    GroupedMealHistory? groupedMeals,
    String? errorMessage,
    MealHistoryFilter? filter,
    bool? isFiltering,
  }) {
    return MealHistoryState(
      status: status ?? this.status,
      groupedMeals: groupedMeals ?? this.groupedMeals,
      errorMessage: errorMessage ?? this.errorMessage,
      filter: filter ?? this.filter,
      isFiltering: isFiltering ?? this.isFiltering,
    );
  }
}

/// Provider for meal history
@injectable
class MealHistoryNotifier extends StateNotifier<MealHistoryState> {
  final MealHistoryRepository _repository;

  MealHistoryNotifier(this._repository) : super(const MealHistoryState());

  /// Load meal history for a user
  Future<void> loadMealHistory(String userId) async {
    // Check if we need to set default date range
    MealHistoryFilter currentFilter = state.filter;
    if (currentFilter.startDate == null && currentFilter.endDate == null) {
      // Set default date range to last 30 days
      final now = DateTime.now();
      final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final startDate = DateTime(
        now.year,
        now.month,
        now.day - currentFilter.days,
      );

      currentFilter = currentFilter.copyWith(
        startDate: startDate,
        endDate: endDate,
      );

      // Update state with the new filter
      state = state.copyWith(
        filter: currentFilter,
        status: MealHistoryStatus.loading,
        isFiltering: true,
      );
    } else {
      // Ensure we don't override a freshly set filter if status is initial
      if (state.status != MealHistoryStatus.initial &&
          state.status != MealHistoryStatus.loading) {
        state = state.copyWith(
          status: MealHistoryStatus.loading,
          isFiltering: state.filter != const MealHistoryFilter(),
        );
      } else if (state.status == MealHistoryStatus.initial) {
        // If initial, it means a filter might have just been set.
        // The isFiltering flag should reflect if the current filter is non-default.
        state = state.copyWith(
          status: MealHistoryStatus.loading,
          isFiltering: state.filter != const MealHistoryFilter(),
        );
      }
    }

    final result = await _repository.getMealHistory(
      userId: userId,
      filter: currentFilter, // Use the potentially updated filter
    );

    result.fold(
      (failure) => state = state.copyWith(
        status: MealHistoryStatus.error,
        errorMessage: failure.message,
        isFiltering: false,
      ),
      (groupedMeals) => state = state.copyWith(
        status: MealHistoryStatus.loaded,
        groupedMeals: groupedMeals,
        isFiltering: false,
      ),
    );
  }

  Future<void> setInitialFilterAndLoad(
    String userId,
    MealHistoryFilter filter,
  ) async {
    state = state.copyWith(
      filter: filter,
      status: MealHistoryStatus.initial,
      isFiltering: true,
    );
    await loadMealHistory(userId);
  }

  /// Apply filter to meal history
  Future<void> applyFilter(String userId, MealHistoryFilter filter) async {
    state = state.copyWith(isFiltering: true, filter: filter);

    final result = await _repository.getMealHistory(
      userId: userId,
      filter: filter,
    );

    result.fold(
      (failure) => state = state.copyWith(
        isFiltering: false,
        status: MealHistoryStatus.error,
        errorMessage: failure.message,
      ),
      (groupedMeals) => state = state.copyWith(
        isFiltering: false,
        status: MealHistoryStatus.loaded,
        groupedMeals: groupedMeals,
      ),
    );
  }

  /// Reset filters
  Future<void> resetFilters(String userId) async {
    // Create a filter with default date range of last 30 days
    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final startDate = DateTime(now.year, now.month, now.day - 30);

    final defaultFilter = MealHistoryFilter(
      startDate: startDate,
      endDate: endDate,
      days: 30,
    );

    state = state.copyWith(isFiltering: true, filter: defaultFilter);

    final result = await _repository.getMealHistory(
      userId: userId,
      filter: defaultFilter,
    );

    result.fold(
      (failure) => state = state.copyWith(
        isFiltering: false,
        status: MealHistoryStatus.error,
        errorMessage: failure.message,
      ),
      (groupedMeals) => state = state.copyWith(
        isFiltering: false,
        status: MealHistoryStatus.loaded,
        groupedMeals: groupedMeals,
      ),
    );
  }

  /// Update a meal
  Future<Result<MealHistoryEntry>> updateMeal(
    String userId,
    MealHistoryEntry updatedMeal,
  ) async {
    state = state.copyWith(status: MealHistoryStatus.loading);

    final result = await _repository.updateMeal(
      userId: userId,
      updatedMeal: updatedMeal,
    );

    result.fold(
      (failure) => state = state.copyWith(
        status: MealHistoryStatus.error,
        errorMessage: failure.message,
      ),
      (_) => state = state.copyWith(status: MealHistoryStatus.loading),
    );

    // Reload meals after update
    await loadMealHistory(userId);

    return result;
  }

  /// Delete a meal
  Future<void> deleteMeal(String userId, String mealId) async {
    state = state.copyWith(status: MealHistoryStatus.loading);

    final result = await _repository.deleteMeal(userId: userId, mealId: mealId);

    result.fold(
      (failure) => state = state.copyWith(
        status: MealHistoryStatus.error,
        errorMessage: failure.message,
      ),
      (_) => loadMealHistory(userId), // Reload meals after deletion
    );
  }
}

/// Provider for meal history
final mealHistoryProvider =
    StateNotifierProvider<MealHistoryNotifier, MealHistoryState>((ref) {
      return getIt<MealHistoryNotifier>();
    });

/// Provider for a single meal detail
final mealDetailProvider =
    FutureProvider.family<Result<MealHistoryEntry>, String>((ref, mealId) {
      final repository = getIt<MealHistoryRepository>();
      final userId = ref.read(currentUserIdProvider);
      return repository.getMealById(userId: userId, mealId: mealId);
    });
