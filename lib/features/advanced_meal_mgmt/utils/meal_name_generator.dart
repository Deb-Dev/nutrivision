import '../../../../core/models/meal_models.dart';

/// Utility class for generating meaningful meal names from meal data
class MealNameGenerator {
  /// Generate a meaningful meal name from MealHistoryEntry
  static String generateFromMealHistoryEntry(MealHistoryEntry meal) {
    print('🔍 [MEAL NAME GEN] Processing meal: ${meal.id}');
    print('🔍 [MEAL NAME GEN] Meal source: ${meal.source}');
    print('🔍 [MEAL NAME GEN] Description: "${meal.description}"');
    print('🔍 [MEAL NAME GEN] Food items count: ${meal.foodItems.length}');

    // PRIORITY 1: Use pre-computed description from conversion
    // This should now contain the meal name generated during fromManualMeal/fromAIMeal
    if (meal.description != null &&
        meal.description!.isNotEmpty &&
        meal.description!.toLowerCase() != 'logged meal' &&
        meal.description!.toLowerCase() != 'unnamed meal' &&
        meal.description!.toLowerCase() != 'ai recognized meal') {
      print(
        '🔍 [MEAL NAME GEN] Using pre-computed description: "${meal.description}"',
      );
      return meal.description!;
    }

    // PRIORITY 2: Generate from food items (fallback for legacy data)
    if (meal.foodItems.isNotEmpty) {
      List<String> foodNames = meal.foodItems
          .map((item) => item.name)
          .where((name) => name.isNotEmpty)
          .toList();

      print('🔍 [MEAL NAME GEN] Food names extracted: $foodNames');

      if (foodNames.isNotEmpty) {
        final generated = _generateMealNameFromFoodNames(foodNames);
        print('🔍 [MEAL NAME GEN] Generated from food items: "$generated"');
        return generated;
      }
    }

    // PRIORITY 3: Intelligent fallback based on meal source and type
    if (meal.source == MealSource.manual) {
      print('🔍 [MEAL NAME GEN] Manual meal fallback');
      switch (meal.mealType.toLowerCase()) {
        case 'breakfast':
          return 'Breakfast Meal';
        case 'lunch':
          return 'Lunch Meal';
        case 'dinner':
          return 'Dinner Meal';
        case 'snack':
          return 'Snack';
        default:
          return 'Manual Meal';
      }
    }

    // PRIORITY 4: Final fallback
    final fallback = '${_capitalizeFirst(meal.mealType)} Items';
    print('🔍 [MEAL NAME GEN] Using final fallback: "$fallback"');
    return fallback;
  }

  /// Generate a meaningful meal name from regular meal data
  static String generateFromRegularMealData(Map<String, dynamic> mealData) {
    print('DEBUG: Regular meal data structure: $mealData');

    // Check for 'foods' field (array of food objects)
    List<String> foodNames = [];

    if (mealData['foods'] != null && mealData['foods'] is List) {
      List<dynamic> foods = mealData['foods'];
      foodNames = foods
          .map((food) {
            // Try different field names for food name
            return food['name']?.toString() ??
                food['foodName']?.toString() ??
                food['item']?.toString() ??
                '';
          })
          .where((name) => name.isNotEmpty)
          .toList();
    }

    // Check for 'foodName' field (single food name)
    if (foodNames.isEmpty && mealData['foodName'] != null) {
      String singleFood = mealData['foodName'].toString();
      if (singleFood.isNotEmpty) {
        foodNames = [singleFood];
      }
    }

    // Check for 'name' field as fallback
    if (foodNames.isEmpty && mealData['name'] != null) {
      String mealName = mealData['name'].toString();
      if (mealName.isNotEmpty && mealName.toLowerCase() != 'unnamed meal') {
        return mealName;
      }
    }

    // Generate meaningful name from food list
    if (foodNames.isNotEmpty) {
      String result = _generateMealNameFromFoodNames(foodNames);
      print('DEBUG: Generated regular meal name: $result');
      return result;
    }

    // Fallback: use meal type as descriptor
    String mealType = mealData['mealType']?.toString() ?? 'Meal';
    String result = '${_capitalizeFirst(mealType)} Items';
    print('DEBUG: Using fallback regular meal name: $result');
    return result;
  }

  /// Generate a meaningful meal name from AI meal data
  static String generateFromAIMealData(Map<String, dynamic> aiMealData) {
    print('DEBUG: AI meal data structure: $aiMealData');

    List<String> itemNames = [];

    // Check for 'confirmedItems' field
    if (aiMealData['confirmedItems'] != null &&
        aiMealData['confirmedItems'] is List) {
      List<dynamic> items = aiMealData['confirmedItems'];
      itemNames = items
          .map((item) {
            // Try different field names for item name
            return item['name']?.toString() ??
                item['foodName']?.toString() ??
                item['item']?.toString() ??
                '';
          })
          .where((name) => name.isNotEmpty)
          .toList();
    }

    // Check for 'recognizedItems' as fallback
    if (itemNames.isEmpty &&
        aiMealData['recognizedItems'] != null &&
        aiMealData['recognizedItems'] is List) {
      List<dynamic> items = aiMealData['recognizedItems'];
      itemNames = items
          .map((item) => item['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
    }

    // Check for 'items' as another fallback
    if (itemNames.isEmpty &&
        aiMealData['items'] != null &&
        aiMealData['items'] is List) {
      List<dynamic> items = aiMealData['items'];
      itemNames = items
          .map((item) => item['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
    }

    // Generate meaningful name from items list
    if (itemNames.isNotEmpty) {
      return _generateMealNameFromFoodNames(itemNames);
    }

    // Fallback: use meal type as descriptor
    String mealType = aiMealData['mealType']?.toString() ?? 'Meal';
    return 'AI ${_capitalizeFirst(mealType)}';
  }

  /// Generate meal name pattern from list of food names
  static String _generateMealNameFromFoodNames(List<String> foodNames) {
    if (foodNames.isEmpty) return 'Meal';

    if (foodNames.length == 1) {
      return foodNames[0];
    } else if (foodNames.length == 2) {
      return '${foodNames[0]} & ${foodNames[1]}';
    } else if (foodNames.length <= 3) {
      return foodNames.join(', ');
    } else {
      return '${foodNames.take(2).join(', ')} + ${foodNames.length - 2} more';
    }
  }

  /// Capitalize first letter of a string
  static String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}
