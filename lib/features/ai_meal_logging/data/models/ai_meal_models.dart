import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/ai_meal_recognition.dart';

/// Data model for ConfirmedMealItem for Firestore serialization
class ConfirmedMealItemModel {
  final String name;
  final String foodId;
  final double quantity;
  final String servingUnit;
  final NutritionalEstimateModel nutrition;
  final bool wasAIRecognized;
  final double? originalConfidence;

  ConfirmedMealItemModel({
    required this.name,
    required this.foodId,
    required this.quantity,
    required this.servingUnit,
    required this.nutrition,
    required this.wasAIRecognized,
    this.originalConfidence,
  });

  /// Convert entity to model
  factory ConfirmedMealItemModel.fromEntity(ConfirmedMealItem entity) {
    return ConfirmedMealItemModel(
      name: entity.name,
      foodId: entity.foodId,
      quantity: entity.quantity,
      servingUnit: entity.servingUnit,
      nutrition: NutritionalEstimateModel.fromEntity(entity.nutrition),
      wasAIRecognized: entity.wasAIRecognized,
      originalConfidence: entity.originalConfidence,
    );
  }

  /// Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'foodId': foodId,
      'quantity': quantity,
      'servingUnit': servingUnit,
      'nutrition': nutrition.toFirestore(),
      'wasAIRecognized': wasAIRecognized,
      'originalConfidence': originalConfidence,
    };
  }

  /// Create from Firestore data
  factory ConfirmedMealItemModel.fromFirestore(Map<String, dynamic> data) {
    return ConfirmedMealItemModel(
      name: data['name'] as String,
      foodId: data['foodId'] as String,
      quantity: (data['quantity'] is int)
          ? (data['quantity'] as int).toDouble()
          : data['quantity'] as double,
      servingUnit: data['servingUnit'] as String,
      nutrition: NutritionalEstimateModel.fromFirestore(
        data['nutrition'] as Map<String, dynamic>,
      ),
      wasAIRecognized: data['wasAIRecognized'] as bool,
      originalConfidence: data['originalConfidence'] != null
          ? (data['originalConfidence'] is int)
                ? (data['originalConfidence'] as int).toDouble()
                : data['originalConfidence'] as double
          : null,
    );
  }

  /// Convert to entity
  ConfirmedMealItem toEntity() {
    return ConfirmedMealItem(
      name: name,
      foodId: foodId,
      quantity: quantity,
      servingUnit: servingUnit,
      nutrition: nutrition.toEntity(),
      wasAIRecognized: wasAIRecognized,
      originalConfidence: originalConfidence,
    );
  }
}

/// Data model for NutritionalEstimate for Firestore serialization
class NutritionalEstimateModel {
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? fiber;
  final double? sugar;
  final double? sodium;

  NutritionalEstimateModel({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber,
    this.sugar,
    this.sodium,
  });

  /// Convert entity to model
  factory NutritionalEstimateModel.fromEntity(NutritionalEstimate entity) {
    return NutritionalEstimateModel(
      calories: entity.calories,
      protein: entity.protein,
      carbs: entity.carbs,
      fat: entity.fat,
      fiber: entity.fiber,
      sugar: entity.sugar,
      sodium: entity.sodium,
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
  factory NutritionalEstimateModel.fromFirestore(Map<String, dynamic> data) {
    return NutritionalEstimateModel(
      calories: data['calories'] as int,
      protein: (data['protein'] is int)
          ? (data['protein'] as int).toDouble()
          : data['protein'] as double,
      carbs: (data['carbs'] is int)
          ? (data['carbs'] as int).toDouble()
          : data['carbs'] as double,
      fat: (data['fat'] is int)
          ? (data['fat'] as int).toDouble()
          : data['fat'] as double,
      fiber: data['fiber'] != null
          ? (data['fiber'] is int)
                ? (data['fiber'] as int).toDouble()
                : data['fiber'] as double
          : null,
      sugar: data['sugar'] != null
          ? (data['sugar'] is int)
                ? (data['sugar'] as int).toDouble()
                : data['sugar'] as double
          : null,
      sodium: data['sodium'] != null
          ? (data['sodium'] is int)
                ? (data['sodium'] as int).toDouble()
                : data['sodium'] as double
          : null,
    );
  }

  /// Convert to entity
  NutritionalEstimate toEntity() {
    return NutritionalEstimate(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
      sugar: sugar,
      sodium: sodium,
    );
  }
}

/// Data model for AIMealLog for Firestore serialization
class AIMealLogModel {
  final String id;
  final List<ConfirmedMealItemModel> items;
  final DateTime loggedAt;
  final String imageId;
  final AIMealRecognitionResultModel originalAnalysis;
  final NutritionalEstimateModel totalNutrition;
  final String mealType;
  final String? notes;

  AIMealLogModel({
    required this.id,
    required this.items,
    required this.loggedAt,
    required this.imageId,
    required this.originalAnalysis,
    required this.totalNutrition,
    required this.mealType,
    this.notes,
  });

  /// Convert entity to model
  factory AIMealLogModel.fromEntity(AIMealLog entity) {
    return AIMealLogModel(
      id: entity.id,
      items: entity.items
          .map((item) => ConfirmedMealItemModel.fromEntity(item))
          .toList(),
      loggedAt: entity.loggedAt,
      imageId: entity.imageId,
      originalAnalysis: AIMealRecognitionResultModel.fromEntity(
        entity.originalAnalysis,
      ),
      totalNutrition: NutritionalEstimateModel.fromEntity(
        entity.totalNutrition,
      ),
      mealType: entity.mealType,
      notes: entity.notes,
    );
  }

  /// Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'items': items.map((item) => item.toFirestore()).toList(),
      'loggedAt': Timestamp.fromDate(loggedAt),
      'imageId': imageId,
      'originalAnalysis': originalAnalysis.toFirestore(),
      'totalNutrition': totalNutrition.toFirestore(),
      'mealType': mealType,
      'notes': notes,
    };
  }

  /// Create from Firestore data
  factory AIMealLogModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final id = doc.id;

    return AIMealLogModel(
      id: id,
      items: (data['items'] as List)
          .map(
            (item) => ConfirmedMealItemModel.fromFirestore(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
      loggedAt: (data['loggedAt'] as Timestamp).toDate(),
      imageId: data['imageId'] as String,
      originalAnalysis: AIMealRecognitionResultModel.fromFirestore(
        data['originalAnalysis'] as Map<String, dynamic>,
      ),
      totalNutrition: NutritionalEstimateModel.fromFirestore(
        data['totalNutrition'] as Map<String, dynamic>,
      ),
      mealType: data['mealType'] as String,
      notes: data['notes'] as String?,
    );
  }

  /// Convert to entity
  AIMealLog toEntity() {
    return AIMealLog(
      id: id,
      items: items.map((item) => item.toEntity()).toList(),
      loggedAt: loggedAt,
      imageId: imageId,
      originalAnalysis: originalAnalysis.toEntity(),
      totalNutrition: totalNutrition.toEntity(),
      mealType: mealType,
      notes: notes,
    );
  }
}

/// Data model for RecognizedFoodItem for Firestore serialization
class RecognizedFoodItemModel {
  final String name;
  final double confidence;
  final String estimatedServing;
  final NutritionalEstimateModel nutritionalEstimate;
  final String? foodId;
  final String? boundingBox;

  RecognizedFoodItemModel({
    required this.name,
    required this.confidence,
    required this.estimatedServing,
    required this.nutritionalEstimate,
    this.foodId,
    this.boundingBox,
  });

  /// Convert entity to model
  factory RecognizedFoodItemModel.fromEntity(RecognizedFoodItem entity) {
    return RecognizedFoodItemModel(
      name: entity.name,
      confidence: entity.confidence,
      estimatedServing: entity.estimatedServing,
      nutritionalEstimate: NutritionalEstimateModel.fromEntity(
        entity.nutritionalEstimate,
      ),
      foodId: entity.foodId,
      boundingBox: entity.boundingBox,
    );
  }

  /// Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'confidence': confidence,
      'estimatedServing': estimatedServing,
      'nutritionalEstimate': nutritionalEstimate.toFirestore(),
      'foodId': foodId,
      'boundingBox': boundingBox,
    };
  }

  /// Create from Firestore data
  factory RecognizedFoodItemModel.fromFirestore(Map<String, dynamic> data) {
    return RecognizedFoodItemModel(
      name: data['name'] as String,
      confidence: (data['confidence'] is int)
          ? (data['confidence'] as int).toDouble()
          : data['confidence'] as double,
      estimatedServing: data['estimatedServing'] as String,
      nutritionalEstimate: NutritionalEstimateModel.fromFirestore(
        data['nutritionalEstimate'] as Map<String, dynamic>,
      ),
      foodId: data['foodId'] as String?,
      boundingBox: data['boundingBox'] as String?,
    );
  }

  /// Convert to entity
  RecognizedFoodItem toEntity() {
    return RecognizedFoodItem(
      name: name,
      confidence: confidence,
      estimatedServing: estimatedServing,
      nutritionalEstimate: nutritionalEstimate.toEntity(),
      foodId: foodId,
      boundingBox: boundingBox,
    );
  }
}

/// Data model for AIMealRecognitionResult for Firestore serialization
class AIMealRecognitionResultModel {
  final List<RecognizedFoodItemModel> recognizedItems;
  final bool isSuccessful;
  final String? errorMessage;
  final double processingTime;
  final DateTime analyzedAt;
  final String? imageId;

  AIMealRecognitionResultModel({
    required this.recognizedItems,
    required this.isSuccessful,
    this.errorMessage,
    required this.processingTime,
    required this.analyzedAt,
    this.imageId,
  });

  /// Convert entity to model
  factory AIMealRecognitionResultModel.fromEntity(
    AIMealRecognitionResult entity,
  ) {
    return AIMealRecognitionResultModel(
      recognizedItems: entity.recognizedItems
          .map((item) => RecognizedFoodItemModel.fromEntity(item))
          .toList(),
      isSuccessful: entity.isSuccessful,
      errorMessage: entity.errorMessage,
      processingTime: entity.processingTime,
      analyzedAt: entity.analyzedAt,
      imageId: entity.imageId,
    );
  }

  /// Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'recognizedItems': recognizedItems
          .map((item) => item.toFirestore())
          .toList(),
      'isSuccessful': isSuccessful,
      'errorMessage': errorMessage,
      'processingTime': processingTime,
      'analyzedAt': Timestamp.fromDate(analyzedAt),
      'imageId': imageId,
    };
  }

  /// Create from Firestore data
  factory AIMealRecognitionResultModel.fromFirestore(
    Map<String, dynamic> data,
  ) {
    return AIMealRecognitionResultModel(
      recognizedItems: (data['recognizedItems'] as List)
          .map(
            (item) => RecognizedFoodItemModel.fromFirestore(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
      isSuccessful: data['isSuccessful'] as bool,
      errorMessage: data['errorMessage'] as String?,
      processingTime: (data['processingTime'] is int)
          ? (data['processingTime'] as int).toDouble()
          : data['processingTime'] as double,
      analyzedAt: (data['analyzedAt'] as Timestamp).toDate(),
      imageId: data['imageId'] as String?,
    );
  }

  /// Convert to entity
  AIMealRecognitionResult toEntity() {
    return AIMealRecognitionResult(
      recognizedItems: recognizedItems.map((item) => item.toEntity()).toList(),
      isSuccessful: isSuccessful,
      errorMessage: errorMessage,
      processingTime: processingTime,
      analyzedAt: analyzedAt,
      imageId: imageId,
    );
  }
}
