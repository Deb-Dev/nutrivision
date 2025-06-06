import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrivision/core/providers/firebase_providers.dart';
import '../../domain/models/daily_nutrition.dart';

class NutritionHistoryService {
  final FirebaseFirestore _firestore;

  NutritionHistoryService(this._firestore);

  Future<List<DailyNutrition>> getWeeklyNutrition(String userId) async {
    // Calculate the dates for the last 7 days
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(
      const Duration(days: 6),
    ); // To get 7 days including today

    final weekDays = List<DateTime>.generate(
      7,
      (i) => weekAgo.add(Duration(days: i)),
    );

    // Create a map with default values for each day
    final Map<String, DailyNutrition> dailyData = {};

    for (var date in weekDays) {
      final dateString = _formatDateForKey(date);
      dailyData[dateString] = DailyNutrition(
        date: date,
        caloriesConsumed: 0,
        proteinConsumed: 0,
        carbsConsumed: 0,
        fatConsumed: 0,
        caloriesTarget: 2000, // Default values
        proteinTarget: 150,
        carbsTarget: 200,
        fatTarget: 70,
      );
    }

    try {
      // Get user profile for targets
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;

        // Extract target values
        final targetCalories =
            (userData['targetCalories'] as num?)?.toDouble() ?? 2000;
        final targetProtein =
            (userData['targetProteinGrams'] as num?)?.toDouble() ?? 150;
        final targetCarbs =
            (userData['targetCarbsGrams'] as num?)?.toDouble() ?? 200;
        final targetFat =
            (userData['targetFatGrams'] as num?)?.toDouble() ?? 70;

        // Update targets for each day
        dailyData.forEach((key, value) {
          dailyData[key] = DailyNutrition(
            date: value.date,
            caloriesConsumed: value.caloriesConsumed,
            proteinConsumed: value.proteinConsumed,
            carbsConsumed: value.carbsConsumed,
            fatConsumed: value.fatConsumed,
            caloriesTarget: targetCalories,
            proteinTarget: targetProtein,
            carbsTarget: targetCarbs,
            fatTarget: targetFat,
          );
        });
      }

      // Get logged meals for the past week
      final mealsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('loggedMeals')
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo),
          )
          .where(
            'timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(
              today.add(const Duration(days: 1)),
            ),
          )
          .get();

      // Process each meal
      for (var doc in mealsSnapshot.docs) {
        final data = doc.data();
        final timestamp = data['timestamp'] as Timestamp?;

        if (timestamp != null) {
          final mealDate = timestamp.toDate();
          final dateKey = _formatDateForKey(mealDate);

          if (dailyData.containsKey(dateKey)) {
            final currentData = dailyData[dateKey]!;

            // Sum nutrition data
            final calories = (data['calories'] as num?)?.toDouble() ?? 0;
            final protein = (data['proteinGrams'] as num?)?.toDouble() ?? 0;
            final carbs = (data['carbsGrams'] as num?)?.toDouble() ?? 0;
            final fat = (data['fatGrams'] as num?)?.toDouble() ?? 0;

            dailyData[dateKey] = DailyNutrition(
              date: currentData.date,
              caloriesConsumed: currentData.caloriesConsumed + calories,
              proteinConsumed: currentData.proteinConsumed + protein,
              carbsConsumed: currentData.carbsConsumed + carbs,
              fatConsumed: currentData.fatConsumed + fat,
              caloriesTarget: currentData.caloriesTarget,
              proteinTarget: currentData.proteinTarget,
              carbsTarget: currentData.carbsTarget,
              fatTarget: currentData.fatTarget,
            );
          }
        }
      }

      // Convert map to ordered list
      return weekDays
          .map((date) => dailyData[_formatDateForKey(date)]!)
          .toList();
    } catch (e) {
      print('Error fetching weekly nutrition: $e');

      // Return default data if there's an error
      return weekDays
          .map(
            (date) => DailyNutrition(
              date: date,
              caloriesConsumed: 0,
              proteinConsumed: 0,
              carbsConsumed: 0,
              fatConsumed: 0,
              caloriesTarget: 2000,
              proteinTarget: 150,
              carbsTarget: 200,
              fatTarget: 70,
            ),
          )
          .toList();
    }
  }

  // Helper method to format date as YYYY-MM-DD for map keys
  String _formatDateForKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

// Provider for the nutrition history service
final nutritionHistoryServiceProvider = Provider<NutritionHistoryService>((
  ref,
) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return NutritionHistoryService(firestore);
});

// Provider for weekly nutrition data
final weeklyNutritionProvider =
    FutureProvider.family<List<DailyNutrition>, String>((ref, userId) async {
      final service = ref.watch(nutritionHistoryServiceProvider);
      return service.getWeeklyNutrition(userId);
    });

// Provider for the selected day index (default to the last day - today)
final selectedDayIndexProvider = StateProvider<int>(
  (ref) => 6,
); // Default to today (index 6)
