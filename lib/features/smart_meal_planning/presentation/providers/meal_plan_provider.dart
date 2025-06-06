import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/meal_plan.dart';
import '../../domain/usecases/create_meal_plan_usecase.dart';
import '../../domain/repositories/meal_plan_repository.dart';
import '../../data/repositories/meal_plan_repository_impl.dart';

/// State for meal plans
class MealPlanState {
  final List<MealPlan> mealPlans;
  final MealPlan? activeMealPlan;
  final bool isLoading;
  final Failure? failure;

  const MealPlanState({
    this.mealPlans = const [],
    this.activeMealPlan,
    this.isLoading = false,
    this.failure,
  });

  MealPlanState copyWith({
    List<MealPlan>? mealPlans,
    MealPlan? activeMealPlan,
    bool? isLoading,
    Failure? failure,
  }) {
    return MealPlanState(
      mealPlans: mealPlans ?? this.mealPlans,
      activeMealPlan: activeMealPlan ?? this.activeMealPlan,
      isLoading: isLoading ?? this.isLoading,
      failure: failure,
    );
  }
}

/// Provider for meal plans
class MealPlanNotifier extends StateNotifier<MealPlanState> {
  final CreateMealPlanUseCase _createMealPlanUseCase;

  MealPlanNotifier(this._createMealPlanUseCase) : super(const MealPlanState());

  /// Create a new meal plan
  Future<void> createMealPlan({
    required String userId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    Map<String, dynamic>? preferences,
    bool makeActive = false,
  }) async {
    state = state.copyWith(isLoading: true, failure: null);

    final result = await _createMealPlanUseCase(
      CreateMealPlanParams(
        userId: userId,
        name: name,
        startDate: startDate,
        endDate: endDate,
        preferences: preferences ?? {},
        makeActive: makeActive,
      ),
    );

    result.fold(
      (failure) => state = state.copyWith(isLoading: false, failure: failure),
      (newMealPlan) {
        // Add to list and set as active if needed
        final updatedPlans = [...state.mealPlans, newMealPlan];

        state = state.copyWith(
          isLoading: false,
          mealPlans: updatedPlans,
          activeMealPlan: newMealPlan.isActive
              ? newMealPlan
              : state.activeMealPlan,
        );
      },
    );
  }

  /// Set a meal plan as active
  void setActiveMealPlan(MealPlan mealPlan) {
    // Logic to set a meal plan as active will be implemented here
    // For now, just update the state
    state = state.copyWith(activeMealPlan: mealPlan);
  }

  /// Add a meal to a plan
  void addMealToPlan(
    MealPlan mealPlan,
    DateTime date,
    String mealType,
    PlannedMeal meal,
  ) {
    // Find the meal plan in the list
    final index = state.mealPlans.indexWhere((p) => p.id == mealPlan.id);
    if (index == -1) return;

    // Get the existing plan
    final existingPlan = state.mealPlans[index];

    // Check if there's already a daily plan for this date
    final existingDailyPlan = existingPlan.plannedMeals[date];
    final DailyMealPlan updatedDailyPlan;

    if (existingDailyPlan != null) {
      // Update existing daily plan
      final updatedMeals = Map<String, PlannedMeal>.from(
        existingDailyPlan.meals,
      );
      updatedMeals[mealType] = meal;

      updatedDailyPlan = existingDailyPlan.copyWith(meals: updatedMeals);
    } else {
      // Create new daily plan
      updatedDailyPlan = DailyMealPlan(
        id: 'daily_${DateTime.now().millisecondsSinceEpoch}',
        date: date,
        meals: {mealType: meal},
      );
    }

    // Update the meal plan's plannedMeals
    final updatedPlannedMeals = Map<DateTime, DailyMealPlan>.from(
      existingPlan.plannedMeals,
    );
    updatedPlannedMeals[date] = updatedDailyPlan;

    // Create updated meal plan
    final updatedPlan = existingPlan.copyWith(
      plannedMeals: updatedPlannedMeals,
      lastModifiedAt: DateTime.now(),
    );

    // Update the list of meal plans
    final updatedPlans = List<MealPlan>.from(state.mealPlans);
    updatedPlans[index] = updatedPlan;

    // Update state
    state = state.copyWith(
      mealPlans: updatedPlans,
      activeMealPlan: state.activeMealPlan?.id == updatedPlan.id
          ? updatedPlan
          : state.activeMealPlan,
    );
  }

  /// Load the active meal plan for a user
  Future<void> loadActiveMealPlan(String userId) async {
    state = state.copyWith(isLoading: true, failure: null);

    // This method should be injected, but for simplicity, we'll get it directly
    final repository = GetIt.instance<MealPlanRepository>();
    final result = await repository.getActiveMealPlan(userId);

    result.fold(
      (failure) => state = state.copyWith(isLoading: false, failure: failure),
      (activePlan) =>
          state = state.copyWith(isLoading: false, activeMealPlan: activePlan),
    );
  }

  /// Load all meal plans for a user
  Future<void> loadUserMealPlans(String userId) async {
    state = state.copyWith(isLoading: true, failure: null);

    // This method should be injected, but for simplicity, we'll get it directly
    final repository = GetIt.instance<MealPlanRepository>();
    final result = await repository.getUserMealPlans(userId);

    result.fold(
      (failure) => state = state.copyWith(isLoading: false, failure: failure),
      (mealPlans) =>
          state = state.copyWith(isLoading: false, mealPlans: mealPlans),
    );
  }
}

/// Provider for meal plans
final mealPlanProvider = StateNotifierProvider<MealPlanNotifier, MealPlanState>(
  (ref) {
    final createMealPlanUseCase = ref.watch(createMealPlanUseCaseProvider);
    return MealPlanNotifier(createMealPlanUseCase);
  },
);

/// Provider for the use case
final createMealPlanUseCaseProvider = Provider<CreateMealPlanUseCase>((ref) {
  final repository = ref.watch(mealPlanRepositoryProvider);
  return CreateMealPlanUseCase(repository);
});

/// Provider for the repository
final mealPlanRepositoryProvider = Provider<MealPlanRepository>((ref) {
  return MealPlanRepositoryImpl(FirebaseFirestore.instance);
});
