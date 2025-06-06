import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutrivision/core/providers/auth_providers.dart';
import 'package:nutrivision/core/providers/firebase_providers.dart';
import 'package:nutrivision/features/advanced_meal_mgmt/domain/entities/nutrition_goals.dart';
import 'package:nutrivision/core/models/meal_models.dart';

// Provider for recent meals on the dashboard
final recentMealsProvider = FutureProvider.autoDispose<List<MealHistoryEntry>>((
  ref,
) async {
  final userId = ref.watch(currentUserIdProvider);
  final firestore = ref.read(firebaseFirestoreProvider);

  try {
    // Get the most recent meals
    final recentMealsSnapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('loggedMeals')
        .orderBy('timestamp', descending: true)
        .limit(5)
        .get();

    List<MealHistoryEntry> recentMeals = [];

    for (var doc in recentMealsSnapshot.docs) {
      Map<String, dynamic> data = doc.data();
      try {
        // Convert Firestore data to meal history entry
        final mealType = data['mealType'] ?? 'meal';
        final timestamp = data['timestamp'] as Timestamp?;

        if (timestamp == null) continue;

        recentMeals.add(
          MealHistoryEntry(
            id: doc.id,
            userId: userId,
            loggedAt: timestamp.toDate(),
            mealType: mealType,
            source: MealSource.manual,
            foodItems: [],
            nutrition: NutritionalSummary(
              calories: (data['calories'] as num?)?.toInt() ?? 0,
              protein: (data['proteinGrams'] as num?)?.toDouble() ?? 0.0,
              carbs: (data['carbsGrams'] as num?)?.toDouble() ?? 0.0,
              fat: (data['fatGrams'] as num?)?.toDouble() ?? 0.0,
            ),
            description: data['mealName'] ?? 'Unnamed Meal',
          ),
        );
      } catch (e) {
        print('Error parsing meal data: $e');
      }
    }

    return recentMeals;
  } catch (e) {
    print('Error loading recent meals: $e');
    return [];
  }
});

// Provider for favorite meals on the dashboard
final favoriteMealsProvider = FutureProvider.autoDispose<List<FavoriteMeal>>((
  ref,
) async {
  final userId = ref.watch(currentUserIdProvider);
  final firestore = ref.read(firebaseFirestoreProvider);

  try {
    // Get user's favorite meals
    final favoriteMealsSnapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('favoriteMeals')
        .orderBy('useCount', descending: true)
        .limit(5)
        .get();

    List<FavoriteMeal> favoriteMeals = [];

    for (var doc in favoriteMealsSnapshot.docs) {
      Map<String, dynamic> data = doc.data();
      try {
        // Create favorite meal from snapshot
        final createdAtTimestamp = data['createdAt'] as Timestamp?;
        final lastUsedTimestamp = data['lastUsed'] as Timestamp?;

        favoriteMeals.add(
          FavoriteMeal(
            id: doc.id,
            userId: userId,
            name: data['name'] ?? 'Unnamed Meal',
            foodItems:
                [], // We don't need detailed food items for dashboard preview
            nutrition: NutritionalSummary(
              calories: (data['nutrition']?['calories'] as num?)?.toInt() ?? 0,
              protein:
                  (data['nutrition']?['protein'] as num?)?.toDouble() ?? 0.0,
              carbs: (data['nutrition']?['carbs'] as num?)?.toDouble() ?? 0.0,
              fat: (data['nutrition']?['fat'] as num?)?.toDouble() ?? 0.0,
            ),
            mealType: data['mealType'] ?? 'meal',
            imageUrl: data['imageUrl'],
            notes: data['notes'],
            createdAt: createdAtTimestamp?.toDate() ?? DateTime.now(),
            lastUsed: lastUsedTimestamp?.toDate(),
            useCount: (data['useCount'] as num?)?.toInt() ?? 0,
          ),
        );
      } catch (e) {
        print('Error parsing favorite meal data: $e');
      }
    }

    return favoriteMeals;
  } catch (e) {
    print('Error loading favorite meals: $e');
    return [];
  }
});
