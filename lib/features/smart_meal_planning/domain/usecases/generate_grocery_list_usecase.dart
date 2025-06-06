import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../entities/grocery_list.dart';
import '../entities/meal_plan.dart';
import '../repositories/grocery_list_repository.dart';
import '../repositories/meal_plan_repository.dart';

/// Parameters for generating a grocery list
class GenerateGroceryListParams {
  final String userId;
  final String name;
  final List<String> mealPlanIds;

  GenerateGroceryListParams({
    required this.userId,
    required this.name,
    required this.mealPlanIds,
  });
}

/// Use case for generating a grocery list from meal plans
@injectable
class GenerateGroceryListUseCase {
  final GroceryListRepository groceryListRepository;
  final MealPlanRepository mealPlanRepository;

  GenerateGroceryListUseCase(
    this.groceryListRepository,
    this.mealPlanRepository,
  );

  Future<Either<Failure, GroceryList>> call(
    GenerateGroceryListParams params,
  ) async {
    try {
      // Fetch all the meal plans
      final List<MealPlan> mealPlans = [];

      for (final mealPlanId in params.mealPlanIds) {
        final mealPlanResult = await mealPlanRepository.getMealPlanById(
          mealPlanId,
        );

        mealPlanResult.fold(
          (failure) => throw Exception('Failed to get meal plan: $failure'),
          (mealPlan) => mealPlans.add(mealPlan),
        );
      }

      // If we have more than one meal plan, use the multi-plan method
      if (mealPlans.length > 1) {
        return await groceryListRepository
            .generateGroceryListFromMultipleMealPlans(
              params.userId,
              mealPlans,
              params.name,
            );
      } else if (mealPlans.length == 1) {
        // If we have just one meal plan, use the single plan method
        return await groceryListRepository.generateGroceryListFromMealPlan(
          params.userId,
          mealPlans.first,
          params.name,
        );
      } else {
        // No valid meal plans were found
        return Left(
          Failure.validationFailure(message: 'No valid meal plans were found.'),
        );
      }
    } catch (e) {
      return Left(
        Failure.unexpectedFailure(
          message: "Error generating grocery list: ${e.toString()}",
          exception: e,
        ),
      );
    }
  }
}
