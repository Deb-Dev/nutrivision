import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/models/meal_models.dart';
import '../repositories/meal_history_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';

/// Use case for retrieving meal history with filtering options
/// Implements business logic for meal history display and organization
@injectable
class GetMealHistoryUseCase {
  final MealHistoryRepository repository;

  const GetMealHistoryUseCase(this.repository);

  Future<Result<GroupedMealHistory>> call(GetMealHistoryParams params) async {
    try {
      return await repository.getMealHistory(
        userId: params.userId,
        filter: params.filter,
      );
    } catch (e) {
      return Left(
        Failure.serverFailure(
          message: 'Failed to retrieve meal history: ${e.toString()}',
        ),
      );
    }
  }
}

/// Parameters for the GetMealHistoryUseCase
class GetMealHistoryParams {
  final String userId;
  final MealHistoryFilter? filter;

  GetMealHistoryParams({required this.userId, this.filter});
}

/// Use case for retrieving a single meal by ID
@injectable
class GetMealByIdUseCase {
  final MealHistoryRepository repository;

  const GetMealByIdUseCase(this.repository);

  Future<Result<MealHistoryEntry>> call(GetMealByIdParams params) async {
    try {
      return await repository.getMealById(
        userId: params.userId,
        mealId: params.mealId,
      );
    } catch (e) {
      return Left(
        Failure.serverFailure(
          message: 'Failed to retrieve meal: ${e.toString()}',
        ),
      );
    }
  }
}

/// Parameters for the GetMealByIdUseCase
class GetMealByIdParams {
  final String userId;
  final String mealId;

  GetMealByIdParams({required this.userId, required this.mealId});
}

/// Use case for updating an existing meal
@injectable
class UpdateMealUseCase {
  final MealHistoryRepository repository;

  const UpdateMealUseCase(this.repository);

  Future<Result<MealHistoryEntry>> call(UpdateMealParams params) async {
    try {
      // Update edit tracking info
      final updatedMeal = params.updatedMeal.copyWith(
        editedAt: DateTime.now(),
        editCount: params.updatedMeal.editCount + 1,
      );

      return await repository.updateMeal(
        userId: params.userId,
        updatedMeal: updatedMeal,
      );
    } catch (e) {
      return Left(
        Failure.serverFailure(
          message: 'Failed to update meal: ${e.toString()}',
        ),
      );
    }
  }
}

/// Parameters for the UpdateMealUseCase
class UpdateMealParams {
  final String userId;
  final MealHistoryEntry updatedMeal;

  UpdateMealParams({required this.userId, required this.updatedMeal});
}

/// Use case for deleting a meal
@injectable
class DeleteMealUseCase {
  final MealHistoryRepository repository;

  const DeleteMealUseCase(this.repository);

  Future<Result<void>> call(DeleteMealParams params) async {
    try {
      return await repository.deleteMeal(
        userId: params.userId,
        mealId: params.mealId,
      );
    } catch (e) {
      return Left(
        Failure.serverFailure(
          message: 'Failed to delete meal: ${e.toString()}',
        ),
      );
    }
  }
}

/// Parameters for the DeleteMealUseCase
class DeleteMealParams {
  final String userId;
  final String mealId;

  DeleteMealParams({required this.userId, required this.mealId});
}

/// Use case for getting nutritional summary for a period
@injectable
class GetNutritionalSummaryUseCase {
  final MealHistoryRepository repository;

  const GetNutritionalSummaryUseCase(this.repository);

  Future<Result<NutritionalSummary>> call(
    GetNutritionalSummaryParams params,
  ) async {
    try {
      return await repository.getNutritionalSummary(
        userId: params.userId,
        startDate: params.startDate,
        endDate: params.endDate,
      );
    } catch (e) {
      return Left(
        Failure.serverFailure(
          message: 'Failed to get nutritional summary: ${e.toString()}',
        ),
      );
    }
  }
}

/// Parameters for the GetNutritionalSummaryUseCase
class GetNutritionalSummaryParams {
  final String userId;
  final DateTime startDate;
  final DateTime endDate;

  GetNutritionalSummaryParams({
    required this.userId,
    required this.startDate,
    required this.endDate,
  });
}

/// Use case for searching meal history
@injectable
class SearchMealHistoryUseCase {
  final MealHistoryRepository repository;

  const SearchMealHistoryUseCase(this.repository);

  Future<Result<List<MealHistoryEntry>>> call(
    SearchMealHistoryParams params,
  ) async {
    try {
      if (params.searchQuery.length < 3) {
        return Left(
          Failure.validationFailure(
            message: 'Search query must be at least 3 characters',
          ),
        );
      }

      return await repository.searchMealHistory(
        userId: params.userId,
        searchQuery: params.searchQuery,
        limit: params.limit,
      );
    } catch (e) {
      return Left(
        Failure.serverFailure(
          message: 'Failed to search meal history: ${e.toString()}',
        ),
      );
    }
  }
}

/// Parameters for the SearchMealHistoryUseCase
class SearchMealHistoryParams {
  final String userId;
  final String searchQuery;
  final int? limit;

  SearchMealHistoryParams({
    required this.userId,
    required this.searchQuery,
    this.limit,
  });
}

/// Use case for getting recent meals
@injectable
class GetRecentMealsUseCase {
  final MealHistoryRepository repository;

  const GetRecentMealsUseCase(this.repository);

  Future<Result<List<MealHistoryEntry>>> call(
    GetRecentMealsParams params,
  ) async {
    try {
      return await repository.getRecentMeals(
        userId: params.userId,
        limit: params.limit,
      );
    } catch (e) {
      return Left(
        Failure.serverFailure(
          message: 'Failed to get recent meals: ${e.toString()}',
        ),
      );
    }
  }
}

/// Parameters for the GetRecentMealsUseCase
class GetRecentMealsParams {
  final String userId;
  final int limit;

  GetRecentMealsParams({required this.userId, this.limit = 10});
}
