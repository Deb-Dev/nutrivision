import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_meal_recognition.freezed.dart';
part 'ai_meal_recognition.g.dart';

/// Domain entity representing a recognized food item from AI analysis
@freezed
class RecognizedFoodItem with _$RecognizedFoodItem {
  const factory RecognizedFoodItem({
    required String name,
    required double confidence,
    required String estimatedServing,
    required NutritionalEstimate nutritionalEstimate,
    String? foodId, // ID from food database if matched
    String? boundingBox, // Optional bounding box coordinates
  }) = _RecognizedFoodItem;

  factory RecognizedFoodItem.fromJson(Map<String, dynamic> json) =>
      _$RecognizedFoodItemFromJson(json);
}

/// Domain entity for nutritional estimates from AI
@freezed
class NutritionalEstimate with _$NutritionalEstimate {
  const factory NutritionalEstimate({
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
    double? fiber,
    double? sugar,
    double? sodium,
  }) = _NutritionalEstimate;

  factory NutritionalEstimate.fromJson(Map<String, dynamic> json) =>
      _$NutritionalEstimateFromJson(json);
}

/// Domain entity representing the complete AI meal recognition result
@freezed
class AIMealRecognitionResult with _$AIMealRecognitionResult {
  const factory AIMealRecognitionResult({
    required List<RecognizedFoodItem> recognizedItems,
    required bool isSuccessful,
    String? errorMessage,
    required double processingTime,
    required DateTime analyzedAt,
    String? imageId,
  }) = _AIMealRecognitionResult;

  factory AIMealRecognitionResult.fromJson(Map<String, dynamic> json) =>
      _$AIMealRecognitionResultFromJson(json);
}

/// Domain entity for confirmed meal items after user editing
@freezed
class ConfirmedMealItem with _$ConfirmedMealItem {
  const factory ConfirmedMealItem({
    required String name,
    required String foodId,
    required double quantity,
    required String servingUnit,
    required NutritionalEstimate nutrition,
    required bool wasAIRecognized,
    double? originalConfidence,
  }) = _ConfirmedMealItem;

  factory ConfirmedMealItem.fromJson(Map<String, dynamic> json) =>
      _$ConfirmedMealItemFromJson(json);
}

/// Domain entity for a complete AI-assisted meal log
@freezed
class AIMealLog with _$AIMealLog {
  const factory AIMealLog({
    required String id,
    required List<ConfirmedMealItem> items,
    required DateTime loggedAt,
    required String imageId,
    required AIMealRecognitionResult originalAnalysis,
    required NutritionalEstimate totalNutrition,
    required String mealType, // breakfast, lunch, dinner, snack
    String? notes,
  }) = _AIMealLog;

  factory AIMealLog.fromJson(Map<String, dynamic> json) =>
      _$AIMealLogFromJson(json);
}
