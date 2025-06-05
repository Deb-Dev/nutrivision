import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/nutrition_goals.dart';
import '../../domain/repositories/nutrition_analytics_repository.dart';
import '../../../../core/di/injection.dart';

/// States for nutrition analytics
enum NutritionAnalyticsStatus { initial, loading, loaded, error }

/// State for nutrition analytics provider
class NutritionAnalyticsState {
  final NutritionAnalyticsStatus status;
  final NutritionReport? report;
  final String? errorMessage;
  final AnalyticsPeriod currentPeriod;

  const NutritionAnalyticsState({
    this.status = NutritionAnalyticsStatus.initial,
    this.report,
    this.errorMessage,
    this.currentPeriod = AnalyticsPeriod.weekly,
  });

  NutritionAnalyticsState copyWith({
    NutritionAnalyticsStatus? status,
    NutritionReport? report,
    String? errorMessage,
    AnalyticsPeriod? currentPeriod,
  }) {
    return NutritionAnalyticsState(
      status: status ?? this.status,
      report: report ?? this.report,
      errorMessage: errorMessage ?? this.errorMessage,
      currentPeriod: currentPeriod ?? this.currentPeriod,
    );
  }
}

/// Provider for nutrition analytics
@injectable
class NutritionAnalyticsNotifier
    extends StateNotifier<NutritionAnalyticsState> {
  final NutritionAnalyticsRepository _repository;

  NutritionAnalyticsNotifier(this._repository)
    : super(const NutritionAnalyticsState());

  /// Generate a nutrition report for a specific period
  Future<void> generateReport({
    required String userId,
    required AnalyticsPeriod period,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    state = state.copyWith(
      status: NutritionAnalyticsStatus.loading,
      currentPeriod: period,
    );

    // Calculate date range based on period
    final now = DateTime.now();
    final DateTime startDate;
    final DateTime endDate;

    switch (period) {
      case AnalyticsPeriod.daily:
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate.add(const Duration(days: 1));
        break;
      case AnalyticsPeriod.weekly:
        final daysFromMonday = now.weekday - 1;
        startDate = DateTime(now.year, now.month, now.day - daysFromMonday);
        endDate = startDate.add(const Duration(days: 7));
        break;
      case AnalyticsPeriod.monthly:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 1);
        break;
      case AnalyticsPeriod.custom:
        startDate =
            customStartDate ?? DateTime(now.year, now.month, now.day - 30);
        endDate = customEndDate ?? now;
        break;
    }

    final result = await _repository.generateNutritionReport(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
      period: period,
    );

    result.fold(
      (failure) => state = state.copyWith(
        status: NutritionAnalyticsStatus.error,
        errorMessage: failure.message,
      ),
      (report) => state = state.copyWith(
        status: NutritionAnalyticsStatus.loaded,
        report: report,
      ),
    );
  }

  /// Get meal type distribution for pie chart
  Map<String, int> getMealTypeDistribution() {
    return state.report?.mealTypeDistribution ?? {};
  }

  /// Get daily nutrition data for line chart
  List<DailyNutrition> getDailyNutritionData() {
    return state.report?.dailyNutrition ?? [];
  }

  /// Get average nutrition for progress indicators
  AverageNutrition? getAverageNutrition() {
    return state.report?.averageNutrition;
  }
}

/// Provider for nutrition analytics
final nutritionAnalyticsProvider =
    StateNotifierProvider<NutritionAnalyticsNotifier, NutritionAnalyticsState>((
      ref,
    ) {
      return getIt<NutritionAnalyticsNotifier>();
    });
