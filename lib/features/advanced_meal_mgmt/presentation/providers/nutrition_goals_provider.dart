import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/nutrition_goals.dart';
import '../../domain/repositories/nutrition_goals_repository.dart';
import '../../../../core/di/injection.dart';

/// States for nutrition goals
enum NutritionGoalsStatus { initial, loading, loaded, updating, updated, error }

/// State for nutrition goals provider
class NutritionGoalsState {
  final NutritionGoalsStatus status;
  final List<NutritionalGoal>? goals;
  final AverageNutrition? currentProgress;
  final String? errorMessage;

  const NutritionGoalsState({
    this.status = NutritionGoalsStatus.initial,
    this.goals,
    this.currentProgress,
    this.errorMessage,
  });

  NutritionGoalsState copyWith({
    NutritionGoalsStatus? status,
    List<NutritionalGoal>? goals,
    AverageNutrition? currentProgress,
    String? errorMessage,
  }) {
    return NutritionGoalsState(
      status: status ?? this.status,
      goals: goals ?? this.goals,
      currentProgress: currentProgress ?? this.currentProgress,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Provider for nutrition goals
@injectable
class NutritionGoalsNotifier extends StateNotifier<NutritionGoalsState> {
  final NutritionGoalsRepository _repository;

  NutritionGoalsNotifier(this._repository) : super(const NutritionGoalsState());

  /// Load all nutrition goals for a user
  Future<void> loadNutritionGoals(String userId) async {
    state = state.copyWith(status: NutritionGoalsStatus.loading);

    final result = await _repository.getActiveGoals(userId: userId);

    result.fold(
      (failure) => state = state.copyWith(
        status: NutritionGoalsStatus.error,
        errorMessage: failure.message,
      ),
      (goals) => state = state.copyWith(
        status: NutritionGoalsStatus.loaded,
        goals: goals,
      ),
    );

    // Also load current progress
    await loadCurrentProgress(userId);
  }

  /// Load current progress against goals
  Future<void> loadCurrentProgress(String userId) async {
    state = state.copyWith(status: NutritionGoalsStatus.loading);

    // Get current date
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Fetch today's meals from repository to calculate real progress
    final result = await _repository.getTodaysMealSummary(
      userId: userId,
      date: today,
    );

    result.fold(
      (failure) => state = state.copyWith(
        status: NutritionGoalsStatus.error,
        errorMessage: failure.message,
      ),
      (nutritionData) => state = state.copyWith(
        status: NutritionGoalsStatus.loaded,
        currentProgress: nutritionData,
      ),
    );
  }

  /// Create a new nutritional goal
  Future<void> createGoal(String userId, NutritionalGoal goal) async {
    state = state.copyWith(status: NutritionGoalsStatus.updating);

    final result = await _repository.createGoal(
      userId: userId,
      name: goal.name,
      type: goal.type,
      targetValue: goal.targetValue,
      startDate: goal.startDate,
      endDate: goal.endDate,
      notes: goal.notes,
    );

    result.fold(
      (failure) => state = state.copyWith(
        status: NutritionGoalsStatus.error,
        errorMessage: failure.message,
      ),
      (_) async {
        await loadNutritionGoals(userId);
        state = state.copyWith(status: NutritionGoalsStatus.updated);
      },
    );
  }

  /// Update an existing nutritional goal
  Future<void> updateGoal(String userId, NutritionalGoal goal) async {
    state = state.copyWith(status: NutritionGoalsStatus.updating);

    final result = await _repository.updateGoal(
      userId: userId,
      updatedGoal: goal,
    );

    result.fold(
      (failure) => state = state.copyWith(
        status: NutritionGoalsStatus.error,
        errorMessage: failure.message,
      ),
      (_) async {
        await loadNutritionGoals(userId);
        state = state.copyWith(status: NutritionGoalsStatus.updated);
      },
    );
  }

  /// Delete a nutritional goal
  Future<void> deleteGoal(String userId, String goalId) async {
    state = state.copyWith(status: NutritionGoalsStatus.updating);

    final result = await _repository.deleteGoal(userId: userId, goalId: goalId);

    result.fold(
      (failure) => state = state.copyWith(
        status: NutritionGoalsStatus.error,
        errorMessage: failure.message,
      ),
      (_) async {
        await loadNutritionGoals(userId);
        state = state.copyWith(status: NutritionGoalsStatus.updated);
      },
    );
  }
}

/// Provider for nutrition goals
final nutritionGoalsProvider =
    StateNotifierProvider<NutritionGoalsNotifier, NutritionGoalsState>((ref) {
      return getIt<NutritionGoalsNotifier>();
    });
