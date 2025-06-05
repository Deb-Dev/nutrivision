import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/nutrition_goals.dart';
import '../../domain/repositories/nutrition_analytics_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';

/// Implementation of NutritionAnalyticsRepository
@LazySingleton(as: NutritionAnalyticsRepository)
class NutritionAnalyticsRepositoryImpl implements NutritionAnalyticsRepository {
  final FirebaseFirestore _firestore;

  const NutritionAnalyticsRepositoryImpl(this._firestore);

  @override
  Future<Result<NutritionReport>> generateNutritionReport({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    required AnalyticsPeriod period,
  }) async {
    try {
      log('📊 [NUTRITION ANALYTICS REPO] Generating report for user: $userId');
      log(
        '📅 [NUTRITION ANALYTICS REPO] Period: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}',
      );

      // Get daily nutrition data
      final dailyDataResult = await getDailyNutritionData(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      if (dailyDataResult.isFailure) {
        return dailyDataResult.fold(
          (failure) => Left(failure),
          (_) => throw Exception('Unreachable'),
        );
      }

      final dailyData = dailyDataResult.successValue!;

      if (dailyData.isEmpty) {
        log('⚠️ [NUTRITION ANALYTICS REPO] No nutrition data found');
        return Left(
          Failure.serverFailure(
            message: 'No nutrition data found for the selected period',
          ),
        );
      }

      // Get meal type distribution
      final distributionResult = await getMealTypeDistribution(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      if (distributionResult.isFailure) {
        return distributionResult.fold(
          (failure) => Left(failure),
          (_) => throw Exception('Unreachable'),
        );
      }

      final mealTypeDistribution = distributionResult.successValue!;

      // Get top foods
      final topFoodsResult = await getTopFoods(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      if (topFoodsResult.isFailure) {
        return topFoodsResult.fold(
          (failure) => Left(failure),
          (_) => throw Exception('Unreachable'),
        );
      }

      final topFoods = topFoodsResult.successValue!;

      // Calculate average nutrition
      final averageNutrition = _calculateAverageNutrition(dailyData);

      final nutritionReport = NutritionReport(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
        period: period,
        dailyNutrition: dailyData,
        averageNutrition: averageNutrition,
        mealTypeDistribution: mealTypeDistribution,
        topFoods: topFoods.map((food) => food.name).toList(),
      );

      log('✅ [NUTRITION ANALYTICS REPO] Report generated successfully');
      return Right(nutritionReport);
    } catch (e) {
      log('❌ [NUTRITION ANALYTICS REPO] Error generating report: $e');
      return Left(
        Failure.serverFailure(
          message: 'Failed to generate nutrition report: $e',
        ),
      );
    }
  }

  @override
  Future<Result<List<DailyNutrition>>> getDailyNutritionData({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      log('📊 [NUTRITION ANALYTICS REPO] Getting daily nutrition data');

      // Create a map to store nutrition by date
      final nutritionByDate = <DateTime, DailyNutrition>{};

      // Initialize each day in the range
      for (int i = 0; i <= endDate.difference(startDate).inDays; i++) {
        final date = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
        ).add(Duration(days: i));

        nutritionByDate[date] = DailyNutrition(
          date: date,
          calories: 0,
          protein: 0,
          carbs: 0,
          fat: 0,
          mealCount: 0,
        );
      }

      // Get all meals in the date range (both AI and manual)
      final meals = await _getMealsInDateRange(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      // Aggregate nutrition by date
      for (final meal in meals) {
        final timestamp = meal['loggedAt'] is Timestamp
            ? (meal['loggedAt'] as Timestamp).toDate()
            : (meal['timestamp'] as Timestamp).toDate();

        final dateKey = DateTime(
          timestamp.year,
          timestamp.month,
          timestamp.day,
        );

        if (!nutritionByDate.containsKey(dateKey)) {
          // Skip meals outside our initialized range
          continue;
        }

        final existingData = nutritionByDate[dateKey]!;
        int calories = existingData.calories;
        double protein = existingData.protein;
        double carbs = existingData.carbs;
        double fat = existingData.fat;
        int mealCount = existingData.mealCount ?? 0;

        // Add nutrition from this meal
        if (meal.containsKey('calories')) {
          // Manual meal
          calories += (meal['calories'] as num).toInt();
          protein += (meal['proteinGrams'] as num).toDouble();
          carbs += (meal['carbsGrams'] as num).toDouble();
          fat += (meal['fatGrams'] as num).toDouble();
        } else if (meal.containsKey('nutrition')) {
          // AI meal or newer format
          calories += (meal['nutrition']['calories'] as num).toInt();
          protein += (meal['nutrition']['protein'] as num).toDouble();
          carbs += (meal['nutrition']['carbs'] as num).toDouble();
          fat += (meal['nutrition']['fat'] as num).toDouble();
        }

        mealCount += 1;

        nutritionByDate[dateKey] = DailyNutrition(
          date: dateKey,
          calories: calories,
          protein: protein,
          carbs: carbs,
          fat: fat,
          mealCount: mealCount,
        );
      }

      // Convert map to sorted list
      final result = nutritionByDate.values.toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      log(
        '✅ [NUTRITION ANALYTICS REPO] Retrieved daily nutrition data for ${result.length} days',
      );
      return Right(result);
    } catch (e) {
      log('❌ [NUTRITION ANALYTICS REPO] Error getting daily nutrition: $e');
      return Left(
        Failure.serverFailure(
          message: 'Failed to retrieve daily nutrition data: $e',
        ),
      );
    }
  }

  @override
  Future<Result<Map<String, int>>> getMealTypeDistribution({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      log('📊 [NUTRITION ANALYTICS REPO] Getting meal type distribution');

      // Initialize distribution map
      final distribution = <String, int>{
        'breakfast': 0,
        'lunch': 0,
        'dinner': 0,
        'snack': 0,
      };

      // Get all meals in the date range
      final meals = await _getMealsInDateRange(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      // Count meal types
      for (final meal in meals) {
        if (meal.containsKey('mealType')) {
          final mealType = (meal['mealType'] as String).toLowerCase();
          if (distribution.containsKey(mealType)) {
            distribution[mealType] = (distribution[mealType] ?? 0) + 1;
          }
        }
      }

      log('✅ [NUTRITION ANALYTICS REPO] Generated meal type distribution');
      return Right(distribution);
    } catch (e) {
      log('❌ [NUTRITION ANALYTICS REPO] Error getting distribution: $e');
      return Left(
        Failure.serverFailure(
          message: 'Failed to get meal type distribution: $e',
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

  /// Calculate average nutrition from daily data
  AverageNutrition _calculateAverageNutrition(List<DailyNutrition> dailyData) {
    if (dailyData.isEmpty) {
      return const AverageNutrition(calories: 0, protein: 0, carbs: 0, fat: 0);
    }

    // Total values
    int totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    // Sum all values
    for (final day in dailyData) {
      totalCalories += day.calories;
      totalProtein += day.protein;
      totalCarbs += day.carbs;
      totalFat += day.fat;
    }

    // Calculate averages
    return AverageNutrition(
      calories: totalCalories / dailyData.length,
      protein: totalProtein / dailyData.length,
      carbs: totalCarbs / dailyData.length,
      fat: totalFat / dailyData.length,
    );
  }

  @override
  Future<Result<List<TopFood>>> getTopFoods({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  }) async {
    try {
      log('🔍 [NUTRITION ANALYTICS REPO] Getting top foods for user: $userId');

      // Get meals in the date range
      final mealsQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('loggedMeals')
          .where(
            'loggedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('loggedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      // Count food frequencies
      final foodFrequencies = <String, TopFood>{};

      for (final doc in mealsQuery.docs) {
        final data = doc.data();
        final foodItems = List<Map<String, dynamic>>.from(
          data['foodItems'] ?? [],
        );

        for (final item in foodItems) {
          final name = item['name'] as String? ?? 'Unknown';
          final calories = (item['calories'] as num?)?.toDouble() ?? 0.0;

          if (foodFrequencies.containsKey(name)) {
            final existing = foodFrequencies[name]!;
            foodFrequencies[name] = existing.copyWith(
              frequency: existing.frequency + 1,
              totalCalories: existing.totalCalories + calories,
              avgCalories:
                  (existing.totalCalories + calories) /
                  (existing.frequency + 1),
            );
          } else {
            foodFrequencies[name] = TopFood(
              name: name,
              frequency: 1,
              totalCalories: calories,
              avgCalories: calories,
            );
          }
        }
      }

      // Sort by frequency and take top N
      final topFoods = foodFrequencies.values.toList()
        ..sort((a, b) => b.frequency.compareTo(a.frequency));

      final result = topFoods.take(limit).toList();

      log('✅ [NUTRITION ANALYTICS REPO] Found ${result.length} top foods');
      return Right(result);
    } catch (e) {
      log('❌ [NUTRITION ANALYTICS REPO] Error getting top foods: $e');
      return Left(
        Failure.serverFailure(message: 'Failed to get top foods: $e'),
      );
    }
  }

  @override
  Future<Result<NutritionTrends>> getNutritionTrends({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    required AnalyticsPeriod period,
  }) async {
    try {
      log(
        '📈 [NUTRITION ANALYTICS REPO] Getting nutrition trends for user: $userId',
      );

      final dailyData = await getDailyNutritionData(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      if (dailyData.isLeft()) {
        return Left(
          dailyData.fold(
            (l) => l,
            (r) => const Failure.unexpectedFailure(
              message: 'Unexpected error occurred while getting daily data',
            ),
          ),
        );
      }

      final data = dailyData.fold((l) => <DailyNutrition>[], (r) => r);

      // Group data by period
      final caloriesTrend = <String, List<double>>{};
      final proteinTrend = <String, List<double>>{};
      final carbsTrend = <String, List<double>>{};
      final fatTrend = <String, List<double>>{};

      for (final day in data) {
        final key = _formatDateKey(day.date, period);
        caloriesTrend.putIfAbsent(key, () => []).add(day.calories.toDouble());
        proteinTrend.putIfAbsent(key, () => []).add(day.protein);
        carbsTrend.putIfAbsent(key, () => []).add(day.carbs);
        fatTrend.putIfAbsent(key, () => []).add(day.fat);
      }

      final trends = NutritionTrends(
        caloriesTrend: caloriesTrend,
        proteinTrend: proteinTrend,
        carbsTrend: carbsTrend,
        fatTrend: fatTrend,
        startDate: startDate,
        endDate: endDate,
      );

      log('✅ [NUTRITION ANALYTICS REPO] Generated nutrition trends');
      return Right(trends);
    } catch (e) {
      log('❌ [NUTRITION ANALYTICS REPO] Error getting nutrition trends: $e');
      return Left(
        Failure.serverFailure(message: 'Failed to get nutrition trends: $e'),
      );
    }
  }

  @override
  Future<Result<String>> exportNutritionData({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    required ExportFormat format,
  }) async {
    try {
      log(
        '📄 [NUTRITION ANALYTICS REPO] Exporting nutrition data for user: $userId, format: $format',
      );

      final dailyData = await getDailyNutritionData(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      if (dailyData.isLeft()) {
        return Left(
          dailyData.fold(
            (l) => l,
            (r) => const Failure.unexpectedFailure(
              message: 'Unexpected error occurred while getting daily data',
            ),
          ),
        );
      }

      final data = dailyData.fold((l) => <DailyNutrition>[], (r) => r);

      String exportData;
      switch (format) {
        case ExportFormat.csv:
          exportData = _generateCSV(data);
          break;
        case ExportFormat.json:
          exportData = _generateJSON(data);
          break;
        case ExportFormat.pdf:
          exportData = 'PDF export not implemented yet';
          break;
      }

      log('✅ [NUTRITION ANALYTICS REPO] Generated export data');
      return Right(exportData);
    } catch (e) {
      log('❌ [NUTRITION ANALYTICS REPO] Error exporting nutrition data: $e');
      return Left(
        Failure.serverFailure(message: 'Failed to export nutrition data: $e'),
      );
    }
  }

  String _formatDateKey(DateTime date, AnalyticsPeriod period) {
    switch (period) {
      case AnalyticsPeriod.daily:
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      case AnalyticsPeriod.weekly:
        final weekOfYear =
            ((date.difference(DateTime(date.year, 1, 1)).inDays + 1) / 7)
                .ceil();
        return '${date.year}-W$weekOfYear';
      case AnalyticsPeriod.monthly:
        return '${date.year}-${date.month.toString().padLeft(2, '0')}';
      case AnalyticsPeriod.custom:
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  String _generateCSV(List<DailyNutrition> data) {
    final buffer = StringBuffer();
    buffer.writeln('Date,Calories,Protein,Carbs,Fat,Meals');

    for (final day in data) {
      buffer.writeln(
        '${day.date.toIso8601String()},${day.calories},${day.protein},${day.carbs},${day.fat},${day.mealCount ?? 0}',
      );
    }

    return buffer.toString();
  }

  String _generateJSON(List<DailyNutrition> data) {
    return data.map((d) => d.toJson()).toList().toString();
  }
}
