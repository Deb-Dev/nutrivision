import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/nutrition_goals.dart';

/// Model for Firestore serialization of NutritionalGoal
class NutritionalGoalModel {
  final String id;
  final String userId;
  final String name;
  final GoalType type;
  final double targetValue;
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;
  final DateTime? lastUpdated;
  final double? currentProgress;
  final bool isCompleted;

  NutritionalGoalModel({
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

  /// Create from entity
  factory NutritionalGoalModel.fromEntity(NutritionalGoal entity) {
    return NutritionalGoalModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      type: entity.type,
      targetValue: entity.targetValue,
      startDate: entity.startDate,
      endDate: entity.endDate,
      notes: entity.notes,
      lastUpdated: entity.lastUpdated,
      currentProgress: entity.currentProgress,
      isCompleted: entity.isCompleted,
    );
  }

  /// Convert to entity
  NutritionalGoal toEntity() {
    return NutritionalGoal(
      id: id,
      userId: userId,
      name: name,
      type: type,
      targetValue: targetValue,
      startDate: startDate,
      endDate: endDate,
      notes: notes,
      lastUpdated: lastUpdated,
      currentProgress: currentProgress,
      isCompleted: isCompleted,
    );
  }

  /// Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'type': type.toString().split('.').last,
      'targetValue': targetValue,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'notes': notes,
      'lastUpdated': lastUpdated != null
          ? Timestamp.fromDate(lastUpdated!)
          : null,
      'currentProgress': currentProgress,
      'isCompleted': isCompleted,
    };
  }

  /// Create from Firestore document
  factory NutritionalGoalModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    // Parse goal type
    GoalType goalType;
    try {
      goalType = GoalType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => GoalType.dailyCalories,
      );
    } catch (_) {
      goalType = GoalType.dailyCalories;
    }

    return NutritionalGoalModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? 'Unnamed Goal',
      type: goalType,
      targetValue: (data['targetValue'] is int)
          ? (data['targetValue'] as int).toDouble()
          : data['targetValue'] ?? 0.0,
      startDate: data['startDate'] != null
          ? (data['startDate'] as Timestamp).toDate()
          : DateTime.now(),
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      notes: data['notes'],
      lastUpdated: data['lastUpdated'] != null
          ? (data['lastUpdated'] as Timestamp).toDate()
          : null,
      currentProgress: (data['currentProgress'] is int)
          ? (data['currentProgress'] as int).toDouble()
          : data['currentProgress'],
      isCompleted: data['isCompleted'] ?? false,
    );
  }
}

/// Model for Firestore serialization of FavoriteMeal
class FavoriteMealModel {
  final String id;
  final String userId;
  final String name;
  final List<FavoriteFoodItemModel> foodItems;
  final NutritionalSummaryModel nutrition;
  final String mealType;
  final String? imageUrl;
  final String? notes;
  final DateTime createdAt;
  final DateTime? lastUsed;
  final int useCount;

  FavoriteMealModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.foodItems,
    required this.nutrition,
    required this.mealType,
    this.imageUrl,
    this.notes,
    required this.createdAt,
    this.lastUsed,
    this.useCount = 0,
  });

  /// Create from entity
  factory FavoriteMealModel.fromEntity(FavoriteMeal entity) {
    return FavoriteMealModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      foodItems: entity.foodItems
          .map((item) => FavoriteFoodItemModel.fromEntity(item))
          .toList(),
      nutrition: NutritionalSummaryModel.fromEntity(entity.nutrition),
      mealType: entity.mealType,
      imageUrl: entity.imageUrl,
      notes: entity.notes,
      createdAt: entity.createdAt,
      lastUsed: entity.lastUsed,
      useCount: entity.useCount,
    );
  }

  /// Convert to entity
  FavoriteMeal toEntity() {
    return FavoriteMeal(
      id: id,
      userId: userId,
      name: name,
      foodItems: foodItems.map((item) => item.toEntity()).toList(),
      nutrition: nutrition.toEntity(),
      mealType: mealType,
      imageUrl: imageUrl,
      notes: notes,
      createdAt: createdAt,
      lastUsed: lastUsed,
      useCount: useCount,
    );
  }

  /// Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'foodItems': foodItems.map((item) => item.toFirestore()).toList(),
      'nutrition': nutrition.toFirestore(),
      'mealType': mealType,
      'imageUrl': imageUrl,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUsed': lastUsed != null ? Timestamp.fromDate(lastUsed!) : null,
      'useCount': useCount,
    };
  }

  /// Create from Firestore document
  factory FavoriteMealModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    // Parse food items
    List<FavoriteFoodItemModel> foodItems = [];
    if (data['foodItems'] != null) {
      foodItems = (data['foodItems'] as List)
          .map((item) => FavoriteFoodItemModel.fromFirestore(item))
          .toList();
    }

    return FavoriteMealModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? 'Unnamed Meal',
      foodItems: foodItems,
      nutrition: data['nutrition'] != null
          ? NutritionalSummaryModel.fromFirestore(data['nutrition'])
          : NutritionalSummaryModel(
              calories: 0,
              protein: 0.0,
              carbs: 0.0,
              fat: 0.0,
            ),
      mealType: data['mealType'] ?? 'meal',
      imageUrl: data['imageUrl'],
      notes: data['notes'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastUsed: data['lastUsed'] != null
          ? (data['lastUsed'] as Timestamp).toDate()
          : null,
      useCount: data['useCount'] ?? 0,
    );
  }
}

/// Model for Firestore serialization of FavoriteFoodItem
class FavoriteFoodItemModel {
  final String name;
  final double quantity;
  final String unit;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? fiber;
  final double? sugar;
  final double? sodium;
  final String? foodId;

  FavoriteFoodItemModel({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber,
    this.sugar,
    this.sodium,
    this.foodId,
  });

  /// Create from entity
  factory FavoriteFoodItemModel.fromEntity(FavoriteFoodItem entity) {
    return FavoriteFoodItemModel(
      name: entity.name,
      quantity: entity.quantity,
      unit: entity.unit,
      calories: entity.calories,
      protein: entity.protein,
      carbs: entity.carbs,
      fat: entity.fat,
      fiber: entity.fiber,
      sugar: entity.sugar,
      sodium: entity.sodium,
      foodId: entity.foodId,
    );
  }

  /// Convert to entity
  FavoriteFoodItem toEntity() {
    return FavoriteFoodItem(
      name: name,
      quantity: quantity,
      unit: unit,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
      sugar: sugar,
      sodium: sodium,
      foodId: foodId,
    );
  }

  /// Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
      'foodId': foodId,
    };
  }

  /// Create from Firestore data
  factory FavoriteFoodItemModel.fromFirestore(Map<String, dynamic> data) {
    return FavoriteFoodItemModel(
      name: data['name'] ?? 'Unknown Food',
      quantity: (data['quantity'] is int)
          ? (data['quantity'] as int).toDouble()
          : data['quantity'] ?? 0.0,
      unit: data['unit'] ?? 'serving',
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
      fiber: (data['fiber'] is int)
          ? (data['fiber'] as int).toDouble()
          : data['fiber'],
      sugar: (data['sugar'] is int)
          ? (data['sugar'] as int).toDouble()
          : data['sugar'],
      sodium: (data['sodium'] is int)
          ? (data['sodium'] as int).toDouble()
          : data['sodium'],
      foodId: data['foodId'],
    );
  }
}

/// Model for Firestore serialization of NutritionalSummary
class NutritionalSummaryModel {
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? fiber;
  final double? sugar;
  final double? sodium;

  NutritionalSummaryModel({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber,
    this.sugar,
    this.sodium,
  });

  /// Create from entity
  factory NutritionalSummaryModel.fromEntity(NutritionalSummary entity) {
    return NutritionalSummaryModel(
      calories: entity.calories,
      protein: entity.protein,
      carbs: entity.carbs,
      fat: entity.fat,
      fiber: entity.fiber,
      sugar: entity.sugar,
      sodium: entity.sodium,
    );
  }

  /// Convert to entity
  NutritionalSummary toEntity() {
    return NutritionalSummary(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
      sugar: sugar,
      sodium: sodium,
    );
  }

  /// Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
    };
  }

  /// Create from Firestore data
  factory NutritionalSummaryModel.fromFirestore(Map<String, dynamic> data) {
    return NutritionalSummaryModel(
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
      fiber: (data['fiber'] is int)
          ? (data['fiber'] as int).toDouble()
          : data['fiber'],
      sugar: (data['sugar'] is int)
          ? (data['sugar'] as int).toDouble()
          : data['sugar'],
      sodium: (data['sodium'] is int)
          ? (data['sodium'] as int).toDouble()
          : data['sodium'],
    );
  }
}
