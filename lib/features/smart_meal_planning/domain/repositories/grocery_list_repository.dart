import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/grocery_list.dart';
import '../entities/meal_plan.dart';

/// Repository interface for grocery list operations
abstract class GroceryListRepository {
  /// Get a grocery list by ID
  Future<Either<Failure, GroceryList>> getGroceryListById(String id);

  /// Get all grocery lists for a user
  Future<Either<Failure, List<GroceryList>>> getUserGroceryLists(String userId);

  /// Create a new grocery list
  Future<Either<Failure, GroceryList>> createGroceryList(
    GroceryList groceryList,
  );

  /// Update an existing grocery list
  Future<Either<Failure, GroceryList>> updateGroceryList(
    GroceryList groceryList,
  );

  /// Delete a grocery list
  Future<Either<Failure, bool>> deleteGroceryList(String id);

  /// Generate a grocery list from a meal plan
  Future<Either<Failure, GroceryList>> generateGroceryListFromMealPlan(
    String userId,
    MealPlan mealPlan,
    String name,
  );

  /// Generate a grocery list from multiple meal plans
  Future<Either<Failure, GroceryList>> generateGroceryListFromMultipleMealPlans(
    String userId,
    List<MealPlan> mealPlans,
    String name,
  );

  /// Mark a grocery item as checked/unchecked
  Future<Either<Failure, GroceryList>> toggleGroceryItemCheck(
    String groceryListId,
    String categoryId,
    String itemId,
    bool isChecked,
  );

  /// Add an item to a grocery list
  Future<Either<Failure, GroceryList>> addItemToGroceryList(
    String groceryListId,
    String categoryId,
    GroceryItem item,
  );

  /// Remove an item from a grocery list
  Future<Either<Failure, GroceryList>> removeItemFromGroceryList(
    String groceryListId,
    String categoryId,
    String itemId,
  );

  /// Mark a grocery list as completed
  Future<Either<Failure, GroceryList>> markGroceryListCompleted(
    String groceryListId,
    bool isCompleted,
  );
}
