import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/ai_meal_logging/domain/entities/ai_meal_recognition.dart'; // Adjusted import path
import '../../features/advanced_meal_mgmt/utils/meal_name_generator.dart';

part 'meal_models.freezed.dart';
part 'meal_models.g.dart';

/// Unified meal entry that can represent both manual and AI-logged meals
@freezed
class MealHistoryEntry with _$MealHistoryEntry {
  const factory MealHistoryEntry({
    required String id,
    required String userId,
    required DateTime loggedAt,
    required String
    mealType, // breakfast, lunch, dinner, snack - String to allow flexibility, consider Enum if strictly defined
    required MealSource source, // manual or ai_assisted
    required List<FoodItem> foodItems, // Unified food items
    required NutritionalSummary nutrition,
    String? description,
    String? notes,
    // AI-specific fields
    String? imageId,
    // Edit tracking
    DateTime? editedAt,
    @Default(0) int editCount,
  }) = _MealHistoryEntry;

  factory MealHistoryEntry.fromJson(Map<String, dynamic> json) =>
      _$MealHistoryEntryFromJson(json);

  /// Create from AI meal log
  factory MealHistoryEntry.fromAIMeal(AIMealLog aiMeal) {
    // Generate meaningful meal name using the same logic as home screen
    String generatedMealName;
    try {
      // Convert AIMealLog to the format expected by generateFromAIMealData
      final aiMealData = {
        'confirmedItems': aiMeal.items
            .map((item) => {'name': item.name, 'foodName': item.name})
            .toList(),
        'mealType': aiMeal.mealType,
      };
      generatedMealName = MealNameGenerator.generateFromAIMealData(aiMealData);
      print('🔍 [AI MEAL CONVERSION] Generated name: "$generatedMealName"');
    } catch (e) {
      print('🔍 [AI MEAL CONVERSION] Error generating name: $e');
      generatedMealName = 'AI ${aiMeal.mealType}';
    }

    return MealHistoryEntry(
      id: aiMeal.id,
      userId: '', // Will be set from query context
      loggedAt: aiMeal.loggedAt,
      mealType: aiMeal.mealType,
      source: MealSource.aiAssisted,
      foodItems: aiMeal.items
          .map((item) => FoodItem.fromConfirmedMealItem(item))
          .toList(),
      nutrition: NutritionalSummary.fromAIMeal(aiMeal.totalNutrition),
      description: generatedMealName, // Use generated name
      notes: aiMeal.notes,
      imageId: aiMeal.imageId,
    );
  }

  /// Create from manual meal data
  factory MealHistoryEntry.fromManualMeal(
    Map<String, dynamic> data,
    String mealId,
    String userId,
  ) {
    final foodItems = <FoodItem>[];

    // Manual meals use 'foods' field, not 'foodItems'
    if (data['foods'] != null && data['foods'] is List) {
      for (final item in data['foods'] as List) {
        if (item is Map<String, dynamic>) {
          foodItems.add(FoodItem.fromJson(item));
        }
      }
    } else if (data['foodItems'] != null && data['foodItems'] is List) {
      // Fallback for any meals that might use 'foodItems'
      for (final item in data['foodItems'] as List) {
        if (item is Map<String, dynamic>) {
          foodItems.add(FoodItem.fromJson(item));
        }
      }
    }

    DateTime? loggedAtDate;
    // Manual meals use 'timestamp' field, not 'loggedAt'
    if (data['timestamp'] is Timestamp) {
      loggedAtDate = (data['timestamp'] as Timestamp).toDate();
    } else if (data['timestamp'] is String) {
      loggedAtDate = DateTime.tryParse(data['timestamp'] as String);
    } else if (data['loggedAt'] is Timestamp) {
      // Fallback for any meals that might use 'loggedAt'
      loggedAtDate = (data['loggedAt'] as Timestamp).toDate();
    } else if (data['loggedAt'] is String) {
      loggedAtDate = DateTime.tryParse(data['loggedAt'] as String);
    }
    loggedAtDate ??= DateTime.now();

    DateTime? editedAtDate;
    if (data['editedAt'] is Timestamp) {
      editedAtDate = (data['editedAt'] as Timestamp).toDate();
    } else if (data['editedAt'] is String) {
      editedAtDate = DateTime.tryParse(data['editedAt'] as String);
    }

    // Check for existing name/description or generate meaningful meal name
    String generatedMealName;
    // First check if there's already a name or description in the data
    if (data['name'] != null && data['name'] is String && (data['name'] as String).isNotEmpty) {
      generatedMealName = data['name'] as String;
      print('🔍 [MANUAL MEAL CONVERSION] Using existing name: "$generatedMealName"');
    } else if (data['description'] != null && data['description'] is String && (data['description'] as String).isNotEmpty) {
      generatedMealName = data['description'] as String;
      print('🔍 [MANUAL MEAL CONVERSION] Using existing description: "$generatedMealName"');
    } else {
      // If no name/description, generate one
      try {
        generatedMealName = MealNameGenerator.generateFromRegularMealData(data);
        print('🔍 [MANUAL MEAL CONVERSION] Generated name: "$generatedMealName"');
      } catch (e) {
        print('🔍 [MANUAL MEAL CONVERSION] Error generating name: $e');
        final mealType = data['mealType'] as String? ?? 'meal';
        generatedMealName =
            '${mealType[0].toUpperCase()}${mealType.substring(1).toLowerCase()} Meal';
      }
    }

    return MealHistoryEntry(
      id: mealId,
      userId: userId,
      loggedAt: loggedAtDate,
      mealType: data['mealType'] as String? ?? 'meal',
      source: MealSource.manual,
      foodItems: foodItems,
      nutrition: data['nutrition'] != null && data['nutrition'] is Map
        ? NutritionalSummary.fromJson(Map<String, dynamic>.from(data['nutrition'] as Map))
        : NutritionalSummary.fromManualMeal(
            calories: (data['calories'] as num?)?.toInt() ?? 0,
            protein: (data['proteinGrams'] as num?)?.toDouble() ?? 0.0,
            carbs: (data['carbsGrams'] as num?)?.toDouble() ?? 0.0,
            fat: (data['fatGrams'] as num?)?.toDouble() ?? 0.0,
          ),
      description:
          generatedMealName, // Use generated name instead of raw description
      notes: data['notes'] as String?,
      editedAt: editedAtDate,
      editCount: (data['editCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Source of the meal entry
enum MealSource {
  @JsonValue('manual')
  manual,
  @JsonValue('ai_assisted')
  aiAssisted,
}

/// Unified food item that works for both manual and AI meals
@freezed
class FoodItem with _$FoodItem {
  const factory FoodItem({
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
  }) = _FoodItem;

  factory FoodItem.fromJson(Map<String, dynamic> json) =>
      _$FoodItemFromJson(json);

  /// Create from confirmed meal item (AI)
  factory FoodItem.fromConfirmedMealItem(ConfirmedMealItem item) {
    return FoodItem(
      name: item.name,
      quantity: item.quantity,
      unit: item.servingUnit,
      calories: item.nutrition.calories.toDouble(),
      protein: item.nutrition.protein,
      carbs: item.nutrition.carbs,
      fat: item.nutrition.fat,
      fiber: item.nutrition.fiber,
      sugar: item.nutrition.sugar,
      sodium: item.nutrition.sodium,
      foodId: item.foodId,
    );
  }
}

/// Nutritional summary for meal history display
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

  /// Create from AI meal log
  factory NutritionalSummary.fromAIMeal(NutritionalEstimate estimate) {
    return NutritionalSummary(
      calories: estimate.calories,
      protein: estimate.protein,
      carbs: estimate.carbs,
      fat: estimate.fat,
      fiber: estimate.fiber,
      sugar: estimate.sugar,
      sodium: estimate.sodium,
    );
  }

  /// Create from manual meal data
  factory NutritionalSummary.fromManualMeal({
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
  }) {
    return NutritionalSummary(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
    );
  }
}

/// Meal type enum for consistency
enum MealType {
  @JsonValue('breakfast')
  breakfast,
  @JsonValue('lunch')
  lunch,
  @JsonValue('dinner')
  dinner,
  @JsonValue('snack')
  snack,
}

/// Grouped meal history for UI display
@freezed
class GroupedMealHistory with _$GroupedMealHistory {
  const factory GroupedMealHistory({
    required Map<DateTime, List<MealHistoryEntry>> groupedMeals,
    required int totalMeals,
  }) = _GroupedMealHistory;

  factory GroupedMealHistory.fromJson(Map<String, dynamic> json) =>
      _$GroupedMealHistoryFromJson(json);
}

/// Filter for meal history
@freezed
class MealHistoryFilter with _$MealHistoryFilter {
  const factory MealHistoryFilter({
    @Default(30) int days,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? mealTypes,
    @Default([]) List<MealSource> sources,
    String? searchQuery,
  }) = _MealHistoryFilter;

  factory MealHistoryFilter.fromJson(Map<String, dynamic> json) =>
      _$MealHistoryFilterFromJson(json);
}

// GoalType enum removed from this file. It should reside in meal_history.dart or a more specific domain entity file.
