import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/models/meal_models.dart';

part 'meal_history.freezed.dart';
part 'meal_history.g.dart';

/// Filter for meal history queries
@freezed
class MealHistoryFilter with _$MealHistoryFilter {
  const factory MealHistoryFilter({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? mealTypes, // Refers to MealType enum now in core_models
    List<MealSource>? sources, // Refers to MealSource enum now in core_models
    String? searchQuery,
  }) = _MealHistoryFilter;

  factory MealHistoryFilter.fromJson(Map<String, dynamic> json) =>
      _$MealHistoryFilterFromJson(json);
}

/// Grouped meal history for UI display
@freezed
class GroupedMealHistory with _$GroupedMealHistory {
  const factory GroupedMealHistory({
    required Map<DateTime, List<MealHistoryEntry>> groupedMeals, // MealHistoryEntry now from core_models
    required int totalMeals,
  }) = _GroupedMealHistory;

  factory GroupedMealHistory.fromJson(Map<String, dynamic> json) =>
      _$GroupedMealHistoryFromJson(json);
}

/// Nutritional goal for tracking progress
class NutritionalGoal {
  final String id;
  final String userId;
  final String name;
  final GoalType type; // Refers to GoalType enum now in core_models
  final double targetValue;
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;
  final DateTime? lastUpdated;
  final double? currentProgress;
  final bool isCompleted;

  const NutritionalGoal({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.targetValue,
    required this.startDate,
    this.endDate,
    this.notes,
    this.lastUpdated,
    this.currentProgress,
    this.isCompleted = false,
  });

  factory NutritionalGoal.fromJson(Map<String, dynamic> json) {
    return NutritionalGoal(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      type: GoalType.values.firstWhere(
        (e) => e.toString() == 'GoalType.${json['type']}',
        orElse: () => GoalType.dailyCalories, // GoalType now from core_models
      ),
      targetValue: (json['targetValue'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      notes: json['notes'] as String?,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
      currentProgress: json['currentProgress'] != null
          ? (json['currentProgress'] as num).toDouble()
          : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'type': type.toString().split('.').last,
      'targetValue': targetValue,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'notes': notes,
      'lastUpdated': lastUpdated?.toIso8601String(),
      'currentProgress': currentProgress,
      'isCompleted': isCompleted,
    };
  }

  NutritionalGoal copyWith({
    String? id,
    String? userId,
    String? name,
    GoalType? type,
    double? targetValue,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    DateTime? lastUpdated,
    double? currentProgress,
    bool? isCompleted,
  }) {
    return NutritionalGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      currentProgress: currentProgress ?? this.currentProgress,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// Types of nutritional goals
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

/// Statistics for meal history display
class MealHistoryStatistics {
  final int totalMeals;
  final Map<String, int> mealTypeDistribution;
  final Map<MealSource, int> sourceDistribution; // MealSource now from core_models
  final NutritionalSummary averageNutrition; // NutritionalSummary now from core_models
  final List<String> mostCommonFoods;

  const MealHistoryStatistics({
    required this.totalMeals,
    required this.mealTypeDistribution,
    required this.sourceDistribution,
    required this.averageNutrition,
    required this.mostCommonFoods,
  });

  factory MealHistoryStatistics.fromJson(Map<String, dynamic> json) {
    return MealHistoryStatistics(
      totalMeals: json['totalMeals'] as int,
      mealTypeDistribution: Map<String, int>.from(
        json['mealTypeDistribution'] as Map,
      ),
      sourceDistribution: (json['sourceDistribution'] as Map).map(
        (k, v) => MapEntry(
          MealSource.values.firstWhere(
            (e) => e.toString() == k,
            orElse: () => MealSource.manual, // MealSource now from core_models
          ),
          v as int,
        ),
      ),
      averageNutrition: NutritionalSummary.fromJson(
        json['averageNutrition'] as Map<String, dynamic>,
      ),
      mostCommonFoods: List<String>.from(json['mostCommonFoods'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalMeals': totalMeals,
      'mealTypeDistribution': mealTypeDistribution,
      'sourceDistribution': sourceDistribution.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'averageNutrition': (averageNutrition as dynamic).toJson(), // NutritionalSummary now from core_models
      'mostCommonFoods': mostCommonFoods,
    };
  }
}

/// Update payload for meal history editing
class MealHistoryUpdate {
  final String id;
  final DateTime? loggedAt;
  final String? mealType; // Should ideally use MealType enum from core_models
  final List<FoodItem>? foodItems; // FoodItem now from core_models
  final String? description;
  final String? notes;

  const MealHistoryUpdate({
    required this.id,
    this.loggedAt,
    this.mealType,
    this.foodItems,
    this.description,
    this.notes,
  });

  factory MealHistoryUpdate.fromJson(Map<String, dynamic> json) {
    return MealHistoryUpdate(
      id: json['id'] as String,
      loggedAt: json['loggedAt'] != null
          ? DateTime.parse(json['loggedAt'] as String)
          : null,
      mealType: json['mealType'] as String?,
      foodItems: json['foodItems'] != null
          ? (json['foodItems'] as List)
                .map((e) => FoodItem.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      description: json['description'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'loggedAt': loggedAt?.toIso8601String(),
      'mealType': mealType,
      'foodItems': foodItems?.map((e) => (e as dynamic).toJson()).toList(),
      'description': description,
      'notes': notes,
    };
  }
}

/// Time range for filtering meal history
class TimeRange {
  final DateTime startDate;
  final DateTime endDate;

  const TimeRange({required this.startDate, required this.endDate});

  factory TimeRange.fromJson(Map<String, dynamic> json) {
    return TimeRange(
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }

  /// Create a time range for the last 7 days
  factory TimeRange.lastWeek() {
    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final startDate = endDate.subtract(const Duration(days: 6));
    return TimeRange(
      startDate: DateTime(startDate.year, startDate.month, startDate.day),
      endDate: endDate,
    );
  }

  /// Create a time range for the last 30 days
  factory TimeRange.lastMonth() {
    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final startDate = endDate.subtract(const Duration(days: 29));
    return TimeRange(
      startDate: DateTime(startDate.year, startDate.month, startDate.day),
      endDate: endDate,
    );
  }

  /// Create a time range for the current week (Sunday to Saturday)
  factory TimeRange.currentWeek() {
    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final daysToSubtract = now.weekday % 7; // 0 = Sunday, 6 = Saturday
    final startDate = endDate.subtract(Duration(days: daysToSubtract));
    return TimeRange(
      startDate: DateTime(startDate.year, startDate.month, startDate.day),
      endDate: endDate.add(Duration(days: 6 - daysToSubtract)),
    );
  }
}
