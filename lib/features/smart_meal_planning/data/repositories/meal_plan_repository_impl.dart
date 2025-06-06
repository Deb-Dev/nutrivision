import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/base_repository.dart';
import '../../domain/entities/meal_plan.dart';
import '../../domain/repositories/meal_plan_repository.dart';
import '../models/meal_plan_model.dart';

/// Implementation of the meal plan repository
@Injectable(as: MealPlanRepository)
class MealPlanRepositoryImpl extends BaseRepository
    implements MealPlanRepository {
  final FirebaseFirestore _firestore;

  // Collection reference
  late final CollectionReference<Map<String, dynamic>> _mealPlansCollection;

  MealPlanRepositoryImpl(this._firestore) {
    _mealPlansCollection = _firestore.collection('mealPlans');
  }

  @override
  Future<Either<Failure, MealPlan>> getMealPlanById(String id) async {
    return safeCall(() async {
      final docSnapshot = await _mealPlansCollection.doc(id).get();

      if (!docSnapshot.exists) {
        throw Exception('Meal plan not found');
      }

      final mealPlan = MealPlanModel.fromFirestore(docSnapshot);
      return mealPlan.toDomain();
    });
  }

  @override
  Future<Either<Failure, List<MealPlan>>> getUserMealPlans(
    String userId,
  ) async {
    return safeCall(() async {
      final querySnapshot = await _mealPlansCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final mealPlans = querySnapshot.docs
          .map((doc) => MealPlanModel.fromFirestore(doc).toDomain())
          .toList();

      return mealPlans;
    });
  }

  @override
  Future<Either<Failure, MealPlan?>> getActiveMealPlan(String userId) async {
    return safeCall(() async {
      final querySnapshot = await _mealPlansCollection
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final mealPlan = MealPlanModel.fromFirestore(
        querySnapshot.docs.first,
      ).toDomain();
      return mealPlan;
    });
  }

  @override
  Future<Either<Failure, MealPlan>> createMealPlan(MealPlan mealPlan) async {
    return safeCall(() async {
      // Convert domain entity to model
      final mealPlanModel = MealPlanModel.fromJson({
        'id': mealPlan.id,
        'userId': mealPlan.userId,
        'name': mealPlan.name,
        'createdAt': mealPlan.createdAt.toIso8601String(),
        'lastModifiedAt': mealPlan.lastModifiedAt?.toIso8601String(),
        'plannedMeals': _convertPlannedMealsToJson(mealPlan.plannedMeals),
        'description': mealPlan.description,
        'isActive': mealPlan.isActive,
        'source': mealPlan.source.toString().split('.').last,
        'metadata': mealPlan.metadata,
      });

      // Save to Firestore
      final docRef = _mealPlansCollection.doc(mealPlan.id);
      await docRef.set(mealPlanModel.toFirestore());

      // If this plan is active, deactivate other plans
      if (mealPlan.isActive) {
        await _deactivateOtherMealPlans(mealPlan.userId, mealPlan.id);
      }

      return mealPlan;
    });
  }

  @override
  Future<Either<Failure, MealPlan>> updateMealPlan(MealPlan mealPlan) async {
    return safeCall(() async {
      // Convert domain entity to model
      final mealPlanModel = MealPlanModel.fromJson({
        'id': mealPlan.id,
        'userId': mealPlan.userId,
        'name': mealPlan.name,
        'createdAt': mealPlan.createdAt.toIso8601String(),
        'lastModifiedAt': DateTime.now().toIso8601String(),
        'plannedMeals': _convertPlannedMealsToJson(mealPlan.plannedMeals),
        'description': mealPlan.description,
        'isActive': mealPlan.isActive,
        'source': mealPlan.source.toString().split('.').last,
        'metadata': mealPlan.metadata,
      });

      // Update in Firestore
      final docRef = _mealPlansCollection.doc(mealPlan.id);
      await docRef.update(mealPlanModel.toFirestore());

      // If this plan is active, deactivate other plans
      if (mealPlan.isActive) {
        await _deactivateOtherMealPlans(mealPlan.userId, mealPlan.id);
      }

      return mealPlan;
    });
  }

  @override
  Future<Either<Failure, bool>> deleteMealPlan(String id) async {
    return safeCall(() async {
      await _mealPlansCollection.doc(id).delete();
      return true;
    });
  }

  @override
  Future<Either<Failure, bool>> setMealPlanActive(
    String id,
    String userId,
  ) async {
    return safeCall(() async {
      // First, deactivate all meal plans for this user
      await _deactivateOtherMealPlans(userId, id);

      // Then, set the specified meal plan to active
      await _mealPlansCollection.doc(id).update({'isActive': true});

      return true;
    });
  }

  @override
  Future<Either<Failure, List<MealPlan>>> getMealPlansForDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    return safeCall(() async {
      final querySnapshot = await _mealPlansCollection
          .where('userId', isEqualTo: userId)
          .get();

      final allPlans = querySnapshot.docs
          .map((doc) => MealPlanModel.fromFirestore(doc).toDomain())
          .toList();

      // Filter plans that have meals within the specified date range
      final filteredPlans = allPlans.where((plan) {
        return plan.plannedMeals.keys.any((date) {
          return date.isAfter(startDate.subtract(const Duration(days: 1))) &&
              date.isBefore(endDate.add(const Duration(days: 1)));
        });
      }).toList();

      return filteredPlans;
    });
  }

  @override
  Future<Either<Failure, bool>> markPlannedMealCompleted(
    String mealPlanId,
    DateTime date,
    String mealType,
    String actualMealId,
  ) async {
    return safeCall(() async {
      final mealPlanResult = await getMealPlanById(mealPlanId);

      final mealPlan = mealPlanResult.fold(
        (failure) => throw failure,
        (mealPlan) => mealPlan,
      );

      // Get the daily plan for the specified date
      final plannedMeals = mealPlan.plannedMeals;

      // Find the exact date in the map
      final dateKey = plannedMeals.keys.firstWhere((key) {
        final keyDate = DateTime(key.year, key.month, key.day);
        final targetDate = DateTime(date.year, date.month, date.day);
        return keyDate == targetDate;
      }, orElse: () => DateTime(0));

      if (dateKey == DateTime(0)) {
        throw Exception('No meals planned for the specified date');
      }

      final dailyPlan = plannedMeals[dateKey]!;

      // Check if the meal type exists
      if (!dailyPlan.meals.containsKey(mealType)) {
        throw Exception('No $mealType planned for the specified date');
      }

      // Get the planned meal
      final plannedMeal = dailyPlan.meals[mealType]!;

      // Mark the meal as completed
      final updatedMeal = plannedMeal.copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
        actualMealId: actualMealId,
      );

      // Update the daily plan
      final updatedMeals = Map<String, PlannedMeal>.from(dailyPlan.meals);
      updatedMeals[mealType] = updatedMeal;

      final updatedDailyPlan = dailyPlan.copyWith(
        meals: updatedMeals,
        isCompleted: updatedMeals.values.every((meal) => meal.isCompleted),
      );

      // Update the meal plan
      final updatedPlannedMeals = Map<DateTime, DailyMealPlan>.from(
        mealPlan.plannedMeals,
      );
      updatedPlannedMeals[dateKey] = updatedDailyPlan;

      final updatedMealPlan = mealPlan.copyWith(
        plannedMeals: updatedPlannedMeals,
        lastModifiedAt: DateTime.now(),
      );

      // Save the updated meal plan
      final updateResult = await updateMealPlan(updatedMealPlan);

      return updateResult.fold((failure) => throw failure, (mealPlan) => true);
    });
  }

  @override
  Future<Either<Failure, MealPlan>> generateMealPlan(
    String userId,
    DateTime startDate,
    DateTime endDate,
    Map<String, dynamic> preferences,
  ) async {
    return safeCall(() async {
      // Create an empty meal plan with no suggestions - users will add meals manually
      final int days = endDate.difference(startDate).inDays + 1;
      final Map<DateTime, DailyMealPlan> plannedMeals = {};

      for (int i = 0; i < days; i++) {
        final date = startDate.add(Duration(days: i));

        // Create empty daily plan with no meals yet
        final dailyPlanId =
            'dp_${date.toIso8601String().split('T')[0]}_$userId';
        final dailyPlan = DailyMealPlan(
          id: dailyPlanId,
          date: date,
          meals: {}, // Start with empty meals
        );

        plannedMeals[date] = dailyPlan;
      }

      // Create the meal plan
      final id = 'mp_${DateTime.now().millisecondsSinceEpoch}_$userId';
      final planName =
          preferences['planName'] as String? ??
          'Meal Plan ${startDate.month}/${startDate.day} - ${endDate.month}/${endDate.day}';

      final mealPlan = MealPlan(
        id: id,
        userId: userId,
        name: planName,
        createdAt: DateTime.now(),
        lastModifiedAt: DateTime.now(),
        plannedMeals: plannedMeals,
        description: preferences['description'] as String?,
        isActive: preferences['makeActive'] as bool? ?? false,
        source: MealPlanSource.ai,
        metadata: {
          'generatedAt': DateTime.now().toIso8601String(),
          'preferences': preferences,
        },
      );

      // Save the meal plan
      final createResult = await createMealPlan(mealPlan);

      return createResult.fold(
        (failure) => throw failure,
        (mealPlan) => mealPlan,
      );
    });
  }

  // Helper method to deactivate all other meal plans for a user
  Future<void> _deactivateOtherMealPlans(
    String userId,
    String exceptPlanId,
  ) async {
    final batch = _firestore.batch();

    final querySnapshot = await _mealPlansCollection
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .get();

    for (final doc in querySnapshot.docs) {
      if (doc.id != exceptPlanId) {
        batch.update(doc.reference, {'isActive': false});
      }
    }

    await batch.commit();
  }

  // Helper method to convert plannedMeals map to JSON format
  Map<String, dynamic> _convertPlannedMealsToJson(
    Map<DateTime, DailyMealPlan> plannedMeals,
  ) {
    final Map<String, dynamic> result = {};

    plannedMeals.forEach((date, dailyPlan) {
      final dateString = date.toIso8601String().split('T')[0];
      result[dateString] = {
        'id': dailyPlan.id,
        'date': dateString,
        'meals': _convertMealsToJson(dailyPlan.meals),
        'isCompleted': dailyPlan.isCompleted,
        'notes': dailyPlan.notes,
      };
    });

    return result;
  }

  // Helper method to convert meals map to JSON format
  Map<String, dynamic> _convertMealsToJson(Map<String, PlannedMeal> meals) {
    final Map<String, dynamic> result = {};

    meals.forEach((mealType, plannedMeal) {
      result[mealType] = {
        'id': plannedMeal.id,
        'mealType': plannedMeal.mealType,
        'items': plannedMeal.items
            .map(
              (item) => {
                'id': item.id,
                'name': item.name,
                'quantity': item.quantity,
                'unit': item.unit,
                'nutritionalValues': item.nutritionalValues,
                'recipeId': item.recipeId,
                'imageUrl': item.imageUrl,
                'notes': item.notes,
              },
            )
            .toList(),
        'estimatedNutrition': {
          'calories': plannedMeal.estimatedNutrition.calories,
          'protein': plannedMeal.estimatedNutrition.protein,
          'carbs': plannedMeal.estimatedNutrition.carbs,
          'fat': plannedMeal.estimatedNutrition.fat,
          'fiber': plannedMeal.estimatedNutrition.fiber,
          'sugar': plannedMeal.estimatedNutrition.sugar,
          'sodium': plannedMeal.estimatedNutrition.sodium,
        },
        'isCompleted': plannedMeal.isCompleted,
        'completedAt': plannedMeal.completedAt?.toIso8601String(),
        'actualMealId': plannedMeal.actualMealId,
        'notes': plannedMeal.notes,
        'source': plannedMeal.source.toString().split('.').last,
      };
    });

    return result;
  }
}
