import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../entities/nutrition_goals.dart';
import '../repositories/nutrition_goals_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';

/// Use case for creating a new nutritional goal
@injectable
class CreateNutritionalGoalUseCase {
  final NutritionGoalsRepository repository;

  const CreateNutritionalGoalUseCase(this.repository);

  Future<Result<NutritionalGoal>> call(
    CreateNutritionalGoalParams params,
  ) async {
    try {
      // Validate goal values
      if (params.targetValue <= 0) {
        return Left(
          Failure.validationFailure(
            message: 'Target value must be greater than zero',
          ),
        );
      }

      // Validate date range
      if (params.endDate != null &&
          params.endDate!.isBefore(params.startDate)) {
        return Left(
          Failure.validationFailure(
            message: 'End date must be after start date',
          ),
        );
      }

      return await repository.createGoal(
        userId: params.userId,
        name: params.name,
        type: params.type,
        targetValue: params.targetValue,
        startDate: params.startDate,
        endDate: params.endDate,
        notes: params.notes,
      );
    } catch (e) {
      return Left(
        Failure.serverFailure(
          message: 'Failed to create goal: ${e.toString()}',
        ),
      );
    }
  }
}

/// Parameters for CreateNutritionalGoalUseCase
class CreateNutritionalGoalParams {
  final String userId;
  final String name;
  final GoalType type;
  final double targetValue;
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;

  CreateNutritionalGoalParams({
    required this.userId,
    required this.name,
    required this.type,
    required this.targetValue,
    required this.startDate,
    this.endDate,
    this.notes,
  });
}

/// Use case for retrieving active goals
@injectable
class GetActiveGoalsUseCase {
  final NutritionGoalsRepository repository;

  const GetActiveGoalsUseCase(this.repository);

  Future<Result<List<NutritionalGoal>>> call(
    GetActiveGoalsParams params,
  ) async {
    try {
      return await repository.getActiveGoals(userId: params.userId);
    } catch (e) {
      return Left(
        Failure.serverFailure(
          message: 'Failed to retrieve goals: ${e.toString()}',
        ),
      );
    }
  }
}

/// Parameters for GetActiveGoalsUseCase
class GetActiveGoalsParams {
  final String userId;

  GetActiveGoalsParams({required this.userId});
}

/// Use case for updating a nutritional goal
@injectable
class UpdateNutritionalGoalUseCase {
  final NutritionGoalsRepository repository;

  const UpdateNutritionalGoalUseCase(this.repository);

  Future<Result<NutritionalGoal>> call(
    UpdateNutritionalGoalParams params,
  ) async {
    try {
      // Validate goal values
      if (params.updatedGoal.targetValue <= 0) {
        return Left(
          Failure.validationFailure(
            message: 'Target value must be greater than zero',
          ),
        );
      }

      // Validate date range
      if (params.updatedGoal.endDate != null &&
          params.updatedGoal.endDate!.isBefore(params.updatedGoal.startDate)) {
        return Left(
          Failure.validationFailure(
            message: 'End date must be after start date',
          ),
        );
      }

      return await repository.updateGoal(
        userId: params.userId,
        updatedGoal: params.updatedGoal,
      );
    } catch (e) {
      return Left(
        Failure.serverFailure(
          message: 'Failed to update goal: ${e.toString()}',
        ),
      );
    }
  }
}

/// Parameters for UpdateNutritionalGoalUseCase
class UpdateNutritionalGoalParams {
  final String userId;
  final NutritionalGoal updatedGoal;

  UpdateNutritionalGoalParams({
    required this.userId,
    required this.updatedGoal,
  });
}

/// Use case for deleting a nutritional goal
@injectable
class DeleteNutritionalGoalUseCase {
  final NutritionGoalsRepository repository;

  const DeleteNutritionalGoalUseCase(this.repository);

  Future<Result<void>> call(DeleteNutritionalGoalParams params) async {
    try {
      return await repository.deleteGoal(
        userId: params.userId,
        goalId: params.goalId,
      );
    } catch (e) {
      return Left(
        Failure.serverFailure(
          message: 'Failed to delete goal: ${e.toString()}',
        ),
      );
    }
  }
}

/// Parameters for DeleteNutritionalGoalUseCase
class DeleteNutritionalGoalParams {
  final String userId;
  final String goalId;

  DeleteNutritionalGoalParams({required this.userId, required this.goalId});
}

/// Use case for getting goal progress
@injectable
class GetGoalProgressUseCase {
  final NutritionGoalsRepository repository;

  const GetGoalProgressUseCase(this.repository);

  Future<Result<Map<String, double>>> call(GetGoalProgressParams params) async {
    try {
      // Validate date range
      if (params.endDate.isBefore(params.startDate)) {
        return Left(
          Failure.validationFailure(
            message: 'End date must be after start date',
          ),
        );
      }

      return await repository.getGoalProgress(
        userId: params.userId,
        goalId: params.goalId,
        startDate: params.startDate,
        endDate: params.endDate,
      );
    } catch (e) {
      return Left(
        Failure.serverFailure(
          message: 'Failed to retrieve goal progress: ${e.toString()}',
        ),
      );
    }
  }
}

/// Parameters for GetGoalProgressUseCase
class GetGoalProgressParams {
  final String userId;
  final String goalId;
  final DateTime startDate;
  final DateTime endDate;

  GetGoalProgressParams({
    required this.userId,
    required this.goalId,
    required this.startDate,
    required this.endDate,
  });
}
