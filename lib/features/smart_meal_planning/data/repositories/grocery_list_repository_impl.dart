import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/base_repository.dart';
import '../../domain/entities/grocery_list.dart';
import '../../domain/entities/meal_plan.dart';
import '../../domain/repositories/grocery_list_repository.dart';
import '../models/grocery_list_model.dart';

/// Implementation of the grocery list repository
@Injectable(as: GroceryListRepository)
class GroceryListRepositoryImpl extends BaseRepository
    implements GroceryListRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid = const Uuid();

  // Collection reference
  late final CollectionReference<Map<String, dynamic>> _groceryListsCollection;

  GroceryListRepositoryImpl(this._firestore) {
    _groceryListsCollection = _firestore.collection('groceryLists');
  }

  @override
  Future<Either<Failure, GroceryList>> getGroceryListById(String id) async {
    return safeCall(() async {
      final docSnapshot = await _groceryListsCollection.doc(id).get();

      if (!docSnapshot.exists) {
        throw Failure.validationFailure(message: 'Grocery list not found');
      }

      final groceryList = GroceryListModel.fromFirestore(
        docSnapshot,
      ).toDomain();
      return groceryList;
    });
  }

  @override
  Future<Either<Failure, List<GroceryList>>> getUserGroceryLists(
    String userId,
  ) async {
    return safeCall(() async {
      final querySnapshot = await _groceryListsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final groceryLists = querySnapshot.docs
          .map((doc) => GroceryListModel.fromFirestore(doc).toDomain())
          .toList();

      return groceryLists;
    });
  }

  @override
  Future<Either<Failure, GroceryList>> createGroceryList(
    GroceryList groceryList,
  ) async {
    return safeCall(() async {
      // Generate ID if not provided
      final id = groceryList.id.isEmpty ? _uuid.v4() : groceryList.id;

      // Create a new grocery list with the ID
      final newGroceryList = groceryList.copyWith(id: id);

      // Convert to model and then to Firestore data
      final groceryListModel = GroceryListModel(
        id: newGroceryList.id,
        userId: newGroceryList.userId,
        name: newGroceryList.name,
        createdAt: newGroceryList.createdAt.toIso8601String(),
        lastModifiedAt: newGroceryList.lastModifiedAt?.toIso8601String(),
        categories: newGroceryList.categories
            .map(
              (category) => GroceryCategoryModel(
                id: category.id,
                name: category.name,
                items: category.items
                    .map(
                      (item) => GroceryItemModel(
                        id: item.id,
                        name: item.name,
                        quantity: item.quantity,
                        unit: item.unit,
                        isChecked: item.isChecked,
                        notes: item.notes,
                      ),
                    )
                    .toList(),
                order: category.order,
              ),
            )
            .toList(),
        mealPlanIds: newGroceryList.mealPlanIds,
        isCompleted: newGroceryList.isCompleted,
        completedItemsCount: newGroceryList.completedItemsCount,
        source: newGroceryList.source,
        notes: newGroceryList.notes,
      );

      // Save to Firestore
      await _groceryListsCollection.doc(id).set(groceryListModel.toFirestore());

      // Get the updated document
      final docSnapshot = await _groceryListsCollection.doc(id).get();

      return GroceryListModel.fromFirestore(docSnapshot).toDomain();
    });
  }

  @override
  Future<Either<Failure, GroceryList>> updateGroceryList(
    GroceryList groceryList,
  ) async {
    return safeCall(() async {
      // Convert to model
      final groceryListModel = GroceryListModel(
        id: groceryList.id,
        userId: groceryList.userId,
        name: groceryList.name,
        createdAt: groceryList.createdAt.toIso8601String(),
        lastModifiedAt: DateTime.now().toIso8601String(),
        categories: groceryList.categories
            .map(
              (category) => GroceryCategoryModel(
                id: category.id,
                name: category.name,
                items: category.items
                    .map(
                      (item) => GroceryItemModel(
                        id: item.id,
                        name: item.name,
                        quantity: item.quantity,
                        unit: item.unit,
                        isChecked: item.isChecked,
                        notes: item.notes,
                      ),
                    )
                    .toList(),
                order: category.order,
              ),
            )
            .toList(),
        mealPlanIds: groceryList.mealPlanIds,
        isCompleted: groceryList.isCompleted,
        completedItemsCount: groceryList.completedItemsCount,
        source: groceryList.source,
        notes: groceryList.notes,
      );

      // Update in Firestore
      await _groceryListsCollection
          .doc(groceryList.id)
          .update(groceryListModel.toFirestore());

      // Get the updated document
      final docSnapshot = await _groceryListsCollection
          .doc(groceryList.id)
          .get();

      return GroceryListModel.fromFirestore(docSnapshot).toDomain();
    });
  }

  @override
  Future<Either<Failure, bool>> deleteGroceryList(String id) async {
    return safeCall(() async {
      await _groceryListsCollection.doc(id).delete();
      return true;
    });
  }

  @override
  Future<Either<Failure, GroceryList>> generateGroceryListFromMealPlan(
    String userId,
    MealPlan mealPlan,
    String name,
  ) async {
    return safeCall(() async {
      // Extract all food items from the meal plan
      final allFoodItems = <PlannedFoodItem>[];

      mealPlan.plannedMeals.forEach((date, dailyPlan) {
        dailyPlan.meals.forEach((mealType, meal) {
          allFoodItems.addAll(meal.items);
        });
      });

      // Group items by name and aggregate quantities
      final Map<String, GroceryItem> groceryItems = {};

      for (final item in allFoodItems) {
        final key = '${item.name}_${item.unit}';

        if (groceryItems.containsKey(key)) {
          // Update quantity if item already exists
          final existingItem = groceryItems[key]!;
          groceryItems[key] = GroceryItem(
            id: existingItem.id,
            name: existingItem.name,
            quantity: existingItem.quantity + item.quantity,
            unit: existingItem.unit,
            isChecked: existingItem.isChecked,
            notes: existingItem.notes,
          );
        } else {
          // Add new item
          groceryItems[key] = GroceryItem(
            id: _uuid.v4(),
            name: item.name,
            quantity: item.quantity,
            unit: item.unit,
            isChecked: false,
            notes: null,
          );
        }
      }

      // Create grocery list categories
      final categories = [
        GroceryCategory(
          id: _uuid.v4(),
          name: 'All Items',
          items: groceryItems.values.toList(),
          order: 0,
        ),
      ];

      // Create grocery list
      final groceryList = GroceryList(
        id: _uuid.v4(),
        userId: userId,
        name: name,
        createdAt: DateTime.now(),
        lastModifiedAt: DateTime.now(),
        categories: categories,
        mealPlanIds: [mealPlan.id],
        isCompleted: false,
        completedItemsCount: 0,
        source: GroceryListSource.mealPlan,
        notes: 'Generated from meal plan: ${mealPlan.name}',
      );

      // Save to repository and return the result
      final result = await createGroceryList(groceryList);
      return result.fold(
        (failure) => throw failure,
        (groceryList) => groceryList,
      );
    });
  }

  @override
  Future<Either<Failure, GroceryList>> generateGroceryListFromMultipleMealPlans(
    String userId,
    List<MealPlan> mealPlans,
    String name,
  ) async {
    return safeCall(() async {
      // Extract all food items from all meal plans
      final allFoodItems = <PlannedFoodItem>[];
      final mealPlanIds = <String>[];

      for (final mealPlan in mealPlans) {
        mealPlanIds.add(mealPlan.id);

        mealPlan.plannedMeals.forEach((date, dailyPlan) {
          dailyPlan.meals.forEach((mealType, meal) {
            allFoodItems.addAll(meal.items);
          });
        });
      }

      // Group items by name and aggregate quantities
      final Map<String, GroceryItem> groceryItems = {};

      for (final item in allFoodItems) {
        final key = '${item.name}_${item.unit}';

        if (groceryItems.containsKey(key)) {
          // Update quantity if item already exists
          final existingItem = groceryItems[key]!;
          groceryItems[key] = GroceryItem(
            id: existingItem.id,
            name: existingItem.name,
            quantity: existingItem.quantity + item.quantity,
            unit: existingItem.unit,
            isChecked: existingItem.isChecked,
            notes: existingItem.notes,
          );
        } else {
          // Add new item
          groceryItems[key] = GroceryItem(
            id: _uuid.v4(),
            name: item.name,
            quantity: item.quantity,
            unit: item.unit,
            isChecked: false,
            notes: null,
          );
        }
      }

      // Create grocery list categories
      final categories = [
        GroceryCategory(
          id: _uuid.v4(),
          name: 'All Items',
          items: groceryItems.values.toList(),
          order: 0,
        ),
      ];

      // Create grocery list
      final groceryList = GroceryList(
        id: _uuid.v4(),
        userId: userId,
        name: name,
        createdAt: DateTime.now(),
        lastModifiedAt: DateTime.now(),
        categories: categories,
        mealPlanIds: mealPlanIds,
        isCompleted: false,
        completedItemsCount: 0,
        source: GroceryListSource.mealPlan,
        notes: 'Generated from ${mealPlans.length} meal plans',
      );

      // Save to repository and return the result
      final result = await createGroceryList(groceryList);
      return result.fold(
        (failure) => throw failure,
        (groceryList) => groceryList,
      );
    });
  }

  @override
  Future<Either<Failure, GroceryList>> toggleGroceryItemCheck(
    String groceryListId,
    String categoryId,
    String itemId,
    bool isChecked,
  ) async {
    return safeCall(() async {
      // Get current grocery list
      final groceryListResult = await getGroceryListById(groceryListId);

      final groceryList = groceryListResult.fold(
        (failure) => throw failure,
        (groceryList) => groceryList,
      );

      // Find the category and item
      final updatedCategories = groceryList.categories.map((category) {
        if (category.id == categoryId) {
          final updatedItems = category.items.map((item) {
            if (item.id == itemId) {
              return item.copyWith(isChecked: isChecked);
            }
            return item;
          }).toList();

          return category.copyWith(items: updatedItems);
        }
        return category;
      }).toList();

      // Count completed items
      int completedCount = 0;
      for (final category in updatedCategories) {
        for (final item in category.items) {
          if (item.isChecked) {
            completedCount++;
          }
        }
      }

      // Update grocery list
      final updatedGroceryList = groceryList.copyWith(
        categories: updatedCategories,
        completedItemsCount: completedCount,
        lastModifiedAt: DateTime.now(),
      );

      // Save to repository and return the result
      final result = await updateGroceryList(updatedGroceryList);
      return result.fold(
        (failure) => throw failure,
        (groceryList) => groceryList,
      );
    });
  }

  @override
  Future<Either<Failure, GroceryList>> addItemToGroceryList(
    String groceryListId,
    String categoryId,
    GroceryItem item,
  ) async {
    return safeCall(() async {
      // Get current grocery list
      final groceryListResult = await getGroceryListById(groceryListId);

      final groceryList = groceryListResult.fold(
        (failure) => throw failure,
        (groceryList) => groceryList,
      );

      // Find the category
      final updatedCategories = groceryList.categories.map((category) {
        if (category.id == categoryId) {
          // Check if item with same name and unit already exists
          final existingItemIndex = category.items.indexWhere(
            (i) => i.name == item.name && i.unit == item.unit,
          );

          if (existingItemIndex >= 0) {
            // Update existing item
            final existingItem = category.items[existingItemIndex];
            final updatedItems = List<GroceryItem>.from(category.items);
            updatedItems[existingItemIndex] = existingItem.copyWith(
              quantity: existingItem.quantity + item.quantity,
            );
            return category.copyWith(items: updatedItems);
          } else {
            // Add new item
            final newItem = item.copyWith(id: _uuid.v4());
            return category.copyWith(items: [...category.items, newItem]);
          }
        }
        return category;
      }).toList();

      // Update grocery list
      final updatedGroceryList = groceryList.copyWith(
        categories: updatedCategories,
        lastModifiedAt: DateTime.now(),
      );

      // Save to repository and return the result
      final result = await updateGroceryList(updatedGroceryList);
      return result.fold(
        (failure) => throw failure,
        (groceryList) => groceryList,
      );
    });
  }

  @override
  Future<Either<Failure, GroceryList>> removeItemFromGroceryList(
    String groceryListId,
    String categoryId,
    String itemId,
  ) async {
    return safeCall(() async {
      // Get current grocery list
      final groceryListResult = await getGroceryListById(groceryListId);

      final groceryList = groceryListResult.fold(
        (failure) => throw failure,
        (groceryList) => groceryList,
      );

      // Find the category and remove the item
      final updatedCategories = groceryList.categories.map((category) {
        if (category.id == categoryId) {
          final updatedItems = category.items
              .where((item) => item.id != itemId)
              .toList();

          return category.copyWith(items: updatedItems);
        }
        return category;
      }).toList();

      // Count completed items
      int completedCount = 0;
      for (final category in updatedCategories) {
        for (final item in category.items) {
          if (item.isChecked) {
            completedCount++;
          }
        }
      }

      // Update grocery list
      final updatedGroceryList = groceryList.copyWith(
        categories: updatedCategories,
        completedItemsCount: completedCount,
        lastModifiedAt: DateTime.now(),
      );

      // Save to repository and return the result
      final result = await updateGroceryList(updatedGroceryList);
      return result.fold(
        (failure) => throw failure,
        (groceryList) => groceryList,
      );
    });
  }

  @override
  Future<Either<Failure, GroceryList>> markGroceryListCompleted(
    String groceryListId,
    bool isCompleted,
  ) async {
    return safeCall(() async {
      // Get current grocery list
      final groceryListResult = await getGroceryListById(groceryListId);

      final groceryList = groceryListResult.fold(
        (failure) => throw failure,
        (groceryList) => groceryList,
      );

      // Update completed status
      final updatedGroceryList = groceryList.copyWith(
        isCompleted: isCompleted,
        lastModifiedAt: DateTime.now(),
      );

      // Save to repository and return the result
      final result = await updateGroceryList(updatedGroceryList);
      return result.fold(
        (failure) => throw failure,
        (groceryList) => groceryList,
      );
    });
  }
}
