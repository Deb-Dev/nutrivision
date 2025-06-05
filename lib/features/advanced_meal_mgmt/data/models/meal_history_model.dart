import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/meal_models.dart';

/// Model for Firestore serialization of MealHistoryEntry
class MealHistoryEntryModel {
  final String id;
  final String userId;
  final DateTime loggedAt;
  final String mealType;
  final MealSource source;
  final List<FoodItemModel> foodItems;
  final NutritionalSummaryModel nutrition;
  final String? description;
  final String? notes;
  final String? imageId;
  final DateTime? editedAt;
  final int editCount;

  MealHistoryEntryModel({
    required this.id,
    required this.userId,
    required this.loggedAt,
    required this.mealType,
    required this.source,
    required this.foodItems,
    required this.nutrition,
    this.description,
    this.notes,
    this.imageId,
    this.editedAt,
    this.editCount = 0,
  });

  /// Create from entity
  factory MealHistoryEntryModel.fromEntity(MealHistoryEntry entity) {
    return MealHistoryEntryModel(
      id: entity.id,
      userId: entity.userId,
      loggedAt: entity.loggedAt,
      mealType: entity.mealType,
      source: entity.source,
      foodItems: entity.foodItems
          .map((item) => FoodItemModel.fromEntity(item))
          .toList(),
      nutrition: NutritionalSummaryModel.fromEntity(entity.nutrition),
      description: entity.description,
      notes: entity.notes,
      imageId: entity.imageId,
      editedAt: entity.editedAt,
      editCount: entity.editCount,
    );
  }

  /// Convert to entity
  MealHistoryEntry toEntity() {
    return MealHistoryEntry(
      id: id,
      userId: userId,
      loggedAt: loggedAt,
      mealType: mealType,
      source: source,
      foodItems: foodItems.map((item) => item.toEntity()).toList(),
      nutrition: nutrition.toEntity(),
      description: description,
      notes: notes,
      imageId: imageId,
      editedAt: editedAt,
      editCount: editCount,
    );
  }

  /// Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'loggedAt': Timestamp.fromDate(loggedAt),
      'mealType': mealType,
      'source': source.toString().split('.').last,
      'foodItems': foodItems.map((item) => item.toFirestore()).toList(),
      'calories': nutrition.calories,
      'protein': nutrition.protein,
      'carbs': nutrition.carbs,
      'fat': nutrition.fat,
      'fiber': nutrition.fiber,
      'sugar': nutrition.sugar,
      'sodium': nutrition.sodium,
      'description': description,
      'notes': notes,
      'imageId': imageId,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'editCount': editCount,
    };
  }

  /// Create from Firestore document
  factory MealHistoryEntryModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    // Handle food items
    List<FoodItemModel> foodItems = [];
    if (data['foodItems'] != null) {
      foodItems = (data['foodItems'] as List)
          .map((item) => FoodItemModel.fromFirestore(item))
          .toList();
    }

    // Handle source enum
    MealSource source = MealSource.manual;
    if (data['source'] != null) {
      source = data['source'] == 'aiAssisted'
          ? MealSource.aiAssisted
          : MealSource.manual;
    }

    return MealHistoryEntryModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      loggedAt: (data['loggedAt'] as Timestamp).toDate(),
      mealType: data['mealType'] ?? 'meal',
      source: source,
      foodItems: foodItems,
      nutrition: NutritionalSummaryModel(
        calories: data['calories'] ?? 0,
        protein: data['protein'] ?? 0.0,
        carbs: data['carbs'] ?? 0.0,
        fat: data['fat'] ?? 0.0,
        fiber: data['fiber'],
        sugar: data['sugar'],
        sodium: data['sodium'],
      ),
      description: data['description'],
      notes: data['notes'],
      imageId: data['imageId'],
      editedAt: data['editedAt'] != null
          ? (data['editedAt'] as Timestamp).toDate()
          : null,
      editCount: data['editCount'] ?? 0,
    );
  }
}

/// Model for Firestore serialization of FoodItem
class FoodItemModel {
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

  FoodItemModel({
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
  factory FoodItemModel.fromEntity(FoodItem entity) {
    return FoodItemModel(
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
  FoodItem toEntity() {
    return FoodItem(
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
  factory FoodItemModel.fromFirestore(Map<String, dynamic> data) {
    return FoodItemModel(
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
}
