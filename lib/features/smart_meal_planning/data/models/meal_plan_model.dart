import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/models/meal_models.dart';
import '../../domain/entities/meal_plan.dart';

part 'meal_plan_model.freezed.dart';
part 'meal_plan_model.g.dart';

/// Data model for MealPlan with JSON serialization for Firestore
@freezed
class MealPlanModel with _$MealPlanModel {
  const MealPlanModel._();

  const factory MealPlanModel({
    required String id,
    required String userId,
    required String name,
    required DateTime createdAt,
    DateTime? lastModifiedAt,
    required Map<String, DailyMealPlanModel> plannedMeals,
    String? description,
    @Default(false) bool isActive,
    @Default(MealPlanSource.user) MealPlanSource source,
    @Default({}) Map<String, dynamic> metadata,
  }) = _MealPlanModel;

  /// Create model from JSON map
  factory MealPlanModel.fromJson(Map<String, dynamic> json) =>
      _$MealPlanModelFromJson(json);

  /// Convert from Firestore DocumentSnapshot
  factory MealPlanModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Convert Firestore Timestamps to DateTime
    final createdAt = (data['createdAt'] as Timestamp).toDate();
    final lastModifiedAt = data['lastModifiedAt'] != null
        ? (data['lastModifiedAt'] as Timestamp).toDate()
        : null;

    // Convert plannedMeals string dates to DateTime keys
    final rawPlannedMeals = data['plannedMeals'] as Map<String, dynamic>;
    final plannedMeals = <String, DailyMealPlanModel>{};

    rawPlannedMeals.forEach((key, value) {
      // The key is a date string in ISO format
      plannedMeals[key] = DailyMealPlanModel.fromJson(value);
    });

    return MealPlanModel(
      id: doc.id,
      userId: data['userId'] as String,
      name: data['name'] as String,
      createdAt: createdAt,
      lastModifiedAt: lastModifiedAt,
      plannedMeals: plannedMeals,
      description: data['description'] as String?,
      isActive: data['isActive'] as bool? ?? false,
      source: MealPlanSource.values.firstWhere(
        (s) => s.toString() == 'MealPlanSource.${data['source'] ?? 'user'}',
        orElse: () => MealPlanSource.user,
      ),
      metadata: data['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> plannedMealsMap = {};

    plannedMeals.forEach((key, value) {
      plannedMealsMap[key] = value.toJson();
    });

    return {
      'userId': userId,
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastModifiedAt': lastModifiedAt != null
          ? Timestamp.fromDate(lastModifiedAt!)
          : null,
      'plannedMeals': plannedMealsMap,
      'description': description,
      'isActive': isActive,
      'source': source.toString().split('.').last,
      'metadata': metadata,
    };
  }

  /// Convert to domain entity
  MealPlan toDomain() {
    // Convert plannedMeals map to use DateTime keys
    final domainPlannedMeals = <DateTime, DailyMealPlan>{};

    plannedMeals.forEach((key, value) {
      domainPlannedMeals[DateTime.parse(key)] = value.toDomain();
    });

    return MealPlan(
      id: id,
      userId: userId,
      name: name,
      createdAt: createdAt,
      lastModifiedAt: lastModifiedAt,
      plannedMeals: domainPlannedMeals,
      description: description,
      isActive: isActive,
      source: source,
      metadata: metadata,
    );
  }
}

/// Data model for DailyMealPlan with JSON serialization
@freezed
class DailyMealPlanModel with _$DailyMealPlanModel {
  const DailyMealPlanModel._();

  const factory DailyMealPlanModel({
    required String id,
    required String date, // ISO date string
    required Map<String, PlannedMealModel> meals,
    @Default(false) bool isCompleted,
    String? notes,
  }) = _DailyMealPlanModel;

  /// Create model from JSON map
  factory DailyMealPlanModel.fromJson(Map<String, dynamic> json) =>
      _$DailyMealPlanModelFromJson(json);

  /// Convert to domain entity
  DailyMealPlan toDomain() {
    final domainMeals = <String, PlannedMeal>{};

    meals.forEach((key, value) {
      domainMeals[key] = value.toDomain();
    });

    return DailyMealPlan(
      id: id,
      date: DateTime.parse(date),
      meals: domainMeals,
      isCompleted: isCompleted,
      notes: notes,
    );
  }
}

/// Data model for PlannedMeal with JSON serialization
@freezed
class PlannedMealModel with _$PlannedMealModel {
  const PlannedMealModel._();

  const factory PlannedMealModel({
    required String id,
    required String mealType,
    required List<PlannedFoodItemModel> items,
    required NutritionalSummaryModel estimatedNutrition,
    @Default(false) bool isCompleted,
    String? completedAt, // ISO date string
    String? actualMealId,
    String? notes,
    @Default(PlannedMealSource.suggested) PlannedMealSource source,
  }) = _PlannedMealModel;

  /// Create model from JSON map
  factory PlannedMealModel.fromJson(Map<String, dynamic> json) =>
      _$PlannedMealModelFromJson(json);

  /// Convert to domain entity
  PlannedMeal toDomain() {
    return PlannedMeal(
      id: id,
      mealType: mealType,
      items: items.map((item) => item.toDomain()).toList(),
      estimatedNutrition: estimatedNutrition.toDomain(),
      isCompleted: isCompleted,
      completedAt: completedAt != null ? DateTime.parse(completedAt!) : null,
      actualMealId: actualMealId,
      notes: notes,
      source: source,
    );
  }
}

/// Data model for PlannedFoodItem with JSON serialization
@freezed
class PlannedFoodItemModel with _$PlannedFoodItemModel {
  const PlannedFoodItemModel._();

  const factory PlannedFoodItemModel({
    required String id,
    required String name,
    required double quantity,
    required String unit,
    @Default({}) Map<String, double> nutritionalValues,
    String? recipeId,
    String? imageUrl,
    String? notes,
  }) = _PlannedFoodItemModel;

  /// Create model from JSON map
  factory PlannedFoodItemModel.fromJson(Map<String, dynamic> json) =>
      _$PlannedFoodItemModelFromJson(json);

  /// Convert to domain entity
  PlannedFoodItem toDomain() {
    return PlannedFoodItem(
      id: id,
      name: name,
      quantity: quantity,
      unit: unit,
      nutritionalValues: nutritionalValues,
      recipeId: recipeId,
      imageUrl: imageUrl,
      notes: notes,
    );
  }
}

/// Data model for NutritionalSummary with JSON serialization
@freezed
class NutritionalSummaryModel with _$NutritionalSummaryModel {
  const NutritionalSummaryModel._();

  const factory NutritionalSummaryModel({
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    double? fiber,
    double? sugar,
    double? sodium,
    @Default({}) Map<String, double> micronutrients,
  }) = _NutritionalSummaryModel;

  /// Create model from JSON map
  factory NutritionalSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$NutritionalSummaryModelFromJson(json);

  /// Convert to domain entity
  NutritionalSummary toDomain() {
    return NutritionalSummary(
      calories: calories.toInt(),
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
      sugar: sugar,
      sodium: sodium,
    );
  }
}
