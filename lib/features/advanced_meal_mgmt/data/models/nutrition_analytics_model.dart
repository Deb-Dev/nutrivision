import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/nutrition_goals.dart';

/// Model for Firestore serialization of NutritionReport
class NutritionReportModel {
  final String userId;
  final DateTime startDate;
  final DateTime endDate;
  final AnalyticsPeriod period;
  final List<DailyNutritionModel> dailyNutrition;
  final AverageNutritionModel averageNutrition;
  final Map<String, int> mealTypeDistribution;
  final List<String> topFoods;

  NutritionReportModel({
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.period,
    required this.dailyNutrition,
    required this.averageNutrition,
    required this.mealTypeDistribution,
    required this.topFoods,
  });

  /// Create from entity
  factory NutritionReportModel.fromEntity(NutritionReport entity) {
    return NutritionReportModel(
      userId: entity.userId,
      startDate: entity.startDate,
      endDate: entity.endDate,
      period: entity.period,
      dailyNutrition: entity.dailyNutrition
          .map((item) => DailyNutritionModel.fromEntity(item))
          .toList(),
      averageNutrition: AverageNutritionModel.fromEntity(
        entity.averageNutrition,
      ),
      mealTypeDistribution: entity.mealTypeDistribution,
      topFoods: entity.topFoods,
    );
  }

  /// Convert to entity
  NutritionReport toEntity() {
    return NutritionReport(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
      period: period,
      dailyNutrition: dailyNutrition.map((item) => item.toEntity()).toList(),
      averageNutrition: averageNutrition.toEntity(),
      mealTypeDistribution: mealTypeDistribution,
      topFoods: topFoods,
    );
  }

  /// Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'period': period.toString().split('.').last,
      'dailyNutrition': dailyNutrition
          .map((item) => item.toFirestore())
          .toList(),
      'averageNutrition': averageNutrition.toFirestore(),
      'mealTypeDistribution': mealTypeDistribution,
      'topFoods': topFoods,
    };
  }

  /// Create from Firestore document
  factory NutritionReportModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    // Parse period
    AnalyticsPeriod period;
    try {
      period = AnalyticsPeriod.values.firstWhere(
        (e) => e.toString().split('.').last == data['period'],
        orElse: () => AnalyticsPeriod.daily,
      );
    } catch (_) {
      period = AnalyticsPeriod.daily;
    }

    // Parse daily nutrition
    List<DailyNutritionModel> dailyNutrition = [];
    if (data['dailyNutrition'] != null) {
      dailyNutrition = (data['dailyNutrition'] as List)
          .map(
            (item) =>
                DailyNutritionModel.fromFirestore(item as Map<String, dynamic>),
          )
          .toList();
    }

    return NutritionReportModel(
      userId: data['userId'] ?? '',
      startDate: data['startDate'] != null
          ? (data['startDate'] as Timestamp).toDate()
          : DateTime.now().subtract(const Duration(days: 7)),
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : DateTime.now(),
      period: period,
      dailyNutrition: dailyNutrition,
      averageNutrition: data['averageNutrition'] != null
          ? AverageNutritionModel.fromFirestore(
              data['averageNutrition'] as Map<String, dynamic>,
            )
          : AverageNutritionModel(calories: 0, protein: 0, carbs: 0, fat: 0),
      mealTypeDistribution: data['mealTypeDistribution'] != null
          ? Map<String, int>.from(data['mealTypeDistribution'] as Map)
          : {},
      topFoods: data['topFoods'] != null
          ? List<String>.from(data['topFoods'] as List)
          : [],
    );
  }
}

/// Model for Firestore serialization of DailyNutrition
class DailyNutritionModel {
  final DateTime date;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final int? mealCount;

  DailyNutritionModel({
    required this.date,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.mealCount,
  });

  /// Create from entity
  factory DailyNutritionModel.fromEntity(DailyNutrition entity) {
    return DailyNutritionModel(
      date: entity.date,
      calories: entity.calories,
      protein: entity.protein,
      carbs: entity.carbs,
      fat: entity.fat,
      mealCount: entity.mealCount,
    );
  }

  /// Convert to entity
  DailyNutrition toEntity() {
    return DailyNutrition(
      date: date,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      mealCount: mealCount,
    );
  }

  /// Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(date),
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'mealCount': mealCount,
    };
  }

  /// Create from Firestore data
  factory DailyNutritionModel.fromFirestore(Map<String, dynamic> data) {
    DateTime date;
    if (data['date'] is Timestamp) {
      date = (data['date'] as Timestamp).toDate();
    } else if (data['date'] is String) {
      date = DateTime.parse(data['date'] as String);
    } else {
      date = DateTime.now();
    }

    return DailyNutritionModel(
      date: date,
      calories: data['calories'] ?? 0,
      protein: (data['protein'] is int)
          ? (data['protein'] as int).toDouble()
          : data['protein'] ?? 0.0,
      carbs: (data['carbs'] is int)
          ? (data['carbs'] as int).toDouble()
          : data['carbs'] ?? 0.0,
      fat: (data['fat'] is int)
          ? (data['fat'] as int).toDouble()
          : data['fat'] ?? 0.0,
      mealCount: data['mealCount'],
    );
  }
}

/// Model for Firestore serialization of AverageNutrition
class AverageNutritionModel {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? calorieGoalProgress;
  final double? proteinGoalProgress;
  final double? carbsGoalProgress;
  final double? fatGoalProgress;

  AverageNutritionModel({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.calorieGoalProgress,
    this.proteinGoalProgress,
    this.carbsGoalProgress,
    this.fatGoalProgress,
  });

  /// Create from entity
  factory AverageNutritionModel.fromEntity(AverageNutrition entity) {
    return AverageNutritionModel(
      calories: entity.calories,
      protein: entity.protein,
      carbs: entity.carbs,
      fat: entity.fat,
      calorieGoalProgress: entity.calorieGoalProgress,
      proteinGoalProgress: entity.proteinGoalProgress,
      carbsGoalProgress: entity.carbsGoalProgress,
      fatGoalProgress: entity.fatGoalProgress,
    );
  }

  /// Convert to entity
  AverageNutrition toEntity() {
    return AverageNutrition(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      calorieGoalProgress: calorieGoalProgress,
      proteinGoalProgress: proteinGoalProgress,
      carbsGoalProgress: carbsGoalProgress,
      fatGoalProgress: fatGoalProgress,
    );
  }

  /// Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'calorieGoalProgress': calorieGoalProgress,
      'proteinGoalProgress': proteinGoalProgress,
      'carbsGoalProgress': carbsGoalProgress,
      'fatGoalProgress': fatGoalProgress,
    };
  }

  /// Create from Firestore data
  factory AverageNutritionModel.fromFirestore(Map<String, dynamic> data) {
    return AverageNutritionModel(
      calories: (data['calories'] is int)
          ? (data['calories'] as int).toDouble()
          : data['calories'] ?? 0.0,
      protein: (data['protein'] is int)
          ? (data['protein'] as int).toDouble()
          : data['protein'] ?? 0.0,
      carbs: (data['carbs'] is int)
          ? (data['carbs'] as int).toDouble()
          : data['carbs'] ?? 0.0,
      fat: (data['fat'] is int)
          ? (data['fat'] as int).toDouble()
          : data['fat'] ?? 0.0,
      calorieGoalProgress: (data['calorieGoalProgress'] is int)
          ? (data['calorieGoalProgress'] as int).toDouble()
          : data['calorieGoalProgress'],
      proteinGoalProgress: (data['proteinGoalProgress'] is int)
          ? (data['proteinGoalProgress'] as int).toDouble()
          : data['proteinGoalProgress'],
      carbsGoalProgress: (data['carbsGoalProgress'] is int)
          ? (data['carbsGoalProgress'] as int).toDouble()
          : data['carbsGoalProgress'],
      fatGoalProgress: (data['fatGoalProgress'] is int)
          ? (data['fatGoalProgress'] as int).toDouble()
          : data['fatGoalProgress'],
    );
  }
}

/// Model for TopFood
class TopFoodModel {
  final String foodName;
  final int count;
  final double totalCalories;

  const TopFoodModel({
    required this.foodName,
    required this.count,
    required this.totalCalories,
  });

  /// Create from entity
  factory TopFoodModel.fromEntity(TopFood entity) {
    return TopFoodModel(
      foodName: entity.name,
      count: entity.frequency,
      totalCalories: entity.totalCalories,
    );
  }

  /// Convert to entity
  TopFood toEntity() {
    return TopFood(
      name: foodName,
      frequency: count,
      totalCalories: totalCalories,
      avgCalories: totalCalories / count.clamp(1, double.infinity),
    );
  }

  /// Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'foodName': foodName,
      'count': count,
      'totalCalories': totalCalories,
    };
  }

  /// Create from Firestore data
  factory TopFoodModel.fromFirestore(Map<String, dynamic> data) {
    return TopFoodModel(
      foodName: data['foodName'] ?? 'Unknown Food',
      count: data['count'] ?? 0,
      totalCalories: (data['totalCalories'] is int)
          ? (data['totalCalories'] as int).toDouble()
          : data['totalCalories'] ?? 0.0,
    );
  }
}
