import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../entities/nutrition_goals.dart';
import '../repositories/nutrition_analytics_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';

/// Use case for generating a nutrition report
@injectable
class GenerateNutritionReportUseCase {
  final NutritionAnalyticsRepository repository;

  const GenerateNutritionReportUseCase(this.repository);

  Future<Result<NutritionReport>> call(
    GenerateNutritionReportParams params,
  ) async {
    try {
      // Validate date range
      if (params.endDate.isBefore(params.startDate)) {
        return Left(
          Failure.validationFailure(
            message: 'End date must be after start date',
          ),
        );
      }

      // Validate period based on date range
      final daysDifference = params.endDate.difference(params.startDate).inDays;

      if (params.period == AnalyticsPeriod.daily && daysDifference > 31) {
        return Left(
          Failure.validationFailure(
            message: 'Daily period cannot exceed 31 days',
          ),
        );
      }

      if (params.period == AnalyticsPeriod.weekly && daysDifference > 183) {
        return Left(
          Failure.validationFailure(
            message: 'Weekly period cannot exceed 6 months',
          ),
        );
      }

      if (params.period == AnalyticsPeriod.monthly && daysDifference > 365) {
        return Left(
          Failure.validationFailure(
            message: 'Monthly period cannot exceed 1 year',
          ),
        );
      }

      return await repository.generateNutritionReport(
        userId: params.userId,
        startDate: params.startDate,
        endDate: params.endDate,
        period: params.period,
      );
    } catch (e) {
      return Left(
        Failure.serverFailure(
          message: 'Failed to generate nutrition report: ${e.toString()}',
        ),
      );
    }
  }
}

/// Parameters for GenerateNutritionReportUseCase
class GenerateNutritionReportParams {
  final String userId;
  final DateTime startDate;
  final DateTime endDate;
  final AnalyticsPeriod period;

  GenerateNutritionReportParams({
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.period,
  });
}

/// Use case for getting daily nutrition data
@injectable
class GetDailyNutritionDataUseCase {
  final NutritionAnalyticsRepository repository;

  const GetDailyNutritionDataUseCase(this.repository);

  Future<Result<List<DailyNutrition>>> call(
    GetDailyNutritionDataParams params,
  ) async {
    try {
      // Validate date range
      if (params.endDate.isBefore(params.startDate)) {
        return Left(
          Failure.validationFailure(
            message: 'End date must be after start date',
          ),
        );
      }

      // Limit to reasonable date range (90 days max)
      final daysDifference = params.endDate.difference(params.startDate).inDays;
      if (daysDifference > 90) {
        return Left(
          Failure.validationFailure(
            message: 'Date range cannot exceed 90 days',
          ),
        );
      }

      return await repository.getDailyNutritionData(
        userId: params.userId,
        startDate: params.startDate,
        endDate: params.endDate,
      );
    } catch (e) {
      return Left(
        Failure.serverFailure(
          message: 'Failed to get daily nutrition data: ${e.toString()}',
        ),
      );
    }
  }
}

/// Parameters for GetDailyNutritionDataUseCase
class GetDailyNutritionDataParams {
  final String userId;
  final DateTime startDate;
  final DateTime endDate;

  GetDailyNutritionDataParams({
    required this.userId,
    required this.startDate,
    required this.endDate,
  });
}

/// Use case for getting meal type distribution
@injectable
class GetMealTypeDistributionUseCase {
  final NutritionAnalyticsRepository repository;

  const GetMealTypeDistributionUseCase(this.repository);

  Future<Result<Map<String, int>>> call(
    GetMealTypeDistributionParams params,
  ) async {
    try {
      // Validate date range
      if (params.endDate.isBefore(params.startDate)) {
        return Left(
          Failure.validationFailure(
            message: 'End date must be after start date',
          ),
        );
      }

      return await repository.getMealTypeDistribution(
        userId: params.userId,
        startDate: params.startDate,
        endDate: params.endDate,
      );
    } catch (e) {
      return Left(
        Failure.serverFailure(
          message: 'Failed to get meal type distribution: ${e.toString()}',
        ),
      );
    }
  }
}

/// Parameters for GetMealTypeDistributionUseCase
class GetMealTypeDistributionParams {
  final String userId;
  final DateTime startDate;
  final DateTime endDate;

  GetMealTypeDistributionParams({
    required this.userId,
    required this.startDate,
    required this.endDate,
  });
}

/// Use case for getting top foods
@injectable
class GetTopFoodsUseCase {
  final NutritionAnalyticsRepository repository;

  const GetTopFoodsUseCase(this.repository);

  Future<Result<List<TopFood>>> call(GetTopFoodsParams params) async {
    try {
      // Validate date range
      if (params.endDate.isBefore(params.startDate)) {
        return Left(
          Failure.validationFailure(
            message: 'End date must be after start date',
          ),
        );
      }

      return await repository.getTopFoods(
        userId: params.userId,
        startDate: params.startDate,
        endDate: params.endDate,
        limit: params.limit,
      );
    } catch (e) {
      return Left(
        Failure.serverFailure(
          message: 'Failed to get top foods: ${e.toString()}',
        ),
      );
    }
  }
}

/// Parameters for GetTopFoodsUseCase
class GetTopFoodsParams {
  final String userId;
  final DateTime startDate;
  final DateTime endDate;
  final int limit;

  GetTopFoodsParams({
    required this.userId,
    required this.startDate,
    required this.endDate,
    this.limit = 10,
  });
}
