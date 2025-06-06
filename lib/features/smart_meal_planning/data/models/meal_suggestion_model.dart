import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/models/meal_models.dart';
import '../../domain/entities/meal_suggestion.dart';

part 'meal_suggestion_model.freezed.dart';
part 'meal_suggestion_model.g.dart';

/// Data model for MealSuggestion with JSON serialization for Firestore
@freezed
class MealSuggestionModel with _$MealSuggestionModel {
  const MealSuggestionModel._();

  const factory MealSuggestionModel({
    required String id,
    required String name,
    required String mealType,
    required List<SuggestedFoodItemModel> items,
    required NutritionalSummary estimatedNutrition,
    required SuggestionSource source,
    String? createdAt, // ISO date string
    String? imageUrl,
    String? description,
    double? preparationTimeMinutes,
    @Default({}) Map<String, dynamic> attributes,
    @Default(false) bool isFavorite,
    double? userRating,
  }) = _MealSuggestionModel;

  /// Create model from JSON map
  factory MealSuggestionModel.fromJson(Map<String, dynamic> json) =>
      _$MealSuggestionModelFromJson(json);

  /// Convert from Firestore DocumentSnapshot
  factory MealSuggestionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return MealSuggestionModel(
      id: doc.id,
      name: data['name'] as String,
      mealType: data['mealType'] as String,
      items: (data['items'] as List<dynamic>)
          .map(
            (item) =>
                SuggestedFoodItemModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      estimatedNutrition: NutritionalSummary.fromJson(
        data['estimatedNutrition'] as Map<String, dynamic>,
      ),
      source: SuggestionSource.values.firstWhere(
        (s) => s.toString() == 'SuggestionSource.${data['source'] ?? 'ai'}',
        orElse: () => SuggestionSource.ai,
      ),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate().toIso8601String()
          : null,
      imageUrl: data['imageUrl'] as String?,
      description: data['description'] as String?,
      preparationTimeMinutes: (data['preparationTimeMinutes'] as num?)
          ?.toDouble(),
      attributes: data['attributes'] as Map<String, dynamic>? ?? {},
      isFavorite: data['isFavorite'] as bool? ?? false,
      userRating: (data['userRating'] as num?)?.toDouble(),
    );
  }

  /// Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'mealType': mealType,
      'items': items.map((item) => item.toJson()).toList(),
      'estimatedNutrition': estimatedNutrition.toJson(),
      'source': source.toString().split('.').last,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(DateTime.parse(createdAt!))
          : Timestamp.now(),
      'imageUrl': imageUrl,
      'description': description,
      'preparationTimeMinutes': preparationTimeMinutes,
      'attributes': attributes,
      'isFavorite': isFavorite,
      'userRating': userRating,
    };
  }

  /// Convert to domain entity
  MealSuggestion toDomain() {
    return MealSuggestion(
      id: id,
      name: name,
      mealType: mealType,
      items: items.map((item) => item.toDomain()).toList(),
      estimatedNutrition: estimatedNutrition,
      source: source,
      createdAt: createdAt != null ? DateTime.parse(createdAt!) : null,
      imageUrl: imageUrl,
      description: description,
      preparationTimeMinutes: preparationTimeMinutes,
      attributes: attributes,
      isFavorite: isFavorite,
      userRating: userRating,
    );
  }
}

/// Data model for SuggestedFoodItem with JSON serialization
@freezed
class SuggestedFoodItemModel with _$SuggestedFoodItemModel {
  const SuggestedFoodItemModel._();

  const factory SuggestedFoodItemModel({
    required String id,
    required String name,
    required double quantity,
    required String unit,
    @Default({}) Map<String, double> nutritionalValues,
    String? alternativeFor,
    @Default([]) List<String> alternatives,
    String? imageUrl,
    String? notes,
    @Default({}) Map<String, dynamic> metadata,
  }) = _SuggestedFoodItemModel;

  /// Create model from JSON map
  factory SuggestedFoodItemModel.fromJson(Map<String, dynamic> json) =>
      _$SuggestedFoodItemModelFromJson(json);

  /// Convert to domain entity
  SuggestedFoodItem toDomain() {
    return SuggestedFoodItem(
      id: id,
      name: name,
      quantity: quantity,
      unit: unit,
      nutritionalValues: nutritionalValues,
      alternativeFor: alternativeFor,
      alternatives: alternatives,
      imageUrl: imageUrl,
      notes: notes,
      metadata: metadata,
    );
  }
}
