import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/grocery_list.dart';

part 'grocery_list_model.freezed.dart';
part 'grocery_list_model.g.dart';

/// Data model for GroceryList with JSON serialization for Firestore
@freezed
class GroceryListModel with _$GroceryListModel {
  const GroceryListModel._();

  const factory GroceryListModel({
    required String id,
    required String userId,
    required String name,
    required String createdAt, // ISO date string
    String? lastModifiedAt, // ISO date string
    required List<GroceryCategoryModel> categories,
    @Default([]) List<String> mealPlanIds,
    @Default(false) bool isCompleted,
    @Default(0) int completedItemsCount,
    @Default(GroceryListSource.mealPlan) GroceryListSource source,
    String? notes,
  }) = _GroceryListModel;

  /// Create model from JSON map
  factory GroceryListModel.fromJson(Map<String, dynamic> json) =>
      _$GroceryListModelFromJson(json);

  /// Convert from Firestore DocumentSnapshot
  factory GroceryListModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return GroceryListModel(
      id: doc.id,
      userId: data['userId'] as String,
      name: data['name'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate().toIso8601String(),
      lastModifiedAt: data['lastModifiedAt'] != null
          ? (data['lastModifiedAt'] as Timestamp).toDate().toIso8601String()
          : null,
      categories: (data['categories'] as List<dynamic>)
          .map(
            (category) =>
                GroceryCategoryModel.fromJson(category as Map<String, dynamic>),
          )
          .toList(),
      mealPlanIds:
          (data['mealPlanIds'] as List<dynamic>?)
              ?.map((id) => id as String)
              .toList() ??
          [],
      isCompleted: data['isCompleted'] as bool? ?? false,
      completedItemsCount: (data['completedItemsCount'] as int?) ?? 0,
      source: GroceryListSource.values.firstWhere(
        (s) =>
            s.toString() == 'GroceryListSource.${data['source'] ?? 'mealPlan'}',
        orElse: () => GroceryListSource.mealPlan,
      ),
      notes: data['notes'] as String?,
    );
  }

  /// Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'createdAt': Timestamp.fromDate(DateTime.parse(createdAt)),
      'lastModifiedAt': lastModifiedAt != null
          ? Timestamp.fromDate(DateTime.parse(lastModifiedAt!))
          : null,
      'categories': categories.map((category) => category.toJson()).toList(),
      'mealPlanIds': mealPlanIds,
      'isCompleted': isCompleted,
      'completedItemsCount': completedItemsCount,
      'source': source.toString().split('.').last,
      'notes': notes,
    };
  }

  /// Convert to domain entity
  GroceryList toDomain() {
    return GroceryList(
      id: id,
      userId: userId,
      name: name,
      createdAt: DateTime.parse(createdAt),
      lastModifiedAt: lastModifiedAt != null
          ? DateTime.parse(lastModifiedAt!)
          : null,
      categories: categories.map((category) => category.toDomain()).toList(),
      mealPlanIds: mealPlanIds,
      isCompleted: isCompleted,
      completedItemsCount: completedItemsCount,
      source: source,
      notes: notes,
    );
  }
}

/// Data model for GroceryCategory with JSON serialization
@freezed
class GroceryCategoryModel with _$GroceryCategoryModel {
  const GroceryCategoryModel._();

  const factory GroceryCategoryModel({
    required String id,
    required String name,
    required List<GroceryItemModel> items,
    String? emoji,
    @Default(false) bool isExpanded,
    @Default(0) int order,
  }) = _GroceryCategoryModel;

  /// Create model from JSON map
  factory GroceryCategoryModel.fromJson(Map<String, dynamic> json) =>
      _$GroceryCategoryModelFromJson(json);

  /// Convert to domain entity
  GroceryCategory toDomain() {
    return GroceryCategory(
      id: id,
      name: name,
      items: items.map((item) => item.toDomain()).toList(),
      emoji: emoji,
      isExpanded: isExpanded,
      order: order,
    );
  }
}

/// Data model for GroceryItem with JSON serialization
@freezed
class GroceryItemModel with _$GroceryItemModel {
  const GroceryItemModel._();

  const factory GroceryItemModel({
    required String id,
    required String name,
    required double quantity,
    required String unit,
    @Default(false) bool isChecked,
    String? notes,
    @Default([]) List<String> mealIds,
    String? imageUrl,
    String? addedAt, // ISO date string
    String? checkedAt, // ISO date string
  }) = _GroceryItemModel;

  /// Create model from JSON map
  factory GroceryItemModel.fromJson(Map<String, dynamic> json) =>
      _$GroceryItemModelFromJson(json);

  /// Convert to domain entity
  GroceryItem toDomain() {
    return GroceryItem(
      id: id,
      name: name,
      quantity: quantity,
      unit: unit,
      isChecked: isChecked,
      notes: notes,
      mealIds: mealIds,
      imageUrl: imageUrl,
      addedAt: addedAt != null ? DateTime.parse(addedAt!) : null,
      checkedAt: checkedAt != null ? DateTime.parse(checkedAt!) : null,
    );
  }
}
