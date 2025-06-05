import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../entities/nutrition_goals.dart';
import '../repositories/favorite_meals_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';

/// Use case for creating a favorite meal
@injectable
class CreateFavoriteMealUseCase {
  final FavoriteMealsRepository repository;

  const CreateFavoriteMealUseCase(this.repository);

  Future<Result<FavoriteMeal>> call(CreateFavoriteMealParams params) async {
    try {
      // Validate favorite meal
      if (params.name.isEmpty) {
        return Left(
          Failure.validationFailure(message: 'Meal name cannot be empty'),
        );
      }

      if (params.foodItems.isEmpty) {
        return Left(
          Failure.validationFailure(
            message: 'Meal must contain at least one food item',
          ),
        );
      }

      return await repository.createFavoriteMeal(
        userId: params.userId,
        name: params.name,
        foodItems: params.foodItems,
        nutrition: params.nutrition,
        mealType: params.mealType,
        imageUrl: params.imageUrl,
        notes: params.notes,
      );
    } catch (e) {
      return Left(
        Failure.serverFailure(
          message: 'Failed to create favorite meal: ${e.toString()}',
        ),
      );
    }
  }
}

/// Parameters for CreateFavoriteMealUseCase
class CreateFavoriteMealParams {
  final String userId;
  final String name;
  final List<FavoriteFoodItem> foodItems;
  final NutritionalSummary nutrition;
  final String mealType;
  final String? imageUrl;
  final String? notes;

  CreateFavoriteMealParams({
    required this.userId,
    required this.name,
    required this.foodItems,
    required this.nutrition,
    required this.mealType,
    this.imageUrl,
    this.notes,
  });
}

/// Use case for retrieving favorite meals
@injectable
class GetFavoriteMealsUseCase {
  final FavoriteMealsRepository repository;

  const GetFavoriteMealsUseCase(this.repository);

  Future<Result<List<FavoriteMeal>>> call(GetFavoriteMealsParams params) async {
    try {
      return await repository.getFavoriteMeals(userId: params.userId);
    } catch (e) {
      return Left(
        Failure.serverFailure(
          message: 'Failed to retrieve favorite meals: ${e.toString()}',
        ),
      );
    }
  }
}

/// Parameters for GetFavoriteMealsUseCase
class GetFavoriteMealsParams {
  final String userId;

  GetFavoriteMealsParams({required this.userId});
}

/// Use case for getting a single favorite meal
@injectable
class GetFavoriteMealByIdUseCase {
  final FavoriteMealsRepository repository;

  const GetFavoriteMealByIdUseCase(this.repository);

  Future<Result<FavoriteMeal>> call(GetFavoriteMealByIdParams params) async {
    try {
      return await repository.getFavoriteMealById(
        userId: params.userId,
        favoriteMealId: params.favoriteMealId,
      );
    } catch (e) {
      return Left(
        Failure.serverFailure(
          message: 'Failed to retrieve favorite meal: ${e.toString()}',
        ),
      );
    }
  }
}

/// Parameters for GetFavoriteMealByIdUseCase
class GetFavoriteMealByIdParams {
  final String userId;
  final String favoriteMealId;

  GetFavoriteMealByIdParams({
    required this.userId,
    required this.favoriteMealId,
  });
}

/// Use case for updating a favorite meal
@injectable
class UpdateFavoriteMealUseCase {
  final FavoriteMealsRepository repository;

  const UpdateFavoriteMealUseCase(this.repository);

  Future<Result<FavoriteMeal>> call(UpdateFavoriteMealParams params) async {
    try {
      // Validate favorite meal
      if (params.updatedMeal.name.isEmpty) {
        return Left(
          Failure.validationFailure(message: 'Meal name cannot be empty'),
        );
      }

      if (params.updatedMeal.foodItems.isEmpty) {
        return Left(
          Failure.validationFailure(
            message: 'Meal must contain at least one food item',
          ),
        );
      }

      return await repository.updateFavoriteMeal(
        userId: params.userId,
        updatedMeal: params.updatedMeal,
      );
    } catch (e) {
      return Left(
        Failure.serverFailure(
          message: 'Failed to update favorite meal: ${e.toString()}',
        ),
      );
    }
  }
}

/// Parameters for UpdateFavoriteMealUseCase
class UpdateFavoriteMealParams {
  final String userId;
  final FavoriteMeal updatedMeal;

  UpdateFavoriteMealParams({required this.userId, required this.updatedMeal});
}

/// Use case for deleting a favorite meal
@injectable
class DeleteFavoriteMealUseCase {
  final FavoriteMealsRepository repository;

  const DeleteFavoriteMealUseCase(this.repository);

  Future<Result<void>> call(DeleteFavoriteMealParams params) async {
    try {
      return await repository.deleteFavoriteMeal(
        userId: params.userId,
        favoriteMealId: params.favoriteMealId,
      );
    } catch (e) {
      return Left(
        Failure.serverFailure(
          message: 'Failed to delete favorite meal: ${e.toString()}',
        ),
      );
    }
  }
}

/// Parameters for DeleteFavoriteMealUseCase
class DeleteFavoriteMealParams {
  final String userId;
  final String favoriteMealId;

  DeleteFavoriteMealParams({
    required this.userId,
    required this.favoriteMealId,
  });
}

/// Use case for logging a favorite meal
@injectable
class LogFavoriteMealUseCase {
  final FavoriteMealsRepository repository;

  const LogFavoriteMealUseCase(this.repository);

  Future<Result<String>> call(LogFavoriteMealParams params) async {
    try {
      return await repository.logFavoriteMeal(
        userId: params.userId,
        favoriteMealId: params.favoriteMealId,
        loggedAt: params.loggedAt,
        notes: params.notes,
      );
    } catch (e) {
      return Left(
        Failure.serverFailure(
          message: 'Failed to log favorite meal: ${e.toString()}',
        ),
      );
    }
  }
}

/// Parameters for LogFavoriteMealUseCase
class LogFavoriteMealParams {
  final String userId;
  final String favoriteMealId;
  final DateTime loggedAt;
  final String? notes;

  LogFavoriteMealParams({
    required this.userId,
    required this.favoriteMealId,
    required this.loggedAt,
    this.notes,
  });
}
