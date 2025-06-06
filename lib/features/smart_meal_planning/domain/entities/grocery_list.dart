import 'package:freezed_annotation/freezed_annotation.dart';

part 'grocery_list.freezed.dart';
part 'grocery_list.g.dart';

/// Represents a grocery list generated from meal plans
@freezed
class GroceryList with _$GroceryList {
  const factory GroceryList({
    required String id,
    required String userId,
    required String name,
    required DateTime createdAt,
    DateTime? lastModifiedAt,
    required List<GroceryCategory> categories,
    @Default([])
    List<String>
    mealPlanIds, // IDs of meal plans this grocery list was generated from
    @Default(false) bool isCompleted,
    @Default(0) int completedItemsCount,
    @Default(GroceryListSource.mealPlan) GroceryListSource source,
    String? notes,
  }) = _GroceryList;

  factory GroceryList.fromJson(Map<String, dynamic> json) =>
      _$GroceryListFromJson(json);
}

/// Represents a category of grocery items (e.g., Produce, Dairy, etc.)
@freezed
class GroceryCategory with _$GroceryCategory {
  const factory GroceryCategory({
    required String id,
    required String name,
    required List<GroceryItem> items,
    String? emoji,
    @Default(0) int order, // Display order for categories
    @Default(false) bool isExpanded, // UI state for expandable sections
  }) = _GroceryCategory;

  factory GroceryCategory.fromJson(Map<String, dynamic> json) =>
      _$GroceryCategoryFromJson(json);
}

/// Represents an item in a grocery list
@freezed
class GroceryItem with _$GroceryItem {
  const factory GroceryItem({
    required String id,
    required String name,
    required double quantity,
    required String unit,
    @Default(false) bool isChecked,
    String? notes,
    @Default([]) List<String> mealIds, // IDs of meals this item is used in
    String? imageUrl,
    DateTime? addedAt,
    DateTime? checkedAt,
  }) = _GroceryItem;

  factory GroceryItem.fromJson(Map<String, dynamic> json) =>
      _$GroceryItemFromJson(json);
}

/// Source of a grocery list
enum GroceryListSource {
  mealPlan, // Generated from meal plan
  manual, // Created manually by the user
  template, // Created from a template
  previous, // Copied from a previous grocery list
}
