import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/nutrition_goals.dart';
import '../../domain/repositories/favorite_meals_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';

/// Implementation of FavoriteMealsRepository
@LazySingleton(as: FavoriteMealsRepository)
class FavoriteMealsRepositoryImpl implements FavoriteMealsRepository {
  final FirebaseFirestore _firestore;

  const FavoriteMealsRepositoryImpl(this._firestore);

  @override
  Future<Result<FavoriteMeal>> createFavoriteMeal({
    required String userId,
    required String name,
    required List<FavoriteFoodItem> foodItems,
    required NutritionalSummary nutrition,
    required String mealType,
    String? imageUrl,
    String? notes,
  }) async {
    try {
      log('📝 [FAVORITE MEALS REPO] Creating new favorite meal: $name');

      final mealData = {
        'userId': userId,
        'name': name,
        'foodItems': foodItems.map((item) => item.toJson()).toList(),
        'nutrition': nutrition.toJson(),
        'mealType': mealType,
        'imageUrl': imageUrl,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUsed': null,
        'useCount': 0,
      };

      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorite_meals')
          .add(mealData);

      log(
        '✅ [FAVORITE MEALS REPO] Favorite meal created with ID: ${docRef.id}',
      );

      // Return FavoriteMeal with the new ID
      return Right(
        FavoriteMeal(
          id: docRef.id,
          userId: userId,
          name: name,
          foodItems: foodItems,
          nutrition: nutrition,
          mealType: mealType,
          imageUrl: imageUrl,
          notes: notes,
          createdAt: DateTime.now(),
          lastUsed: null,
          useCount: 0,
        ),
      );
    } catch (e) {
      log('❌ [FAVORITE MEALS REPO] Error creating favorite meal: $e');
      return Left(
        Failure.serverFailure(message: 'Failed to create favorite meal: $e'),
      );
    }
  }

  @override
  Future<Result<List<FavoriteMeal>>> getFavoriteMeals({
    required String userId,
  }) async {
    try {
      log('🔍 [FAVORITE MEALS REPO] Getting favorite meals for user: $userId');

      final query = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorite_meals')
          .orderBy('useCount', descending: true) // Most used first
          .get();

      final favoriteMeals = <FavoriteMeal>[];

      for (final doc in query.docs) {
        try {
          final data = doc.data();

          // Parse food items
          final foodItemsList = (data['foodItems'] as List<dynamic>)
              .map(
                (item) => FavoriteFoodItem.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList();

          // Parse nutrition
          final nutritionData = Map<String, dynamic>.from(
            data['nutrition'] as Map,
          );
          final nutrition = NutritionalSummary.fromJson(nutritionData);

          // Parse timestamps
          final createdAt = data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now();

          final lastUsed = data['lastUsed'] is Timestamp
              ? (data['lastUsed'] as Timestamp).toDate()
              : null;

          favoriteMeals.add(
            FavoriteMeal(
              id: doc.id,
              userId: data['userId'] as String,
              name: data['name'] as String,
              foodItems: foodItemsList,
              nutrition: nutrition,
              mealType: data['mealType'] as String,
              imageUrl: data['imageUrl'] as String?,
              notes: data['notes'] as String?,
              createdAt: createdAt,
              lastUsed: lastUsed,
              useCount: (data['useCount'] as num).toInt(),
            ),
          );
        } catch (e) {
          log('⚠️ [FAVORITE MEALS REPO] Error parsing meal ${doc.id}: $e');
        }
      }

      log(
        '✅ [FAVORITE MEALS REPO] Retrieved ${favoriteMeals.length} favorite meals',
      );
      return Right(favoriteMeals);
    } catch (e) {
      log('❌ [FAVORITE MEALS REPO] Error getting favorite meals: $e');
      return Left(
        Failure.serverFailure(message: 'Failed to retrieve favorite meals: $e'),
      );
    }
  }

  @override
  Future<Result<FavoriteMeal>> getFavoriteMealById({
    required String userId,
    required String favoriteMealId,
  }) async {
    try {
      log(
        '🔍 [FAVORITE MEALS REPO] Getting favorite meal by ID: $favoriteMealId',
      );

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorite_meals')
          .doc(favoriteMealId)
          .get();

      if (!doc.exists) {
        log('❌ [FAVORITE MEALS REPO] Favorite meal not found: $favoriteMealId');
        return Left(Failure.serverFailure(message: 'Favorite meal not found'));
      }

      final data = doc.data()!;

      // Parse food items
      final foodItemsList = (data['foodItems'] as List<dynamic>)
          .map(
            (item) => FavoriteFoodItem.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();

      // Parse nutrition
      final nutritionData = Map<String, dynamic>.from(data['nutrition'] as Map);
      final nutrition = NutritionalSummary.fromJson(nutritionData);

      // Parse timestamps
      final createdAt = data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now();

      final lastUsed = data['lastUsed'] is Timestamp
          ? (data['lastUsed'] as Timestamp).toDate()
          : null;

      final favoriteMeal = FavoriteMeal(
        id: doc.id,
        userId: data['userId'] as String,
        name: data['name'] as String,
        foodItems: foodItemsList,
        nutrition: nutrition,
        mealType: data['mealType'] as String,
        imageUrl: data['imageUrl'] as String?,
        notes: data['notes'] as String?,
        createdAt: createdAt,
        lastUsed: lastUsed,
        useCount: (data['useCount'] as num).toInt(),
      );

      log(
        '✅ [FAVORITE MEALS REPO] Retrieved favorite meal: ${favoriteMeal.id}',
      );
      return Right(favoriteMeal);
    } catch (e) {
      log('❌ [FAVORITE MEALS REPO] Error getting favorite meal: $e');
      return Left(
        Failure.serverFailure(message: 'Failed to retrieve favorite meal: $e'),
      );
    }
  }

  @override
  Future<Result<FavoriteMeal>> updateFavoriteMeal({
    required String userId,
    required FavoriteMeal updatedMeal,
  }) async {
    try {
      log('📝 [FAVORITE MEALS REPO] Updating favorite meal: ${updatedMeal.id}');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorite_meals')
          .doc(updatedMeal.id)
          .update({
            'name': updatedMeal.name,
            'foodItems': updatedMeal.foodItems
                .map((item) => item.toJson())
                .toList(),
            'nutrition': updatedMeal.nutrition.toJson(),
            'mealType': updatedMeal.mealType,
            'imageUrl': updatedMeal.imageUrl,
            'notes': updatedMeal.notes,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      log('✅ [FAVORITE MEALS REPO] Updated favorite meal: ${updatedMeal.id}');
      return Right(updatedMeal);
    } catch (e) {
      log('❌ [FAVORITE MEALS REPO] Error updating favorite meal: $e');
      return Left(
        Failure.serverFailure(message: 'Failed to update favorite meal: $e'),
      );
    }
  }

  @override
  Future<Result<void>> deleteFavoriteMeal({
    required String userId,
    required String favoriteMealId,
  }) async {
    try {
      log('🗑️ [FAVORITE MEALS REPO] Deleting favorite meal: $favoriteMealId');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorite_meals')
          .doc(favoriteMealId)
          .delete();

      log('✅ [FAVORITE MEALS REPO] Deleted favorite meal: $favoriteMealId');
      return const Right(null);
    } catch (e) {
      log('❌ [FAVORITE MEALS REPO] Error deleting favorite meal: $e');
      return Left(
        Failure.serverFailure(message: 'Failed to delete favorite meal: $e'),
      );
    }
  }

  @override
  Future<Result<String>> logFavoriteMeal({
    required String userId,
    required String favoriteMealId,
    required DateTime loggedAt,
    String? notes,
  }) async {
    try {
      log('📝 [FAVORITE MEALS REPO] Logging favorite meal: $favoriteMealId');

      // Get the favorite meal
      final mealResult = await getFavoriteMealById(
        userId: userId,
        favoriteMealId: favoriteMealId,
      );

      if (mealResult.isFailure) {
        return mealResult.fold(
          (failure) => Left(failure),
          (_) => throw Exception('Unreachable'),
        );
      }

      final favoriteMeal = mealResult.successValue!;

      // Create logged meal data
      final mealData = {
        'userId': userId,
        'favoriteId': favoriteMealId,
        'foodItems': favoriteMeal.foodItems
            .map(
              (item) => {
                'name': item.name,
                'quantity': item.quantity,
                'unit': item.unit,
                'calories': item.calories,
                'protein': item.protein,
                'carbs': item.carbs,
                'fat': item.fat,
                'fiber': item.fiber,
                'sugar': item.sugar,
                'sodium': item.sodium,
                'foodId': item.foodId,
              },
            )
            .toList(),
        // Store nutrition data in both formats for compatibility:
        // 1. As a nested object for future compatibility
        'nutrition': {
          'calories': favoriteMeal.nutrition.calories,
          'protein': favoriteMeal.nutrition.protein,
          'carbs': favoriteMeal.nutrition.carbs,
          'fat': favoriteMeal.nutrition.fat,
          'fiber': favoriteMeal.nutrition.fiber,
          'sugar': favoriteMeal.nutrition.sugar,
          'sodium': favoriteMeal.nutrition.sodium,
        },
        // 2. As flat fields for compatibility with MealHistoryEntry.fromManualMeal
        'calories': favoriteMeal.nutrition.calories,
        'proteinGrams': favoriteMeal.nutrition.protein,
        'carbsGrams': favoriteMeal.nutrition.carbs,
        'fatGrams': favoriteMeal.nutrition.fat,
        'mealType': favoriteMeal.mealType,
        'loggedAt': Timestamp.fromDate(loggedAt),
        'timestamp': Timestamp.fromDate(loggedAt), // Add timestamp field for compatibility with meal history
        'notes': notes ?? favoriteMeal.notes,
        'source': 'favorite',
        'createdAt': FieldValue.serverTimestamp(),
        'description': favoriteMeal.name, // Add explicit description for the meal name
        'name': favoriteMeal.name, // Add name field for compatibility
      };

      // Log the meal to the user's loggedMeals collection
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('loggedMeals')
          .add(mealData);

      // Update the favorite meal's usage statistics
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorite_meals')
          .doc(favoriteMealId)
          .update({
            'lastUsed': Timestamp.fromDate(DateTime.now()),
            'useCount': FieldValue.increment(1),
          });

      log('✅ [FAVORITE MEALS REPO] Logged favorite meal with ID: ${docRef.id}');
      return Right(docRef.id);
    } catch (e) {
      log('❌ [FAVORITE MEALS REPO] Error logging favorite meal: $e');
      return Left(
        Failure.serverFailure(message: 'Failed to log favorite meal: $e'),
      );
    }
  }

  @override
  Future<Result<List<FavoriteMeal>>> getMostUsedFavoriteMeals({
    required String userId,
    required int limit,
  }) async {
    try {
      log(
        '🔍 [FAVORITE MEALS REPO] Getting most used favorite meals for user: $userId',
      );

      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorite_meals')
          .orderBy('useCount', descending: true)
          .limit(limit)
          .get();

      final meals = querySnapshot.docs
          .map((doc) => FavoriteMeal.fromJson({'id': doc.id, ...doc.data()}))
          .toList();

      log(
        '✅ [FAVORITE MEALS REPO] Found ${meals.length} most used favorite meals',
      );
      return Right(meals);
    } catch (e) {
      log('❌ [FAVORITE MEALS REPO] Error getting most used favorite meals: $e');
      return Left(
        Failure.serverFailure(
          message: 'Failed to get most used favorite meals: $e',
        ),
      );
    }
  }

  @override
  Future<Result<List<FavoriteMeal>>> searchFavoriteMeals({
    required String userId,
    required String searchQuery,
  }) async {
    try {
      log(
        '🔍 [FAVORITE MEALS REPO] Searching favorite meals for user: $userId, query: $searchQuery',
      );

      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorite_meals')
          .where('name', isGreaterThanOrEqualTo: searchQuery)
          .where('name', isLessThanOrEqualTo: '$searchQuery\uf8ff')
          .get();

      final meals = querySnapshot.docs
          .map((doc) => FavoriteMeal.fromJson({'id': doc.id, ...doc.data()}))
          .toList();

      log(
        '✅ [FAVORITE MEALS REPO] Found ${meals.length} favorite meals matching search',
      );
      return Right(meals);
    } catch (e) {
      log('❌ [FAVORITE MEALS REPO] Error searching favorite meals: $e');
      return Left(
        Failure.serverFailure(message: 'Failed to search favorite meals: $e'),
      );
    }
  }
}
