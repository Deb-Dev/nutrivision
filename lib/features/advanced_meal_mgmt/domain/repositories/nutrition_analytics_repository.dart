import '../entities/nutrition_goals.dart';
import '../../../../core/utils/result.dart';

/// Repository interface for nutrition analytics operations
abstract class NutritionAnalyticsRepository {
  /// Generate nutrition report for a time period
  Future<Result<NutritionReport>> generateNutritionReport({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    required AnalyticsPeriod period,
  });

  /// Get daily nutrition data for charts
  Future<Result<List<DailyNutrition>>> getDailyNutritionData({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get meal type distribution
  Future<Result<Map<String, int>>> getMealTypeDistribution({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get top foods consumed
  Future<Result<List<TopFood>>> getTopFoods({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  });

  /// Get nutritional trends over time
  Future<Result<NutritionTrends>> getNutritionTrends({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    required AnalyticsPeriod period,
  });

  /// Export nutrition data as CSV
  Future<Result<String>> exportNutritionData({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    required ExportFormat format,
  });
}
