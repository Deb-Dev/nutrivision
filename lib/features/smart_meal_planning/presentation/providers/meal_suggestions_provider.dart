import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/meal_suggestion.dart';
import '../../domain/usecases/get_meal_suggestions_usecase.dart';
import '../../domain/repositories/meal_suggestion_repository.dart';
import '../../data/services/meal_suggestion_service.dart';
import '../../../../core/di/injection.dart';

/// State for meal suggestions
class MealSuggestionsState {
  final List<MealSuggestion> suggestions;
  final List<MealSuggestion>
  originalSuggestions; // Store original list for filtering
  final bool isLoading;
  final Failure? failure;

  const MealSuggestionsState({
    this.suggestions = const [],
    this.originalSuggestions = const [],
    this.isLoading = false,
    this.failure,
  });

  MealSuggestionsState copyWith({
    List<MealSuggestion>? suggestions,
    List<MealSuggestion>? originalSuggestions,
    bool? isLoading,
    Failure? failure,
  }) {
    return MealSuggestionsState(
      suggestions: suggestions ?? this.suggestions,
      originalSuggestions: originalSuggestions ?? this.originalSuggestions,
      isLoading: isLoading ?? this.isLoading,
      failure: failure,
    );
  }
}

/// Provider for meal suggestions
class MealSuggestionsNotifier extends StateNotifier<MealSuggestionsState> {
  final GetMealSuggestionsUseCase _getMealSuggestionsUseCase;

  MealSuggestionsNotifier(this._getMealSuggestionsUseCase)
    : super(const MealSuggestionsState());

  /// Get meal suggestions for a specific meal type
  Future<void> getMealSuggestions({
    required String userId,
    required String mealType,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? nutritionalRequirements,
    bool forceRefresh = false,
  }) async {
    // Don't show loading if there are already suggestions and not forcing refresh
    final bool hasExistingSuggestions =
        state.suggestions.isNotEmpty &&
        state.suggestions.any((s) => s.mealType == mealType);

    if (forceRefresh || !hasExistingSuggestions) {
      state = forceRefresh
          ? const MealSuggestionsState(isLoading: true)
          : state.copyWith(isLoading: true, failure: null);
    }

    // Add timestamp and request flags to ensure proper caching behavior
    final updatedPreferences = {
      ...preferences ?? {},
      'requestTimestamp': DateTime.now().millisecondsSinceEpoch,
      'forceRefresh': forceRefresh,
      'uniqueId': '${DateTime.now().millisecondsSinceEpoch}_$mealType',
    };

    final result = await _getMealSuggestionsUseCase(
      GetMealSuggestionsParams(
        userId: userId,
        mealType: mealType,
        preferences: updatedPreferences,
        nutritionalRequirements: nutritionalRequirements ?? {},
      ),
    );

    result.fold(
      (failure) => state = state.copyWith(isLoading: false, failure: failure),
      (suggestions) => state = state.copyWith(
        isLoading: false,
        suggestions: suggestions,
        originalSuggestions: suggestions, // Store original for filtering
      ),
    );
  }

  /// Force refresh suggestions
  Future<void> refreshSuggestions({
    required String userId,
    required String mealType,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? nutritionalRequirements,
  }) async {
    await getMealSuggestions(
      userId: userId,
      mealType: mealType,
      preferences: preferences,
      nutritionalRequirements: nutritionalRequirements,
      forceRefresh: true,
    );
  }

  /// Filter suggestions by criteria
  void filterSuggestions(String query) {
    if (query.isEmpty) {
      resetFilters();
      return;
    }

    final filtered = state.originalSuggestions.where((suggestion) {
      final name = suggestion.name.toLowerCase();
      final description = suggestion.description?.toLowerCase() ?? '';
      final searchQuery = query.toLowerCase();

      return name.contains(searchQuery) || description.contains(searchQuery);
    }).toList();

    state = state.copyWith(suggestions: filtered);
  }

  /// Reset to original suggestions without making new API calls
  void resetFilters() {
    state = state.copyWith(suggestions: state.originalSuggestions);
  }
}

/// Provider for meal suggestions
final mealSuggestionsProvider =
    StateNotifierProvider<MealSuggestionsNotifier, MealSuggestionsState>((ref) {
      final getMealSuggestionsUseCase = ref.watch(
        getMealSuggestionsUseCaseProvider,
      );
      return MealSuggestionsNotifier(getMealSuggestionsUseCase);
    });

/// Provider for the use case
final getMealSuggestionsUseCaseProvider = Provider<GetMealSuggestionsUseCase>((
  ref,
) {
  // Use GetIt singleton instead of creating new instances
  return getIt<GetMealSuggestionsUseCase>();
});

/// Provider for the repository
final mealSuggestionRepositoryProvider = Provider<MealSuggestionRepository>((
  ref,
) {
  // Use GetIt singleton instead of creating new instances
  return getIt<MealSuggestionRepository>();
});

/// Provider for the meal suggestion service
final mealSuggestionServiceProvider = Provider<MealSuggestionService>((ref) {
  // Use GetIt singleton instead of creating new instances
  return getIt<MealSuggestionService>();
});
