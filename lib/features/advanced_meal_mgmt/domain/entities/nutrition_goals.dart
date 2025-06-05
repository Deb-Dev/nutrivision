import 'package:freezed_annotation/freezed_annotation.dart';

part 'nutrition_goals.freezed.dart';
part 'nutrition_goals.g.dart';

/// Represents a favorite meal that can be quickly logged
@freezed
class FavoriteMeal with _$FavoriteMeal {
  const factory FavoriteMeal({
    required String id,
    required String userId,
    required String name,
    required List<FavoriteFoodItem> foodItems,
    required NutritionalSummary nutrition,
    required String mealType,
    String? imageUrl,
    String? notes,
    required DateTime createdAt,
    DateTime? lastUsed,
    @Default(0) int useCount,
  }) = _FavoriteMeal;

  factory FavoriteMeal.fromJson(Map<String, dynamic> json) =>
      _$FavoriteMealFromJson(json);
}

/// Represents a food item in a favorite meal
@freezed
class FavoriteFoodItem with _$FavoriteFoodItem {
  const factory FavoriteFoodItem({
    required String name,
    required double quantity,
    required String unit,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    double? fiber,
    double? sugar,
    double? sodium,
    String? foodId,
  }) = _FavoriteFoodItem;

  factory FavoriteFoodItem.fromJson(Map<String, dynamic> json) =>
      _$FavoriteFoodItemFromJson(json);
}

/// Nutritional summary for favorite meal
@freezed
class NutritionalSummary with _$NutritionalSummary {
  const factory NutritionalSummary({
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
    double? fiber,
    double? sugar,
    double? sodium,
  }) = _NutritionalSummary;

  factory NutritionalSummary.fromJson(Map<String, dynamic> json) =>
      _$NutritionalSummaryFromJson(json);
}

/// Analytics period for reports
enum AnalyticsPeriod {
  @JsonValue('daily')
  daily,
  @JsonValue('weekly')
  weekly,
  @JsonValue('monthly')
  monthly,
  @JsonValue('custom')
  custom,
}

/// Goal type enum
enum GoalType {
  @JsonValue('daily_calories')
  dailyCalories,
  @JsonValue('daily_protein')
  dailyProtein,
  @JsonValue('daily_carbs')
  dailyCarbs,
  @JsonValue('daily_fat')
  dailyFat,
  @JsonValue('weekly_calories')
  weeklyCalories,
  @JsonValue('water_intake')
  waterIntake,
  @JsonValue('custom')
  custom,
}

/// Export format for nutrition data
enum ExportFormat {
  @JsonValue('csv')
  csv,
  @JsonValue('json')
  json,
  @JsonValue('pdf')
  pdf,
}

/// Top food item in analytics
@freezed
class TopFood with _$TopFood {
  const factory TopFood({
    required String name,
    required int frequency,
    required double totalCalories,
    required double avgCalories,
  }) = _TopFood;

  factory TopFood.fromJson(Map<String, dynamic> json) =>
      _$TopFoodFromJson(json);
}

/// Nutrition trends over time
@freezed
class NutritionTrends with _$NutritionTrends {
  const factory NutritionTrends({
    required Map<String, List<double>> caloriesTrend,
    required Map<String, List<double>> proteinTrend,
    required Map<String, List<double>> carbsTrend,
    required Map<String, List<double>> fatTrend,
    required DateTime startDate,
    required DateTime endDate,
  }) = _NutritionTrends;

  factory NutritionTrends.fromJson(Map<String, dynamic> json) =>
      _$NutritionTrendsFromJson(json);
}

/// Nutrition progress report
@freezed
class NutritionReport with _$NutritionReport {
  const factory NutritionReport({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    required AnalyticsPeriod period,
    required List<DailyNutrition> dailyNutrition,
    required AverageNutrition averageNutrition,
    required Map<String, int> mealTypeDistribution,
    required List<String> topFoods,
  }) = _NutritionReport;

  factory NutritionReport.fromJson(Map<String, dynamic> json) =>
      _$NutritionReportFromJson(json);
}

/// Daily nutrition data for reports
@freezed
class DailyNutrition with _$DailyNutrition {
  const factory DailyNutrition({
    required DateTime date,
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
    int? mealCount,
  }) = _DailyNutrition;

  factory DailyNutrition.fromJson(Map<String, dynamic> json) =>
      _$DailyNutritionFromJson(json);
}

/// Average nutrition data for reports
@freezed
class AverageNutrition with _$AverageNutrition {
  const factory AverageNutrition({
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    double? calorieGoalProgress,
    double? proteinGoalProgress,
    double? carbsGoalProgress,
    double? fatGoalProgress,
  }) = _AverageNutrition;

  factory AverageNutrition.fromJson(Map<String, dynamic> json) =>
      _$AverageNutritionFromJson(json);
}

/// Nutritional goal for tracking progress
@freezed
class NutritionalGoal with _$NutritionalGoal {
  const factory NutritionalGoal({
    required String id,
    required String userId,
    required String name,
    required GoalType type,
    required double targetValue,
    required DateTime startDate,
    DateTime? endDate,
    String? notes,
    DateTime? lastUpdated,
    double? currentProgress,
    @Default(false) bool isCompleted,
  }) = _NutritionalGoal;

  factory NutritionalGoal.fromJson(Map<String, dynamic> json) =>
      _$NutritionalGoalFromJson(json);
}

/// Goal progress update
@freezed
class GoalProgressUpdate with _$GoalProgressUpdate {
  const factory GoalProgressUpdate({
    required String goalId,
    required double currentValue,
    required double progressPercentage,
    required DateTime updatedAt,
  }) = _GoalProgressUpdate;

  factory GoalProgressUpdate.fromJson(Map<String, dynamic> json) =>
      _$GoalProgressUpdateFromJson(json);
}

/// Report generation parameters
@freezed
class ReportParams with _$ReportParams {
  const factory ReportParams({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    required AnalyticsPeriod period,
    List<String>? goalIds,
    List<String>? mealTypes,
  }) = _ReportParams;

  factory ReportParams.fromJson(Map<String, dynamic> json) =>
      _$ReportParamsFromJson(json);
}
