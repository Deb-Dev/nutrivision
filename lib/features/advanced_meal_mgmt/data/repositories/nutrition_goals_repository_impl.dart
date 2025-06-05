import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/nutrition_goals.dart';
import '../../domain/repositories/nutrition_goals_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';

/// Implementation of NutritionGoalsRepository
@LazySingleton(as: NutritionGoalsRepository)
class NutritionGoalsRepositoryImpl implements NutritionGoalsRepository {
  final FirebaseFirestore _firestore;

  const NutritionGoalsRepositoryImpl(this._firestore);

  @override
  Future<Result<NutritionalGoal>> createGoal({
    required String userId,
    required String name,
    required GoalType type,
    required double targetValue,
    required DateTime startDate,
    DateTime? endDate,
    String? notes,
  }) async {
    try {
      log('📝 [NUTRITION GOALS REPO] Creating new goal for user: $userId');

      final goalData = {
        'userId': userId,
        'name': name,
        'type': type.toString().split('.').last, // Convert enum to string
        'targetValue': targetValue,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': endDate != null ? Timestamp.fromDate(endDate) : null,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('nutritional_goals')
          .add(goalData);

      log('✅ [NUTRITION GOALS REPO] Goal created with ID: ${docRef.id}');

      // Construct a NutritionalGoal object with the newly created ID
      return Right(
        NutritionalGoal(
          id: docRef.id,
          userId: userId,
          name: name,
          type: type,
          targetValue: targetValue,
          startDate: startDate,
          endDate: endDate,
          notes: notes,
        ),
      );
    } catch (e) {
      log('❌ [NUTRITION GOALS REPO] Error creating goal: $e');
      return Left(Failure.serverFailure(message: 'Failed to create goal: $e'));
    }
  }

  @override
  Future<Result<List<NutritionalGoal>>> getActiveGoals({
    required String userId,
  }) async {
    try {
      log('🔍 [NUTRITION GOALS REPO] Getting active goals for user: $userId');

      final today = DateTime.now();
      final todayTimestamp = Timestamp.fromDate(today);

      // Get goals where:
      // 1. startDate is before or equal to today, AND
      // 2. endDate is null OR endDate is after or equal to today
      final query = await _firestore
          .collection('users')
          .doc(userId)
          .collection('nutritional_goals')
          .where('startDate', isLessThanOrEqualTo: todayTimestamp)
          .get();

      final activeGoals = <NutritionalGoal>[];

      for (final doc in query.docs) {
        final data = doc.data();
        final endDate = data['endDate'] as Timestamp?;

        // Skip goals with an end date that's in the past
        if (endDate != null && endDate.toDate().isBefore(today)) {
          continue;
        }

        try {
          activeGoals.add(
            NutritionalGoal(
              id: doc.id,
              userId: data['userId'] as String,
              name: data['name'] as String,
              type: _goalTypeFromString(data['type'] as String),
              targetValue: (data['targetValue'] as num).toDouble(),
              startDate: (data['startDate'] as Timestamp).toDate(),
              endDate: endDate?.toDate(),
              notes: data['notes'] as String?,
            ),
          );
        } catch (e) {
          log('⚠️ [NUTRITION GOALS REPO] Error parsing goal ${doc.id}: $e');
        }
      }

      log('✅ [NUTRITION GOALS REPO] Found ${activeGoals.length} active goals');
      return Right(activeGoals);
    } catch (e) {
      log('❌ [NUTRITION GOALS REPO] Error getting active goals: $e');
      return Left(
        Failure.serverFailure(message: 'Failed to retrieve active goals: $e'),
      );
    }
  }

  @override
  Future<Result<NutritionalGoal>> updateGoal({
    required String userId,
    required NutritionalGoal updatedGoal,
  }) async {
    try {
      log('📝 [NUTRITION GOALS REPO] Updating goal: ${updatedGoal.id}');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('nutritional_goals')
          .doc(updatedGoal.id)
          .update({
            'name': updatedGoal.name,
            'type': updatedGoal.type.toString().split('.').last,
            'targetValue': updatedGoal.targetValue,
            'startDate': Timestamp.fromDate(updatedGoal.startDate),
            'endDate': updatedGoal.endDate != null
                ? Timestamp.fromDate(updatedGoal.endDate!)
                : null,
            'notes': updatedGoal.notes,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      log('✅ [NUTRITION GOALS REPO] Goal updated: ${updatedGoal.id}');
      return Right(updatedGoal);
    } catch (e) {
      log('❌ [NUTRITION GOALS REPO] Error updating goal: $e');
      return Left(Failure.serverFailure(message: 'Failed to update goal: $e'));
    }
  }

  @override
  Future<Result<void>> deleteGoal({
    required String userId,
    required String goalId,
  }) async {
    try {
      log('🗑️ [NUTRITION GOALS REPO] Deleting goal: $goalId');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('nutritional_goals')
          .doc(goalId)
          .delete();

      log('✅ [NUTRITION GOALS REPO] Goal deleted: $goalId');
      return const Right(null);
    } catch (e) {
      log('❌ [NUTRITION GOALS REPO] Error deleting goal: $e');
      return Left(Failure.serverFailure(message: 'Failed to delete goal: $e'));
    }
  }

  @override
  Future<Result<Map<String, double>>> getGoalProgress({
    required String userId,
    required String goalId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      log(
        '📊 [NUTRITION GOALS REPO] Getting progress for goal: $goalId, period: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}',
      );

      // Get the goal first to determine what to measure
      final goalDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('nutritional_goals')
          .doc(goalId)
          .get();

      if (!goalDoc.exists) {
        log('❌ [NUTRITION GOALS REPO] Goal not found: $goalId');
        return Left(Failure.serverFailure(message: 'Goal not found'));
      }

      final goalData = goalDoc.data()!;
      final goalType = _goalTypeFromString(goalData['type'] as String);
      final targetValue = (goalData['targetValue'] as num).toDouble();

      // Get AI and manual meals for the date range
      final meals = await _getMealsInDateRange(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      if (meals.isEmpty) {
        log('⚠️ [NUTRITION GOALS REPO] No meals found in date range');
        return Right({'progress': 0.0, 'target': targetValue, 'actual': 0.0});
      }

      // Calculate progress based on goal type
      double actualValue = 0.0;
      switch (goalType) {
        case GoalType.dailyCalories:
          final totalCalories = _calculateTotalCalories(meals);
          final daysInRange = endDate.difference(startDate).inDays + 1;
          actualValue = totalCalories / daysInRange;
          break;
        case GoalType.dailyProtein:
          final totalProtein = _calculateTotalProtein(meals);
          final daysInRange = endDate.difference(startDate).inDays + 1;
          actualValue = totalProtein / daysInRange;
          break;
        case GoalType.dailyCarbs:
          final totalCarbs = _calculateTotalCarbs(meals);
          final daysInRange = endDate.difference(startDate).inDays + 1;
          actualValue = totalCarbs / daysInRange;
          break;
        case GoalType.dailyFat:
          final totalFat = _calculateTotalFat(meals);
          final daysInRange = endDate.difference(startDate).inDays + 1;
          actualValue = totalFat / daysInRange;
          break;
        case GoalType.weeklyCalories:
          final totalCalories = _calculateTotalCalories(meals);
          final weeksInRange =
              endDate.difference(startDate).inDays / 7.0; // Fractional weeks
          actualValue = totalCalories / weeksInRange;
          break;
        case GoalType.waterIntake:
        case GoalType.custom:
          // These would need separate tracking which isn't implemented yet
          actualValue = 0.0;
          break;
      }

      // Calculate progress percentage
      final progress = (actualValue / targetValue) * 100;

      log(
        '✅ [NUTRITION GOALS REPO] Goal progress calculated: $progress% (actual: $actualValue, target: $targetValue)',
      );
      return Right({
        'progress': progress,
        'target': targetValue,
        'actual': actualValue,
      });
    } catch (e) {
      log('❌ [NUTRITION GOALS REPO] Error getting goal progress: $e');
      return Left(
        Failure.serverFailure(message: 'Failed to calculate goal progress: $e'),
      );
    }
  }

  @override
  Future<Result<AverageNutrition>> getTodaysMealSummary({
    required String userId,
    required DateTime date,
  }) async {
    try {
      log(
        '📊 [NUTRITION GOALS REPO] Getting today\'s meal summary for: ${date.toIso8601String()}',
      );

      // Set time range for the day (beginning to end of day)
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      // Get all meals for today
      final meals = await _getMealsInDateRange(
        userId: userId,
        startDate: startOfDay,
        endDate: endOfDay,
      );

      // If no meals logged today, return zeros
      if (meals.isEmpty) {
        log('⚠️ [NUTRITION GOALS REPO] No meals found for today');
        return const Right(
          AverageNutrition(calories: 0, protein: 0, carbs: 0, fat: 0),
        );
      }

      // Calculate totals from today's meals
      final totalCalories = _calculateTotalCalories(meals);
      final totalProtein = _calculateTotalProtein(meals);
      final totalCarbs = _calculateTotalCarbs(meals);
      final totalFat = _calculateTotalFat(meals);

      // Create AverageNutrition object for today
      final todaysNutrition = AverageNutrition(
        calories: totalCalories.toDouble(),
        protein: totalProtein,
        carbs: totalCarbs,
        fat: totalFat,
      );

      log(
        '✅ [NUTRITION GOALS REPO] Today\'s nutrition summary: C:$totalCalories P:$totalProtein C:$totalCarbs F:$totalFat',
      );
      return Right(todaysNutrition);
    } catch (e) {
      log('❌ [NUTRITION GOALS REPO] Error getting today\'s meal summary: $e');
      return Left(
        Failure.serverFailure(
          message: 'Failed to get today\'s meal summary: $e',
        ),
      );
    }
  }

  /// Helper method to get both AI and manual meals for a date range
  Future<List<Map<String, dynamic>>> _getMealsInDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final startTimestamp = Timestamp.fromDate(startDate);
    final endTimestamp = Timestamp.fromDate(endDate);
    final allMeals = <Map<String, dynamic>>[];

    // Get AI meals
    final aiMealsQuery = await _firestore
        .collection('users')
        .doc(userId)
        .collection('ai_meal_logs')
        .where('loggedAt', isGreaterThanOrEqualTo: startTimestamp)
        .where('loggedAt', isLessThanOrEqualTo: endTimestamp)
        .get();

    for (final doc in aiMealsQuery.docs) {
      allMeals.add(doc.data());
    }

    // Get manual meals
    final manualMealsQuery = await _firestore
        .collection('users')
        .doc(userId)
        .collection('loggedMeals')
        .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
        .where('timestamp', isLessThanOrEqualTo: endTimestamp)
        .get();

    for (final doc in manualMealsQuery.docs) {
      allMeals.add(doc.data());
    }

    return allMeals;
  }

  /// Calculate total calories from meals
  int _calculateTotalCalories(List<Map<String, dynamic>> meals) {
    int total = 0;
    for (final meal in meals) {
      if (meal.containsKey('calories')) {
        // Manual meal
        total += (meal['calories'] as num).toInt();
      } else if (meal.containsKey('totalNutrition') &&
          meal['totalNutrition'].containsKey('calories')) {
        // AI meal
        total += (meal['totalNutrition']['calories'] as num).toInt();
      }
    }
    return total;
  }

  /// Calculate total protein from meals
  double _calculateTotalProtein(List<Map<String, dynamic>> meals) {
    double total = 0;
    for (final meal in meals) {
      if (meal.containsKey('proteinGrams')) {
        // Manual meal
        total += (meal['proteinGrams'] as num).toDouble();
      } else if (meal.containsKey('totalNutrition') &&
          meal['totalNutrition'].containsKey('protein')) {
        // AI meal
        total += (meal['totalNutrition']['protein'] as num).toDouble();
      }
    }
    return total;
  }

  /// Calculate total carbs from meals
  double _calculateTotalCarbs(List<Map<String, dynamic>> meals) {
    double total = 0;
    for (final meal in meals) {
      if (meal.containsKey('carbsGrams')) {
        // Manual meal
        total += (meal['carbsGrams'] as num).toDouble();
      } else if (meal.containsKey('totalNutrition') &&
          meal['totalNutrition'].containsKey('carbs')) {
        // AI meal
        total += (meal['totalNutrition']['carbs'] as num).toDouble();
      }
    }
    return total;
  }

  /// Calculate total fat from meals
  double _calculateTotalFat(List<Map<String, dynamic>> meals) {
    double total = 0;
    for (final meal in meals) {
      if (meal.containsKey('fatGrams')) {
        // Manual meal
        total += (meal['fatGrams'] as num).toDouble();
      } else if (meal.containsKey('totalNutrition') &&
          meal['totalNutrition'].containsKey('fat')) {
        // AI meal
        total += (meal['totalNutrition']['fat'] as num).toDouble();
      }
    }
    return total;
  }

  /// Helper method to convert string to GoalType enum
  GoalType _goalTypeFromString(String typeString) {
    switch (typeString) {
      case 'dailyCalories':
        return GoalType.dailyCalories;
      case 'dailyProtein':
        return GoalType.dailyProtein;
      case 'dailyCarbs':
        return GoalType.dailyCarbs;
      case 'dailyFat':
        return GoalType.dailyFat;
      case 'weeklyCalories':
        return GoalType.weeklyCalories;
      case 'waterIntake':
        return GoalType.waterIntake;
      case 'custom':
        return GoalType.custom;
      default:
        log('⚠️ [NUTRITION GOALS REPO] Unknown goal type: $typeString');
        return GoalType.custom;
    }
  }
}
