import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/grocery_list.dart';
import '../../domain/usecases/generate_grocery_list_usecase.dart';
import '../../domain/repositories/grocery_list_repository.dart';
import '../../domain/repositories/meal_plan_repository.dart';
import '../../data/repositories/grocery_list_repository_impl.dart';
import '../../data/repositories/meal_plan_repository_impl.dart';

/// State for grocery lists
class GroceryListState {
  final List<GroceryList> groceryLists;
  final GroceryList? activeGroceryList;
  final bool isLoading;
  final Failure? failure;

  const GroceryListState({
    this.groceryLists = const [],
    this.activeGroceryList,
    this.isLoading = false,
    this.failure,
  });

  GroceryListState copyWith({
    List<GroceryList>? groceryLists,
    GroceryList? activeGroceryList,
    bool? isLoading,
    Failure? failure,
  }) {
    return GroceryListState(
      groceryLists: groceryLists ?? this.groceryLists,
      activeGroceryList: activeGroceryList ?? this.activeGroceryList,
      isLoading: isLoading ?? this.isLoading,
      failure: failure,
    );
  }
}

/// Provider for grocery lists
class GroceryListNotifier extends StateNotifier<GroceryListState> {
  final GenerateGroceryListUseCase _generateGroceryListUseCase;

  GroceryListNotifier(this._generateGroceryListUseCase)
    : super(const GroceryListState());

  /// Generate a grocery list from meal plans
  Future<void> generateGroceryList({
    required String userId,
    required List<String> mealPlanIds,
    required String name,
  }) async {
    state = state.copyWith(isLoading: true, failure: null);

    final params = GenerateGroceryListParams(
      userId: userId,
      mealPlanIds: mealPlanIds,
      name: name,
    );

    final result = await _generateGroceryListUseCase(params);

    result.fold(
      (failure) => state = state.copyWith(isLoading: false, failure: failure),
      (groceryList) {
        final updatedLists = [...state.groceryLists, groceryList];

        state = state.copyWith(
          isLoading: false,
          groceryLists: updatedLists,
          activeGroceryList: groceryList,
        );
      },
    );
  }

  /// Toggle a grocery item as checked/unchecked
  void toggleItemCheck({
    required GroceryList groceryList,
    required String categoryId,
    required String itemId,
    required bool isChecked,
  }) {
    // Find the grocery list in the state
    final index = state.groceryLists.indexOf(groceryList);
    if (index == -1) return;

    // Find the category and update the item
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

    // Create updated grocery list
    final updatedGroceryList = groceryList.copyWith(
      categories: updatedCategories,
      completedItemsCount: completedCount,
    );

    // Update the list of grocery lists
    final updatedLists = List<GroceryList>.from(state.groceryLists);
    updatedLists[index] = updatedGroceryList;

    // Update state
    state = state.copyWith(
      groceryLists: updatedLists,
      activeGroceryList: state.activeGroceryList == groceryList
          ? updatedGroceryList
          : state.activeGroceryList,
    );
  }

  /// Add an item to a grocery list
  void addItem({
    required GroceryList groceryList,
    required String categoryId,
    required GroceryItem item,
  }) {
    // Find the grocery list in the state
    final index = state.groceryLists.indexOf(groceryList);
    if (index == -1) return;

    // Find the category and add the item
    final updatedCategories = groceryList.categories.map((category) {
      if (category.id == categoryId) {
        // Check if an item with the same name already exists
        final existingItemIndex = category.items.indexWhere(
          (i) => i.name == item.name && i.unit == item.unit,
        );

        if (existingItemIndex != -1) {
          // Update existing item quantity
          final existingItem = category.items[existingItemIndex];
          final updatedItems = List<GroceryItem>.from(category.items);
          updatedItems[existingItemIndex] = existingItem.copyWith(
            quantity: existingItem.quantity + item.quantity,
          );
          return category.copyWith(items: updatedItems);
        } else {
          // Add new item
          return category.copyWith(items: [...category.items, item]);
        }
      }
      return category;
    }).toList();

    // Create updated grocery list
    final updatedGroceryList = groceryList.copyWith(
      categories: updatedCategories,
    );

    // Update the list of grocery lists
    final updatedLists = List<GroceryList>.from(state.groceryLists);
    updatedLists[index] = updatedGroceryList;

    // Update state
    state = state.copyWith(
      groceryLists: updatedLists,
      activeGroceryList: state.activeGroceryList == groceryList
          ? updatedGroceryList
          : state.activeGroceryList,
    );
  }
}

/// Provider for grocery lists
final groceryListProvider =
    StateNotifierProvider<GroceryListNotifier, GroceryListState>((ref) {
      final generateGroceryListUseCase = ref.watch(
        generateGroceryListUseCaseProvider,
      );
      return GroceryListNotifier(generateGroceryListUseCase);
    });

/// Provider for the use case
final generateGroceryListUseCaseProvider = Provider<GenerateGroceryListUseCase>(
  (ref) {
    final groceryListRepository = ref.watch(groceryListRepositoryProvider);
    final mealPlanRepository = ref.watch(mealPlanRepositoryProvider);
    return GenerateGroceryListUseCase(
      groceryListRepository,
      mealPlanRepository,
    );
  },
);

/// Provider for the grocery list repository
final groceryListRepositoryProvider = Provider<GroceryListRepository>((ref) {
  return GroceryListRepositoryImpl(FirebaseFirestore.instance);
});

/// Provider for the meal plan repository (shared with meal_plan_provider)
final mealPlanRepositoryProvider = Provider<MealPlanRepository>((ref) {
  return MealPlanRepositoryImpl(FirebaseFirestore.instance);
});
