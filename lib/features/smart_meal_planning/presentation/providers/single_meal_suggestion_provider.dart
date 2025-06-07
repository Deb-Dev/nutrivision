import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/meal_suggestion.dart';
import '../../data/services/single_meal_suggestion_service.dart';
import '../../../../core/di/injection.dart';
import 'meal_plan_provider.dart';

/// State for single meal suggestion
class SingleMealSuggestionState {
  final MealSuggestion? currentSuggestion;
  final bool isLoading;
  final Failure? failure;
  final int rejectionCount;
  final List<String> recentRejections;

  const SingleMealSuggestionState({
    this.currentSuggestion,
    this.isLoading = false,
    this.failure,
    this.rejectionCount = 0,
    this.recentRejections = const [],
  });

  SingleMealSuggestionState copyWith({
    MealSuggestion? currentSuggestion,
    bool? isLoading,
    Failure? failure,
    int? rejectionCount,
    List<String>? recentRejections,
  }) {
    return SingleMealSuggestionState(
      currentSuggestion: currentSuggestion,
      isLoading: isLoading ?? this.isLoading,
      failure: failure,
      rejectionCount: rejectionCount ?? this.rejectionCount,
      recentRejections: recentRejections ?? this.recentRejections,
    );
  }
}

/// Provider for single meal suggestions with rejection learning
class SingleMealSuggestionNotifier
    extends StateNotifier<SingleMealSuggestionState> {
  final SingleMealSuggestionService _singleMealSuggestionService;
  final Ref _ref;

  SingleMealSuggestionNotifier(this._singleMealSuggestionService, this._ref)
    : super(const SingleMealSuggestionState());

  /// Load the next meal suggestion
  Future<void> loadNextSuggestion({
    required String userId,
    required String mealType,
    required DateTime date,
    String? rejectionReason,
  }) async {
    state = state.copyWith(isLoading: true, failure: null);

    try {
      final suggestion = await _singleMealSuggestionService
          .generateSingleSuggestion(
            userId: userId,
            mealType: mealType,
            date: date,
            recentRejections: state.recentRejections,
            rejectionReason: rejectionReason,
          );

      // Update rejections list if we had a rejection
      List<String> updatedRejections = List.from(state.recentRejections);
      if (rejectionReason != null) {
        updatedRejections.add(rejectionReason);
        // Keep only recent rejections (last 5)
        if (updatedRejections.length > 5) {
          updatedRejections = updatedRejections
              .skip(updatedRejections.length - 5)
              .toList();
        }
      }

      state = state.copyWith(
        isLoading: false,
        currentSuggestion: suggestion,
        rejectionCount: rejectionReason != null
            ? state.rejectionCount + 1
            : state.rejectionCount,
        recentRejections: updatedRejections,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        failure: ServerFailure(message: e.toString()),
      );
    }
  }

  /// Record a rejection with feedback
  Future<void> recordRejection({
    required String userId,
    required String suggestionId,
    required String mealType,
    String? reason,
    String? userNote,
  }) async {
    try {
      await _singleMealSuggestionService.recordRejection(
        userId: userId,
        suggestionId: suggestionId,
        mealType: mealType,
        reason: reason,
        userNote: userNote,
      );
    } catch (e) {
      print('❌ Error recording rejection: $e');
    }
  }

  /// Accept a suggestion and add it to the meal plan
  Future<void> acceptSuggestion({
    required String userId,
    required MealSuggestion suggestion,
    required String mealType,
    required DateTime date,
  }) async {
    try {
      await _singleMealSuggestionService.acceptSuggestion(
        userId: userId,
        suggestion: suggestion,
        mealType: mealType,
        date: date,
      );

      // Clear the current suggestion since it's been accepted
      state = state.copyWith(currentSuggestion: null);

      // Trigger reload of meal plans to reflect the new planned meal
      _ref.read(mealPlanProvider.notifier).loadActiveMealPlan(userId);

      print('✅ Suggestion accepted and meal plan refreshed');
    } catch (e) {
      print('❌ Error accepting suggestion: $e');
      state = state.copyWith(
        failure: ServerFailure(message: 'Failed to accept suggestion: $e'),
      );
    }
  }

  /// Reset the state (e.g., when starting fresh)
  void reset() {
    state = const SingleMealSuggestionState();
  }
}

/// Provider instance
final singleMealSuggestionProvider =
    StateNotifierProvider<
      SingleMealSuggestionNotifier,
      SingleMealSuggestionState
    >((ref) {
      return SingleMealSuggestionNotifier(
        getIt<SingleMealSuggestionService>(),
        ref,
      );
    });
