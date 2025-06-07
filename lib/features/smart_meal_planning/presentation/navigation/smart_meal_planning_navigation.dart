import 'package:flutter/material.dart';
import '../screens/meal_planning_screen.dart';
import '../screens/swipeable_meal_suggestions_screen.dart';
import '../screens/grocery_list_screen.dart';
import '../../domain/entities/meal_plan.dart';

/// Class to handle navigation for Smart Meal Planning feature
class SmartMealPlanningNavigation {
  /// Navigate to the meal planning screen
  static void navigateToMealPlanningScreen(
    BuildContext context,
    String userId,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MealPlanningScreen(userId: userId),
      ),
    );
  }

  /// Navigate to the meal suggestions screen
  static void navigateToMealSuggestionsScreen(
    BuildContext context,
    String mealType, {
    DateTime? date,
    Function(dynamic)? onSuggestionSelected,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SwipeableMealSuggestionsScreen(
          mealType: mealType,
          date: date,
          onSuggestionAccepted: onSuggestionSelected,
        ),
      ),
    );
  }

  /// Navigate to the grocery list screen
  static void navigateToGroceryListScreen(
    BuildContext context,
    String userId, {
    MealPlan? mealPlan,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            GroceryListScreen(userId: userId, mealPlan: mealPlan),
      ),
    );
  }
}

/// Routes for Smart Meal Planning feature
class SmartMealPlanningRoutes {
  static const String mealPlanning = '/meal-planning';
  static const String mealSuggestions = '/meal-suggestions';
  static const String groceryList = '/grocery-list';

  /// Generate routes for Smart Meal Planning feature
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      mealPlanning: (context) => MealPlanningScreen(
        userId: ModalRoute.of(context)!.settings.arguments as String,
      ),
      mealSuggestions: (context) {
        final args =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        return SwipeableMealSuggestionsScreen(
          mealType: args['mealType'] as String,
          date: args['date'] as DateTime?,
          onSuggestionAccepted:
              args['onSuggestionSelected'] as Function(dynamic)?,
        );
      },
      groceryList: (context) {
        final args =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        return GroceryListScreen(
          userId: args['userId'] as String,
          mealPlan: args['mealPlan'] as MealPlan?,
        );
      },
    };
  }
}
