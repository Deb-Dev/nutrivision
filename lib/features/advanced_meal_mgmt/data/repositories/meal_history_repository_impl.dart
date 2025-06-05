import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/meal_history_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../../ai_meal_logging/domain/entities/ai_meal_recognition.dart';
import '../../../../core/models/meal_models.dart'; // Core meal models

/// Implementation of MealHistoryRepository using Firestore
/// Combines data from both AI meal logs and manual meal logs
@LazySingleton(as: MealHistoryRepository)
class MealHistoryRepositoryImpl implements MealHistoryRepository {
  final FirebaseFirestore _firestore;

  const MealHistoryRepositoryImpl(this._firestore);

  @override
  Future<Result<GroupedMealHistory>> getMealHistory({
    required String userId,
    MealHistoryFilter? filter,
  }) async {
    try {
      log('🗄️ [MEAL HISTORY REPO] Getting meal history for user: $userId');
      log(
        '🔍 [MEAL HISTORY REPO] Using filter: ${filter?.toString() ?? 'None'}',
      );

      // Get both AI meals and manual meals based on sources filter
      List<MealHistoryEntry> aiMeals = [];
      List<MealHistoryEntry> manualMeals = [];

      // Check if we should fetch AI meals
      final filterSources = filter?.sources;
      final shouldFetchAI =
          filterSources == null ||
          filterSources.isEmpty ||
          filterSources.contains(MealSource.aiAssisted);

      // Check if we should fetch manual meals
      final shouldFetchManual =
          filterSources == null ||
          filterSources.isEmpty ||
          filterSources.contains(MealSource.manual);

      if (shouldFetchAI) {
        log('🔄 [MEAL HISTORY REPO] Fetching AI meals...');
        final aiMealsResult = await _getAIMeals(userId, filter);
        if (aiMealsResult.isFailure) {
          log('❌ [MEAL HISTORY REPO] Failed to get AI meals');
          return aiMealsResult.fold((l) => Left(l), (r) => throw Exception());
        }
        aiMeals = aiMealsResult.successValue ?? [];
      } else {
        log('⏭️ [MEAL HISTORY REPO] Skipping AI meals due to sources filter');
      }

      if (shouldFetchManual) {
        log('🔄 [MEAL HISTORY REPO] Fetching manual meals...');
        final manualMealsResult = await _getManualMeals(userId, filter);
        if (manualMealsResult.isFailure) {
          log('❌ [MEAL HISTORY REPO] Failed to get manual meals');
          return manualMealsResult.fold(
            (l) => Left(l),
            (r) => throw Exception(),
          );
        }
        manualMeals = manualMealsResult.successValue ?? [];
      } else {
        log(
          '⏭️ [MEAL HISTORY REPO] Skipping manual meals due to sources filter',
        );
      }

      // Combine and sort meals
      final allMeals = [...aiMeals, ...manualMeals];
      log(
        '📊 [MEAL HISTORY REPO] Combined into ${allMeals.length} total meals',
      );

      // Sort by logged date (newest first)
      allMeals.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));

      // Group meals by date
      final groupedMeals = _groupMealsByDate(allMeals);

      log(
        '✅ [MEAL HISTORY REPO] Successfully retrieved ${allMeals.length} meals, grouped into ${groupedMeals.groupedMeals.length} dates',
      );
      return Right(groupedMeals);
    } catch (e, stack) {
      log('❌ [MEAL HISTORY REPO] Error getting meal history: $e');
      log('❌ [MEAL HISTORY REPO] Stack trace: $stack');
      return Left(
        Failure.serverFailure(message: 'Failed to retrieve meal history: $e'),
      );
    }
  }

  @override
  Future<Result<MealHistoryEntry>> getMealById({
    required String userId,
    required String mealId,
  }) async {
    try {
      log('🔍 [MEAL HISTORY REPO] Getting meal by ID: $mealId');

      // Try to find in AI meals first
      final aiMealDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('ai_meal_logs')
          .doc(mealId)
          .get();

      if (aiMealDoc.exists) {
        final data = aiMealDoc.data()!;

        // Handle Timestamp conversion for loggedAt
        if (data['loggedAt'] is Timestamp) {
          data['loggedAt'] = (data['loggedAt'] as Timestamp)
              .toDate()
              .toIso8601String();
        }

        // Handle Timestamp in originalAnalysis.analyzedAt if present
        if (data['originalAnalysis'] is Map<String, dynamic>) {
          final originalAnalysis =
              data['originalAnalysis'] as Map<String, dynamic>;
          if (originalAnalysis['analyzedAt'] is Timestamp) {
            originalAnalysis['analyzedAt'] =
                (originalAnalysis['analyzedAt'] as Timestamp)
                    .toDate()
                    .toIso8601String();
          }
        }

        // Ensure ID is set correctly
        data['id'] = mealId;

        final aiMeal = AIMealLog.fromJson(data);
        final historyEntry = MealHistoryEntry.fromAIMeal(
          aiMeal,
        ).copyWith(userId: userId);
        log('✅ [MEAL HISTORY REPO] Found AI meal: $mealId');
        return Right(historyEntry);
      }

      // Try to find in manual meals
      final manualMealDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('loggedMeals')
          .doc(mealId)
          .get();

      if (manualMealDoc.exists) {
        final manualMealData = manualMealDoc.data()!;
        final historyEntry = MealHistoryEntry.fromManualMeal(
          manualMealData,
          mealId,
          userId, // Pass userId here
        );
        log('✅ [MEAL HISTORY REPO] Found manual meal: $mealId');
        return Right(historyEntry);
      }

      log('❌ [MEAL HISTORY REPO] Meal not found: $mealId');
      return Left(Failure.serverFailure(message: 'Meal not found'));
    } catch (e) {
      log('❌ [MEAL HISTORY REPO] Error getting meal by ID: $e');
      return Left(
        Failure.serverFailure(message: 'Failed to retrieve meal: $e'),
      );
    }
  }

  @override
  Future<Result<MealHistoryEntry>> updateMeal({
    required String userId,
    required MealHistoryEntry updatedMeal,
  }) async {
    try {
      log('📝 [MEAL HISTORY REPO] Updating meal: ${updatedMeal.id}');

      if (updatedMeal.source == MealSource.aiAssisted) {
        // Update AI meal log
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('ai_meal_logs')
            .doc(updatedMeal.id)
            .update({
              'editedAt': Timestamp.fromDate(updatedMeal.editedAt!),
              'editCount': updatedMeal.editCount,
              'confirmedItems': updatedMeal.foodItems
                  .map(
                    (item) => {
                      'name': item.name,
                      'quantity': item.quantity,
                      'unit': item.unit,
                      'calories': item.calories,
                      'protein': item.protein,
                      'carbs': item.carbs,
                      'fat': item.fat,
                    },
                  )
                  .toList(),
              'nutritionalEstimate': {
                'calories': updatedMeal.nutrition.calories,
                'protein': updatedMeal.nutrition.protein,
                'carbs': updatedMeal.nutrition.carbs,
                'fat': updatedMeal.nutrition.fat,
                'fiber': updatedMeal.nutrition.fiber,
                'sugar': updatedMeal.nutrition.sugar,
                'sodium': updatedMeal.nutrition.sodium,
              },
            });
      } else {
        // Update manual meal log
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('loggedMeals')
            .doc(updatedMeal.id)
            .update({
              'editedAt': Timestamp.fromDate(updatedMeal.editedAt!),
              'editCount': updatedMeal.editCount,
              'mealType': updatedMeal.mealType,
              'foodItems': updatedMeal.foodItems
                  .map(
                    (item) => {
                      'name': item.name,
                      'quantity': item.quantity,
                      'unit': item.unit,
                      'calories': item.calories,
                      'protein': item.protein,
                      'carbs': item.carbs,
                      'fat': item.fat,
                    },
                  )
                  .toList(),
              'nutrition': {
                'calories': updatedMeal.nutrition.calories,
                'protein': updatedMeal.nutrition.protein,
                'carbs': updatedMeal.nutrition.carbs,
                'fat': updatedMeal.nutrition.fat,
                'fiber': updatedMeal.nutrition.fiber,
                'sugar': updatedMeal.nutrition.sugar,
                'sodium': updatedMeal.nutrition.sodium,
              },
            });
      }

      log('✅ [MEAL HISTORY REPO] Successfully updated meal: ${updatedMeal.id}');
      return Right(updatedMeal);
    } catch (e) {
      log('❌ [MEAL HISTORY REPO] Error updating meal: $e');
      return Left(Failure.serverFailure(message: 'Failed to update meal: $e'));
    }
  }

  @override
  Future<Result<void>> deleteMeal({
    required String userId,
    required String mealId,
  }) async {
    try {
      log('🗑️ [MEAL HISTORY REPO] Deleting meal: $mealId');

      // Try to delete from AI meals first
      final aiMealDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('ai_meal_logs')
          .doc(mealId)
          .get();

      if (aiMealDoc.exists) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('ai_meal_logs')
            .doc(mealId)
            .delete();
        log('✅ [MEAL HISTORY REPO] Deleted AI meal: $mealId');
        return const Right(null);
      }

      // Try to delete from manual meals
      final manualMealDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('loggedMeals')
          .doc(mealId)
          .get();

      if (manualMealDoc.exists) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('loggedMeals')
            .doc(mealId)
            .delete();
        log('✅ [MEAL HISTORY REPO] Deleted manual meal: $mealId');
        return const Right(null);
      }

      log('❌ [MEAL HISTORY REPO] Meal not found for deletion: $mealId');
      return Left(Failure.serverFailure(message: 'Meal not found'));
    } catch (e) {
      log('❌ [MEAL HISTORY REPO] Error deleting meal: $e');
      return Left(Failure.serverFailure(message: 'Failed to delete meal: $e'));
    }
  }

  @override
  Future<Result<NutritionalSummary>> getNutritionalSummary({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      log('📊 [MEAL HISTORY REPO] Getting nutritional summary');

      // Get all meals in the date range
      final filter = MealHistoryFilter(startDate: startDate, endDate: endDate);

      final mealsResult = await getMealHistory(userId: userId, filter: filter);

      if (mealsResult.isFailure) {
        return mealsResult.fold((l) => Left(l), (r) => throw Exception());
      }

      final groupedMeals = mealsResult.successValue!;
      final allMeals = groupedMeals.groupedMeals.values
          .expand((m) => m)
          .toList();

      if (allMeals.isEmpty) {
        log('✅ [MEAL HISTORY REPO] No meals found in date range');
        return Right(
          const NutritionalSummary(calories: 0, protein: 0, carbs: 0, fat: 0),
        );
      }

      // Calculate totals
      int totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;
      double? totalFiber;
      double? totalSugar;
      double? totalSodium;

      for (final meal in allMeals) {
        totalCalories += meal.nutrition.calories;
        totalProtein += meal.nutrition.protein;
        totalCarbs += meal.nutrition.carbs;
        totalFat += meal.nutrition.fat;

        // Optional nutrients - only add if all meals have them
        if (meal.nutrition.fiber != null) {
          totalFiber = (totalFiber ?? 0) + meal.nutrition.fiber!;
        }
        if (meal.nutrition.sugar != null) {
          totalSugar = (totalSugar ?? 0) + meal.nutrition.sugar!;
        }
        if (meal.nutrition.sodium != null) {
          totalSodium = (totalSodium ?? 0) + meal.nutrition.sodium!;
        }
      }

      log('✅ [MEAL HISTORY REPO] Calculated nutritional summary');
      return Right(
        NutritionalSummary(
          calories: totalCalories,
          protein: totalProtein,
          carbs: totalCarbs,
          fat: totalFat,
          fiber: totalFiber,
          sugar: totalSugar,
          sodium: totalSodium,
        ),
      );
    } catch (e) {
      log('❌ [MEAL HISTORY REPO] Error getting nutritional summary: $e');
      return Left(
        Failure.serverFailure(
          message: 'Failed to calculate nutritional summary: $e',
        ),
      );
    }
  }

  @override
  Future<Result<List<MealHistoryEntry>>> searchMealHistory({
    required String userId,
    required String searchQuery,
    int? limit,
  }) async {
    try {
      log('🔍 [MEAL HISTORY REPO] Searching meals with query: $searchQuery');

      // Get all meals first
      final mealsResult = await getMealHistory(userId: userId);
      if (mealsResult.isFailure) {
        return mealsResult.fold((l) => Left(l), (r) => throw Exception());
      }

      final groupedMeals = mealsResult.successValue!;
      final allMeals = groupedMeals.groupedMeals.values
          .expand((m) => m)
          .toList();

      // Filter meals by search query
      final filteredMeals = allMeals.where((meal) {
        // Search in meal description/notes
        if (meal.description != null &&
            meal.description!.toLowerCase().contains(
              searchQuery.toLowerCase(),
            )) {
          return true;
        }
        if (meal.notes != null &&
            meal.notes!.toLowerCase().contains(searchQuery.toLowerCase())) {
          return true;
        }

        // Search in food items
        for (final item in meal.foodItems) {
          if (item.name.toLowerCase().contains(searchQuery.toLowerCase())) {
            return true;
          }
        }

        return false;
      }).toList();

      // Apply limit if provided
      final limitedMeals = limit != null && limit > 0
          ? filteredMeals.take(limit).toList()
          : filteredMeals;

      log('✅ [MEAL HISTORY REPO] Found ${limitedMeals.length} matching meals');
      return Right(limitedMeals);
    } catch (e) {
      log('❌ [MEAL HISTORY REPO] Error searching meals: $e');
      return Left(Failure.serverFailure(message: 'Failed to search meals: $e'));
    }
  }

  @override
  Future<Result<List<MealHistoryEntry>>> getRecentMeals({
    required String userId,
    int limit = 10,
  }) async {
    try {
      log('⏰ [MEAL HISTORY REPO] Getting $limit recent meals');

      final historyResult = await getMealHistory(userId: userId);
      if (historyResult.isFailure) {
        return historyResult.fold((l) => Left(l), (r) => throw Exception());
      }

      final groupedHistory = historyResult.successValue!;
      final allMeals = groupedHistory.groupedMeals.values
          .expand((meals) => meals)
          .toList();

      // Sort by logged date (newest first) and take limit
      allMeals.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
      final recentMeals = allMeals.take(limit).toList();

      log('✅ [MEAL HISTORY REPO] Retrieved ${recentMeals.length} recent meals');
      return Right(recentMeals);
    } catch (e) {
      log('❌ [MEAL HISTORY REPO] Error getting recent meals: $e');
      return Left(
        Failure.serverFailure(message: 'Failed to get recent meals: $e'),
      );
    }
  }

  /// Helper method to get AI meals from Firestore
  Future<Result<List<MealHistoryEntry>>> _getAIMeals(
    String userId,
    MealHistoryFilter? filter,
  ) async {
    try {
      log('🔄 [MEAL HISTORY REPO] Getting AI meals for user: $userId');

      Query query = _firestore
          .collection('users')
          .doc(userId)
          .collection('ai_meal_logs');

      log('🔍 [MEAL HISTORY REPO] Initial AI query path: ${query.toString()}');

      // Apply date filters - now we don't need userId filter since it's implicit in subcollection
      if (filter?.startDate != null) {
        log(
          '📅 [MEAL HISTORY REPO] Adding start date filter: ${filter!.startDate!}',
        );
        query = query.where(
          'loggedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(filter.startDate!),
        );
      }
      if (filter?.endDate != null) {
        log(
          '📅 [MEAL HISTORY REPO] Adding end date filter: ${filter!.endDate!}',
        );
        query = query.where(
          'loggedAt',
          isLessThanOrEqualTo: Timestamp.fromDate(filter.endDate!),
        );
      }

      log('🔍 [MEAL HISTORY REPO] Executing AI meals query');
      final snapshot = await query.get();
      log(
        '📊 [MEAL HISTORY REPO] Found ${snapshot.docs.length} AI meal documents',
      );

      final aiMeals = <MealHistoryEntry>[];

      for (final doc in snapshot.docs) {
        try {
          log('🔄 [MEAL HISTORY REPO] Processing AI meal document: ${doc.id}');
          log(
            '📄 [MEAL HISTORY REPO] Document data exists: ${doc.exists}, data: ${doc.data()}',
          );

          // Manual conversion to handle Timestamp
          final data = doc.data() as Map<String, dynamic>;
          final id = doc.id;

          // Handle Timestamp conversion for loggedAt
          DateTime loggedAt;
          if (data['loggedAt'] is Timestamp) {
            loggedAt = (data['loggedAt'] as Timestamp).toDate();
            // Create a copy of the data with loggedAt as an ISO string
            data['loggedAt'] = loggedAt.toIso8601String();
          } else if (data['loggedAt'] is String) {
            loggedAt = DateTime.parse(data['loggedAt'] as String);
          } else {
            log(
              '⚠️ [MEAL HISTORY REPO] Invalid loggedAt format in AI meal ${doc.id}',
            );
            continue;
          }

          // Handle Timestamp in originalAnalysis.analyzedAt if present
          if (data['originalAnalysis'] is Map<String, dynamic>) {
            final originalAnalysis =
                data['originalAnalysis'] as Map<String, dynamic>;
            if (originalAnalysis['analyzedAt'] is Timestamp) {
              originalAnalysis['analyzedAt'] =
                  (originalAnalysis['analyzedAt'] as Timestamp)
                      .toDate()
                      .toIso8601String();
            }
          }

          // Ensure ID is set correctly
          data['id'] = id;

          final aiMeal = AIMealLog.fromJson(data);
          log(
            '✅ [MEAL HISTORY REPO] Successfully parsed AIMealLog: ${aiMeal.id}, logged at: ${aiMeal.loggedAt}',
          );

          // Apply meal type filter
          if (filter?.mealTypes != null &&
              !filter!.mealTypes!.contains(aiMeal.mealType)) {
            log('⏭️ [MEAL HISTORY REPO] Skipping due to meal type filter');
            continue;
          }

          final historyEntry = MealHistoryEntry.fromAIMeal(
            aiMeal,
          ).copyWith(userId: userId);
          log(
            '✅ [MEAL HISTORY REPO] Created history entry for AI meal: ${historyEntry.id}',
          );
          aiMeals.add(historyEntry);
        } catch (e, stack) {
          log('⚠️ [MEAL HISTORY REPO] Error parsing AI meal ${doc.id}: $e');
          log('⚠️ [MEAL HISTORY REPO] Stack trace: $stack');
          // Continue with other meals
        }
      }

      log(
        '📊 [MEAL HISTORY REPO] Total AI meals after filtering: ${aiMeals.length}',
      );
      return Right(aiMeals);
    } catch (e, stack) {
      log('❌ [MEAL HISTORY REPO] Error getting AI meals: $e');
      log('❌ [MEAL HISTORY REPO] Stack trace: $stack');
      return Left(Failure.serverFailure(message: 'Failed to get AI meals: $e'));
    }
  }

  /// Helper method to get manual meals from Firestore
  Future<Result<List<MealHistoryEntry>>> _getManualMeals(
    String userId,
    MealHistoryFilter? filter,
  ) async {
    try {
      log('🔄 [MEAL HISTORY REPO] Getting manual meals for user: $userId');

      Query query = _firestore
          .collection('users')
          .doc(userId)
          .collection('loggedMeals');

      log(
        '🔍 [MEAL HISTORY REPO] Initial manual meals query path: ${query.toString()}',
      );

      if (filter != null) {
        if (filter.startDate != null) {
          log(
            '📅 [MEAL HISTORY REPO] Adding start date filter: ${filter.startDate!}',
          );
          query = query.where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(filter.startDate!),
          );
        }
        if (filter.endDate != null) {
          // Adjust endDate to include the whole day
          final endOfDay = DateTime(
            filter.endDate!.year,
            filter.endDate!.month,
            filter.endDate!.day,
            23,
            59,
            59,
          );
          log('📅 [MEAL HISTORY REPO] Adding end date filter: $endOfDay');
          query = query.where(
            'timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
          );
        }
        if (filter.mealTypes != null && filter.mealTypes!.isNotEmpty) {
          log(
            '🍽️ [MEAL HISTORY REPO] Adding meal type filter: ${filter.mealTypes}',
          );
          query = query.where('mealType', whereIn: filter.mealTypes);
        }
        // Note: Manual meals don't have a 'source' field to filter by directly.
        // They are implicitly MealSource.manual.
        // Search query for manual meals might need specific field targeting if desired.
        // For now, search query is not applied to manual meals in this example.
      }

      log('🔍 [MEAL HISTORY REPO] Executing manual meals query');
      final snapshot = await query.get();
      log(
        '📊 [MEAL HISTORY REPO] Found ${snapshot.docs.length} manual meal documents',
      );

      final meals = <MealHistoryEntry>[];

      for (final doc in snapshot.docs) {
        try {
          log(
            '🔄 [MEAL HISTORY REPO] Processing manual meal document: ${doc.id}',
          );
          final mealEntry = MealHistoryEntry.fromManualMeal(
            doc.data() as Map<String, dynamic>,
            doc.id,
            userId, // Pass userId here
          );
          log(
            '✅ [MEAL HISTORY REPO] Created history entry for manual meal: ${mealEntry.id}',
          );
          meals.add(mealEntry);
        } catch (e, stack) {
          log('⚠️ [MEAL HISTORY REPO] Error parsing manual meal ${doc.id}: $e');
          log('⚠️ [MEAL HISTORY REPO] Stack trace: $stack');
          // Continue with other meals
        }
      }

      log(
        '📊 [MEAL HISTORY REPO] Total manual meals after processing: ${meals.length}',
      );
      return Right(meals);
    } catch (e, stack) {
      log('❌ [MEAL HISTORY REPO] Error getting manual meals: $e');
      log('❌ [MEAL HISTORY REPO] Stack trace: $stack');
      return Left(
        Failure.serverFailure(message: 'Failed to retrieve manual meals: $e'),
      );
    }
  }

  /// Helper method to group meals by date
  GroupedMealHistory _groupMealsByDate(List<MealHistoryEntry> meals) {
    final groupedMeals = <DateTime, List<MealHistoryEntry>>{};

    for (final meal in meals) {
      final dateKey = DateTime(
        meal.loggedAt.year,
        meal.loggedAt.month,
        meal.loggedAt.day,
      );

      if (groupedMeals.containsKey(dateKey)) {
        groupedMeals[dateKey]!.add(meal);
      } else {
        groupedMeals[dateKey] = [meal];
      }
    }

    // Sort meals within each day by logged time
    groupedMeals.forEach((date, meals) {
      meals.sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    });

    return GroupedMealHistory(
      groupedMeals: groupedMeals,
      totalMeals: meals.length,
    );
  }
}
