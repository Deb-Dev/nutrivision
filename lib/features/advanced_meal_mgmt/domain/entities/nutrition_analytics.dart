import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/material.dart';

part 'nutrition_analytics.freezed.dart';
part 'nutrition_analytics.g.dart';

/// Converter for Flutter Color to/from JSON
class ColorConverter implements JsonConverter<Color, int> {
  const ColorConverter();

  @override
  Color fromJson(int json) => Color(json);

  @override
  int toJson(Color object) => object.toARGB32();
}

/// Comprehensive nutrition analytics for a specific time period
@freezed
class NutritionAnalytics with _$NutritionAnalytics {
  const factory NutritionAnalytics({
    required DateTime startDate,
    required DateTime endDate,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    @Default(0.0) double fiber,
    @Default(0.0) double sugar,
    @Default(0.0) double sodium,
    @Default(0) int mealCount,
    @Default([]) List<TrendData> trendData,
  }) = _NutritionAnalytics;

  factory NutritionAnalytics.fromJson(Map<String, dynamic> json) =>
      _$NutritionAnalyticsFromJson(json);
}

/// Data point for nutrition trends over time
@freezed
class TrendData with _$TrendData {
  const factory TrendData({
    required DateTime date,
    required double value,
    @Default('') String label,
  }) = _TrendData;

  factory TrendData.fromJson(Map<String, dynamic> json) =>
      _$TrendDataFromJson(json);
}

/// Macro breakdown data for charts
@freezed
class MacroData with _$MacroData {
  const factory MacroData({
    required String name,
    required double value,
    @ColorConverter() required Color color,
    required String displayLabel,
  }) = _MacroData;

  factory MacroData.fromJson(Map<String, dynamic> json) =>
      _$MacroDataFromJson(json);
}

/// Meal distribution data for meal timing analysis
@freezed
class MealDistribution with _$MealDistribution {
  const factory MealDistribution({
    required String mealType,
    required int count,
    required int percentage,
    required double avgCalories,
  }) = _MealDistribution;

  factory MealDistribution.fromJson(Map<String, dynamic> json) =>
      _$MealDistributionFromJson(json);
}

/// Nutrient comparison against goals
@freezed
class NutrientComparison with _$NutrientComparison {
  const factory NutrientComparison({
    required String nutrient,
    required double actual,
    required double goal,
    required double percentage,
    required bool isOnTrack,
  }) = _NutrientComparison;

  factory NutrientComparison.fromJson(Map<String, dynamic> json) =>
      _$NutrientComparisonFromJson(json);
}
