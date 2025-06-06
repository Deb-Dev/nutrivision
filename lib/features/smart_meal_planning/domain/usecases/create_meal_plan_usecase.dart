import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../entities/meal_plan.dart';
import '../repositories/meal_plan_repository.dart';

/// Parameters for creating a meal plan
class CreateMealPlanParams {
  final String userId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, dynamic> preferences;
  final bool makeActive;

  CreateMealPlanParams({
    required this.userId,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.preferences,
    this.makeActive = false,
  });
}

/// Use case for creating a new meal plan
@injectable
class CreateMealPlanUseCase {
  final MealPlanRepository repository;

  CreateMealPlanUseCase(this.repository);

  Future<Either<Failure, MealPlan>> call(CreateMealPlanParams params) async {
    try {
      // Create a simple meal plan without AI suggestions
      final String id =
          'mp_${DateTime.now().millisecondsSinceEpoch}_${params.userId}';
      final Map<DateTime, DailyMealPlan> plannedMeals = {};

      // Create empty daily plans for each day in the range
      final int days = params.endDate.difference(params.startDate).inDays + 1;
      for (int i = 0; i < days; i++) {
        final date = params.startDate.add(Duration(days: i));
        final dailyPlanId =
            'dp_${date.toIso8601String().split('T')[0]}_${params.userId}';
        plannedMeals[date] = DailyMealPlan(
          id: dailyPlanId,
          date: date,
          meals: {},
        );
      }

      // Create the meal plan entity
      final mealPlan = MealPlan(
        id: id,
        userId: params.userId,
        name: params.name,
        createdAt: DateTime.now(),
        lastModifiedAt: DateTime.now(),
        plannedMeals: plannedMeals,
        description: params.preferences['description'] as String?,
        isActive: params.makeActive,
        source: MealPlanSource.user,
        metadata: {
          'createdAt': DateTime.now().toIso8601String(),
          'preferences': params.preferences,
        },
      );

      // Save the meal plan to repository
      final createResult = await repository.createMealPlan(mealPlan);

      return createResult.fold((failure) => Left(failure), (createdPlan) async {
        // If the meal plan should be set as active
        if (params.makeActive) {
          final setActiveResult = await repository.setMealPlanActive(
            createdPlan.id,
            params.userId,
          );

          return setActiveResult.fold(
            (failure) => Left(failure),
            (_) => Right(createdPlan),
          );
        }

        return Right(createdPlan);
      });
    } catch (e) {
      return Left(
        Failure.unexpectedFailure(
          message: "Error creating meal plan: ${e.toString()}",
          exception: e,
        ),
      );
    }
  }
}
