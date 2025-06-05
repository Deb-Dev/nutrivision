import 'package:flutter_test/flutter_test.dart';
import 'package:nutrivision/features/advanced_meal_mgmt/domain/entities/nutrition_goals.dart';
import 'package:nutrivision/features/advanced_meal_mgmt/domain/entities/nutrition_report.dart';
import 'package:nutrivision/features/advanced_meal_mgmt/domain/entities/daily_nutrition.dart';
import 'package:nutrivision/features/advanced_meal_mgmt/domain/entities/nutrition.dart';

void main() {
  group('Advanced Meal Management Entities', () {
    test('NutritionGoals entity should work correctly', () {
      final goal = NutritionGoal(
        id: '123',
        userId: 'user1',
        name: 'Test Goal',
        type: NutritionGoalType.calories,
        targetValue: 2000,
        created: DateTime(2025, 5, 27),
      );

      expect(goal.id, equals('123'));
      expect(goal.userId, equals('user1'));
      expect(goal.name, equals('Test Goal'));
      expect(goal.type, equals(NutritionGoalType.calories));
      expect(goal.targetValue, equals(2000));
      expect(goal.created, equals(DateTime(2025, 5, 27)));
    });

    test('NutritionReport should calculate progress correctly', () {
      final dailyData = [
        DailyNutrition(
          date: DateTime(2025, 5, 20),
          calories: 2100,
          protein: 120,
          carbs: 200,
          fat: 70,
          mealCount: 3,
        ),
        DailyNutrition(
          date: DateTime(2025, 5, 21),
          calories: 1900,
          protein: 110,
          carbs: 180,
          fat: 65,
          mealCount: 3,
        ),
      ];

      final avgNutrition = Nutrition(
        calories: 2000,
        protein: 115,
        carbs: 190,
        fat: 67.5,
      );

      final report = NutritionReport(
        period: AnalyticsPeriod.weekly,
        startDate: DateTime(2025, 5, 20),
        endDate: DateTime(2025, 5, 26),
        dailyNutrition: dailyData,
        averageNutrition: avgNutrition,
        goalProgress: {
          NutritionGoalType.calories: 0.95,
          NutritionGoalType.protein: 1.15,
        },
        mealTypeDistribution: {'Breakfast': 5, 'Lunch': 4, 'Dinner': 3},
        macroDistribution: MacroDistribution(
          proteinPercentage: 0.25,
          carbsPercentage: 0.5,
          fatPercentage: 0.25,
        ),
        topFoods: [
          TopFoodItem(name: 'Chicken', frequency: 3),
          TopFoodItem(name: 'Rice', frequency: 2),
        ],
      );

      expect(report.averageNutrition.calories, equals(2000));
      expect(report.goalProgress[NutritionGoalType.calories], equals(0.95));
      expect(report.mealTypeDistribution['Breakfast'], equals(5));
      expect(report.macroDistribution.proteinPercentage, equals(0.25));
      expect(report.topFoods.length, equals(2));
      expect(report.topFoods.first.name, equals('Chicken'));
    });
  });
}
