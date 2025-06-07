import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/base_repository.dart';
import '../../../../core/models/meal_models.dart';
import '../../domain/entities/meal_suggestion.dart';
import '../../domain/entities/meal_plan.dart';
import '../../../ai_meal_logging/data/services/gemini_ai_service.dart';

/// Service for generating meal suggestions using AI
@injectable
class MealSuggestionService extends BaseRepository {
  final FirebaseFirestore _firestore;
  final GeminiAIService _geminiService;

  // Collection reference
  late final CollectionReference<Map<String, dynamic>> _suggestionsCollection;

  // Track ongoing AI requests to prevent duplicate calls
  final Map<String, Future<PlannedMeal>> _ongoingRequests = {};

  // Add local memory cache for better performance and to avoid repeated calls
  final Map<String, MealSuggestion> _localSuggestionCache = {};
  final Map<String, DateTime> _localCacheTimestamps = {};
  final Duration _localCacheExpiration = const Duration(minutes: 30);

  MealSuggestionService(this._firestore, this._geminiService) {
    _suggestionsCollection = _firestore.collection('mealSuggestions');
  }

  /// Generate a meal suggestion for a specific meal type and date
  Future<PlannedMeal> getMealSuggestion(
    String userId,
    String mealType,
    DateTime date,
    Map<String, dynamic> preferences,
  ) async {
    // Create a unique key for this request to prevent duplicates
    final dateString = date.toIso8601String().split('T')[0];
    final requestKey = '${userId}_${mealType}_$dateString';

    // Check if there's already an ongoing request for this same meal
    if (_ongoingRequests.containsKey(requestKey)) {
      print('🔄 Returning existing request for $mealType');
      return _ongoingRequests[requestKey]!;
    }

    print(
      '🍽️ Generating meal suggestion: $mealType, type: ${preferences['requestType'] ?? 'primary'}',
    );

    // First check memory cache for faster access
    final cacheKey = requestKey;
    if (_localSuggestionCache.containsKey(cacheKey)) {
      final cachedTime = _localCacheTimestamps[cacheKey] ?? DateTime(2000);

      // If cache is valid and we're not forcing refresh
      if (DateTime.now().difference(cachedTime) < _localCacheExpiration &&
          preferences['forceRefresh'] != true) {
        print('✅ Using cached suggestion for $mealType');
        return _convertToPlannedMeal(
          _localSuggestionCache[cacheKey]!,
          mealType,
        );
      }
    }

    // Create the future and store it
    final future = _generateMealSuggestionInternal(
      userId,
      mealType,
      date,
      preferences,
    );
    _ongoingRequests[requestKey] = future;

    try {
      final result = await future;
      return result;
    } finally {
      // Remove the request from ongoing requests when done
      _ongoingRequests.remove(requestKey);
    }
  }

  /// Internal method to generate meal suggestion
  Future<PlannedMeal> _generateMealSuggestionInternal(
    String userId,
    String mealType,
    DateTime date,
    Map<String, dynamic> preferences,
  ) async {
    try {
      final variationIndex = preferences['variationIndex'] as int? ?? 0;
      final requestType = preferences['requestType'] as String? ?? 'primary';

      print('🍽️ Generating meal suggestion: $mealType, type: $requestType');

      // If this is explicitly a fallback request, skip AI and go straight to fallback
      if (requestType == 'fallback') {
        final fallbackVariation =
            (variationIndex + DateTime.now().millisecond) % 1000;
        return _generateFallbackMeal(
          mealType,
          variationIndex: fallbackVariation,
        );
      }

      // Skip caching for variations to ensure different suggestions
      if (variationIndex == 0) {
        // Check if we have cached suggestions first (only for first suggestion)
        final cachedSuggestion = await _getCachedSuggestion(
          userId,
          mealType,
          date,
        );
        if (cachedSuggestion != null) {
          print('✅ Using cached suggestion for $mealType');
          return _convertToPlannedMeal(cachedSuggestion, mealType);
        }
      }

      print('🔄 No cached suggestion, generating AI suggestion...');

      // No cached suggestion, generate a new one
      final userPreferences = await _getUserPreferences(userId);
      final dietaryRestrictions = await _getUserDietaryRestrictions(userId);
      final recentMeals = await _getRecentMeals(userId, 10);

      // Combine all preferences
      final combinedPreferences = {
        ...userPreferences,
        ...preferences,
        'userId': userId,
        'dietaryRestrictions': dietaryRestrictions,
        'recentMeals': recentMeals,
        'mealType': mealType,
        'date': date.toIso8601String(),
      };

      // Try to generate suggestion using AI
      try {
        final suggestion = await _generateAISuggestion(combinedPreferences);

        // Cache the suggestion
        await _cacheSuggestion(suggestion);

        print('✅ AI suggestion generated and cached');
        return _convertToPlannedMeal(suggestion, mealType);
      } catch (aiError) {
        print('❌ AI generation failed, using fallback: $aiError');

        // Fallback to a dynamic suggestion
        final fallbackVariation =
            (variationIndex + DateTime.now().millisecond) % 1000;
        return _generateFallbackMeal(
          mealType,
          variationIndex: fallbackVariation,
        );
      }
    } catch (e) {
      print('❌ Error generating meal suggestion: $e');

      // Final fallback to a basic suggestion if everything else fails
      // Use a random variation index to get different fallback meals
      final emergencyVariation = DateTime.now().millisecondsSinceEpoch % 1000;
      return _generateFallbackMeal(
        mealType,
        variationIndex: emergencyVariation,
      );
    }
  }

  /// Convert a MealSuggestion to a PlannedMeal
  PlannedMeal _convertToPlannedMeal(
    MealSuggestion suggestion,
    String mealType,
  ) {
    final id = 'pm_${DateTime.now().millisecondsSinceEpoch}_${suggestion.id}';

    return PlannedMeal(
      id: id,
      mealType: mealType,
      items: suggestion.items
          .map(
            (item) => PlannedFoodItem(
              id: 'pfi_${item.id}',
              name: item.name,
              quantity: item.quantity,
              unit: item.unit,
              nutritionalValues: item.nutritionalValues,
              imageUrl: item.imageUrl,
              notes: item.notes,
            ),
          )
          .toList(),
      estimatedNutrition: suggestion.estimatedNutrition,
      source: PlannedMealSource.suggested,
      notes: suggestion.description,
    );
  }

  /// Check for cached suggestions with improved performance
  Future<MealSuggestion?> _getCachedSuggestion(
    String userId,
    String mealType,
    DateTime date,
  ) async {
    final dateString = date.toIso8601String().split('T')[0];
    final cacheKey = '${userId}_${mealType}_$dateString';

    // First check local memory cache for faster access
    if (_localSuggestionCache.containsKey(cacheKey)) {
      final cachedTime = _localCacheTimestamps[cacheKey] ?? DateTime(2000);
      final now = DateTime.now();

      // If cache is still valid
      if (now.difference(cachedTime) < _localCacheExpiration) {
        print('💾 Using in-memory cached suggestion for $mealType');
        return _localSuggestionCache[cacheKey];
      } else {
        // Expired cache, remove it
        _localSuggestionCache.remove(cacheKey);
        _localCacheTimestamps.remove(cacheKey);
      }
    }

    // No valid memory cache, try to fetch from Firestore
    final querySnapshot = await _suggestionsCollection
        .where('userId', isEqualTo: userId)
        .where('mealType', isEqualTo: mealType)
        .where('dateGenerated', isEqualTo: dateString)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return null;
    }

    // Found a cached suggestion in Firestore
    final doc = querySnapshot.docs.first;
    final data = doc.data();

    try {
      final suggestion = MealSuggestion.fromJson(data);

      // Store in local cache for future use
      _localSuggestionCache[cacheKey] = suggestion;
      _localCacheTimestamps[cacheKey] = DateTime.now();

      print('📦 Retrieved database cached suggestion for $mealType');
      return suggestion;
    } catch (e) {
      print('❌ Error parsing cached suggestion: $e');
      return null;
    }
  }

  /// Cache a suggestion
  Future<void> _cacheSuggestion(MealSuggestion suggestion) async {
    final userId = suggestion.id.split('_').last; // Extract userId from ID
    final dateString = DateTime.now().toIso8601String().split('T')[0];
    final cacheKey = '${userId}_${suggestion.mealType}_$dateString';

    // Update local memory cache
    _localSuggestionCache[cacheKey] = suggestion;
    _localCacheTimestamps[cacheKey] = DateTime.now();

    final data = {
      'userId': userId,
      'name': suggestion.name,
      'mealType': suggestion.mealType,
      'dateGenerated': dateString, // Add date for easier querying
      'items': suggestion.items
          .map(
            (item) => {
              'id': item.id,
              'name': item.name,
              'quantity': item.quantity,
              'unit': item.unit,
              'nutritionalValues': item.nutritionalValues,
              'imageUrl': item.imageUrl,
              'notes': item.notes,
            },
          )
          .toList(),
      'estimatedNutrition': {
        'calories': suggestion.estimatedNutrition.calories,
        'protein': suggestion.estimatedNutrition.protein,
        'carbs': suggestion.estimatedNutrition.carbs,
        'fat': suggestion.estimatedNutrition.fat,
        'fiber': suggestion.estimatedNutrition.fiber,
        'sugar': suggestion.estimatedNutrition.sugar,
        'sodium': suggestion.estimatedNutrition.sodium,
      },
      'source': suggestion.source.toString().split('.').last,
      'createdAt': Timestamp.fromDate(suggestion.createdAt ?? DateTime.now()),
      'description': suggestion.description,
      'preparationTimeMinutes': suggestion.preparationTimeMinutes,
    };

    await _suggestionsCollection.doc(suggestion.id).set(data);
  }

  /// Get user preferences
  Future<Map<String, dynamic>> _getUserPreferences(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();

    if (!userDoc.exists) {
      return {};
    }

    final userData = userDoc.data() as Map<String, dynamic>;
    final preferences = userData['preferences'] as Map<String, dynamic>? ?? {};

    return preferences;
  }

  /// Get user dietary restrictions
  Future<List<String>> _getUserDietaryRestrictions(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();

    if (!userDoc.exists) {
      return [];
    }

    final userData = userDoc.data() as Map<String, dynamic>;
    final restrictions =
        userData['dietaryRestrictions'] as List<dynamic>? ?? [];

    return restrictions.map((r) => r as String).toList();
  }

  /// Get recent meals for a user
  Future<List<Map<String, dynamic>>> _getRecentMeals(
    String userId,
    int limit,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('mealHistory')
          .where('userId', isEqualTo: userId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      // Sort in memory to avoid Firestore composite index requirement
      final allMeals = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'mealType': data['mealType'],
          'foodItems': data['foodItems'],
          'loggedAt': (data['loggedAt'] as Timestamp)
              .toDate()
              .toIso8601String(),
          'timestamp': (data['loggedAt'] as Timestamp).toDate(),
        };
      }).toList();

      // Sort by timestamp descending and take the limit
      allMeals.sort(
        (a, b) =>
            (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime),
      );

      // Remove the timestamp field and return limited results
      return allMeals.take(limit).map((meal) {
        meal.remove('timestamp');
        return meal;
      }).toList();
    } catch (e) {
      // If there's still an error, return empty list and log the error
      print('Error fetching recent meals: $e');
      return [];
    }
  }

  /// Generate a suggestion using Gemini AI
  Future<MealSuggestion> _generateAISuggestion(
    Map<String, dynamic> preferences,
  ) async {
    final maxRetries = 1; // Limit retries to reduce API costs
    int retryCount = 0;

    while (retryCount <= maxRetries) {
      try {
        // Ensure Gemini service is initialized
        await _geminiService.initialize();

        // Construct prompt for AI
        final prompt = _constructAIPrompt(preferences);

        print('🤖 Attempting to generate AI suggestion...');

        // Get response from Gemini
        final response = await _geminiService.generateMealSuggestion(prompt);

        // Log the meal name from the response
        final mealName = _extractMealNameFromResponse(response);
        if (mealName.isNotEmpty) {
          print('🍽️ Parsed AI meal: $mealName');
        }

        // Parse the response into a structured meal suggestion
        final suggestion = _parseAIResponse(response, preferences);
        print('✅ AI suggestion generated and cached');
        return suggestion;
      } catch (e) {
        print('❌ AI generation failed (attempt ${retryCount + 1}): $e');
        retryCount++;

        // On the last retry, throw to trigger fallback
        if (retryCount > maxRetries) {
          throw Exception(
            'Failed to generate AI suggestion after $maxRetries retries',
          );
        }

        // Wait a bit before retrying
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    // Should never reach here due to throw above, but Dart requires a return
    throw Exception('Failed to generate AI suggestion');
  }

  /// Extract meal name from AI response for logging
  String _extractMealNameFromResponse(String response) {
    try {
      // Simple regex to find meal name which is usually in a "name" field in JSON
      final nameMatch = RegExp(r'"name"\s*:\s*"([^"]+)"').firstMatch(response);
      if (nameMatch != null && nameMatch.groupCount >= 1) {
        return nameMatch.group(1) ?? '';
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  /// Construct prompt for Gemini AI
  String _constructAIPrompt(Map<String, dynamic> preferences) {
    final mealType = preferences['mealType'] as String;
    final dietaryRestrictions =
        (preferences['dietaryRestrictions'] as List<String>?)?.join(', ') ??
        'None';
    final calorieTarget = preferences['calorieTarget'] ?? 500;
    final cuisine = preferences['cuisine'] ?? 'Any';
    final variationIndex = preferences['variationIndex'] as int? ?? 0;
    final recentMealsData =
        preferences['recentMeals'] as List<Map<String, dynamic>>? ?? [];

    // Extract meal names from recent meals data
    final recentMealNames = recentMealsData
        .map((meal) {
          final foodItems = meal['foodItems'] as List<dynamic>? ?? [];
          return foodItems
              .map((item) => item['name'] as String? ?? 'Unknown')
              .join(', ');
        })
        .where((name) => name.isNotEmpty)
        .toList();

    final recentMealsText = recentMealNames.isNotEmpty
        ? 'Recent meals to avoid repeating: ${recentMealNames.join('; ')}'
        : 'No recent meals to avoid';

    // Add variety instructions based on variation index
    final varietyInstructions = _getVarietyInstructions(
      mealType,
      variationIndex,
    );

    return '''
    Generate a nutritious $mealType meal recommendation with these specifications:
    
    REQUIREMENTS:
    - Meal type: $mealType
    - Dietary restrictions: $dietaryRestrictions
    - Target calories: $calorieTarget
    - Preferred cuisine: $cuisine
    - $recentMealsText
    - VARIETY REQUIREMENT: $varietyInstructions
    - Request ID: ${DateTime.now().millisecondsSinceEpoch}_$variationIndex (ensure unique response)
    
    RESPONSE FORMAT (JSON):
    {
      "name": "Meal name",
      "description": "Brief description",
      "ingredients": [
        {
          "name": "ingredient name",
          "quantity": 1.5,
          "unit": "unit (g, cups, pieces, etc.)"
        }
      ],
      "nutrition": {
        "calories": 350,
        "protein": 25.0,
        "carbs": 30.0,
        "fat": 15.0,
        "fiber": 8.0,
        "sugar": 5.0,
        "sodium": 600
      },
      "preparationTimeMinutes": 25,
      "instructions": "Simple preparation steps"
    }
    
    IMPORTANT: 
    - Use ONLY decimal numbers (like 1.5, 0.5, 2.0) for all quantities
    - DO NOT use fractions (like 1/2, 3/4) 
    - All numeric values must be valid JSON numbers
    - MUST create completely different meals - no repeating ingredients or meal types
    
    Ensure the meal strictly avoids all dietary restrictions and provides balanced nutrition.
    ''';
  }

  /// Get variety instructions based on meal type and variation index
  String _getVarietyInstructions(String mealType, int variationIndex) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        final breakfastStyles = [
          'Create a protein-rich egg-based breakfast',
          'Design a healthy smoothie or smoothie bowl',
          'Make a whole grain cereal or porridge (NOT oats)',
          'Create an avocado-based breakfast',
          'Design a yogurt parfait or dairy-based meal',
          'Make a breakfast sandwich or wrap',
          'Create a pancake or waffle alternative',
          'Design a fruit and nut breakfast bowl',
        ];
        return breakfastStyles[variationIndex % breakfastStyles.length];

      case 'lunch':
        final lunchStyles = [
          'Create a fresh salad with protein',
          'Design a hearty soup with grains/legumes',
          'Make a sandwich or wrap with lean protein',
          'Create a grain bowl (quinoa, rice, etc.)',
          'Design a stir-fry with vegetables',
          'Make a pasta dish with vegetables',
          'Create a Mediterranean-style meal',
          'Design an Asian-inspired dish',
        ];
        return lunchStyles[variationIndex % lunchStyles.length];

      case 'dinner':
        final dinnerStyles = [
          'Create a grilled or baked fish dish',
          'Design a lean meat with roasted vegetables',
          'Make a plant-based protein main course',
          'Create a one-pot meal with protein and vegetables',
          'Design a curry or stew with protein',
          'Make a stuffed vegetable dish',
          'Create a healthy pasta or noodle dish',
          'Design a sheet pan meal with protein and vegetables',
        ];
        return dinnerStyles[variationIndex % dinnerStyles.length];

      default: // snack
        final snackStyles = [
          'Create a protein-rich snack',
          'Design a fruit and nut combination',
          'Make a vegetable-based snack with dip',
          'Create an energy ball or bar',
          'Design a dairy-based protein snack',
          'Make a seed and grain mix',
        ];
        return snackStyles[variationIndex % snackStyles.length];
    }
  }

  /// Parse AI response into a MealSuggestion
  MealSuggestion _parseAIResponse(
    String response,
    Map<String, dynamic> preferences,
  ) {
    final id =
        'sg_${DateTime.now().millisecondsSinceEpoch}_${preferences['userId']}';
    final mealType = preferences['mealType'] as String;

    try {
      // Try to parse as JSON first
      Map<String, dynamic> jsonData;

      // Extract JSON from response if it's wrapped in markdown
      final jsonMatch = RegExp(
        r'```(?:json)?\s*(\{[\s\S]*?\})\s*```',
        caseSensitive: false,
      ).firstMatch(response);

      String jsonString;
      if (jsonMatch != null) {
        jsonString = jsonMatch.group(1)!;
      } else {
        jsonString = response;
      }

      // Preprocess to convert common fractions to decimals
      jsonString = _convertFractionsToDecimals(jsonString);

      // Parse the JSON
      jsonData = json.decode(jsonString);

      // Extract meal name and log it
      final mealName = jsonData['name'] as String? ?? 'Unknown Meal';
      print('🍽️ Parsed AI meal: $mealName');

      // Extract ingredients
      final items = <SuggestedFoodItem>[];
      final ingredients = jsonData['ingredients'] as List<dynamic>? ?? [];

      for (int i = 0; i < ingredients.length; i++) {
        final ingredient = ingredients[i] as Map<String, dynamic>;
        items.add(
          SuggestedFoodItem(
            id: 'i_${DateTime.now().millisecondsSinceEpoch}_$i',
            name: ingredient['name'] as String? ?? 'Unknown ingredient',
            quantity: (ingredient['quantity'] as num?)?.toDouble() ?? 1.0,
            unit: ingredient['unit'] as String? ?? 'piece',
            nutritionalValues: {},
          ),
        );
      }

      // Extract nutrition
      final nutrition = jsonData['nutrition'] as Map<String, dynamic>? ?? {};
      final estimatedNutrition = NutritionalSummary(
        calories: (nutrition['calories'] as num?)?.toInt() ?? 0,
        protein: (nutrition['protein'] as num?)?.toDouble() ?? 0.0,
        carbs: (nutrition['carbs'] as num?)?.toDouble() ?? 0.0,
        fat: (nutrition['fat'] as num?)?.toDouble() ?? 0.0,
        fiber: (nutrition['fiber'] as num?)?.toDouble() ?? 0.0,
        sugar: (nutrition['sugar'] as num?)?.toDouble() ?? 0.0,
        sodium: (nutrition['sodium'] as num?)?.toDouble() ?? 0.0,
      );

      return MealSuggestion(
        id: id,
        name: jsonData['name'] as String? ?? 'AI Suggested Meal',
        mealType: mealType,
        items: items,
        estimatedNutrition: estimatedNutrition,
        source: SuggestionSource.ai,
        createdAt: DateTime.now(),
        description: jsonData['description'] as String?,
        preparationTimeMinutes: (jsonData['preparationTimeMinutes'] as num?)
            ?.toDouble(),
      );
    } catch (e) {
      print('Error parsing AI JSON response: $e');
      // Fallback to text parsing
      return _parseAIResponseText(response, preferences);
    }
  }

  /// Fallback text parser for AI responses
  MealSuggestion _parseAIResponseText(
    String response,
    Map<String, dynamic> preferences,
  ) {
    final id =
        'sg_${DateTime.now().millisecondsSinceEpoch}_${preferences['userId']}';
    final mealType = preferences['mealType'] as String;

    // Extract meal name (first line of response)
    final lines = response.split('\n');
    final name = lines.first.replaceAll('#', '').trim();

    // Extract ingredients (look for lines with quantities)
    final items = <SuggestedFoodItem>[];
    final itemRegex = RegExp(r'(\d+[\.\d]*)\s*(\w+)\s+([\w\s]+)');

    for (final line in lines) {
      final match = itemRegex.firstMatch(line);
      if (match != null) {
        final quantity = double.tryParse(match.group(1) ?? '0') ?? 0;
        final unit = match.group(2) ?? '';
        final itemName = (match.group(3) ?? '').trim();

        items.add(
          SuggestedFoodItem(
            id: 'i_${DateTime.now().millisecondsSinceEpoch}_${items.length}',
            name: itemName,
            quantity: quantity,
            unit: unit,
            nutritionalValues: {},
          ),
        );
      }
    }

    // Extract nutritional info (look for lines with nutrition values)
    int calories = 0;
    double protein = 0, carbs = 0, fat = 0;

    final calorieRegex = RegExp(r'calories:?\s*(\d+)', caseSensitive: false);
    final calorieMatch = calorieRegex.firstMatch(response);
    if (calorieMatch != null) {
      calories = int.tryParse(calorieMatch.group(1) ?? '0') ?? 0;
    }

    final proteinRegex = RegExp(
      r'protein:?\s*(\d+[\.\d]*)',
      caseSensitive: false,
    );
    final proteinMatch = proteinRegex.firstMatch(response);
    if (proteinMatch != null) {
      protein = double.tryParse(proteinMatch.group(1) ?? '0') ?? 0;
    }

    final carbsRegex = RegExp(r'carbs:?\s*(\d+[\.\d]*)', caseSensitive: false);
    final carbsMatch = carbsRegex.firstMatch(response);
    if (carbsMatch != null) {
      carbs = double.tryParse(carbsMatch.group(1) ?? '0') ?? 0;
    }

    final fatRegex = RegExp(r'fat:?\s*(\d+[\.\d]*)', caseSensitive: false);
    final fatMatch = fatRegex.firstMatch(response);
    if (fatMatch != null) {
      fat = double.tryParse(fatMatch.group(1) ?? '0') ?? 0;
    }

    // Extract description
    String? description;
    final descIndex = response.toLowerCase().indexOf('description');
    final prepTimeIndex = response.toLowerCase().indexOf('preparation time');

    if (descIndex > 0 && prepTimeIndex > descIndex) {
      description = response
          .substring(descIndex, prepTimeIndex)
          .trim()
          .replaceAll('Description:', '')
          .trim();
    }

    // Extract prep time
    double? prepTime;
    final prepTimeRegex = RegExp(
      r'preparation time:?\s*(\d+[\.\d]*)',
      caseSensitive: false,
    );
    final prepTimeMatch = prepTimeRegex.firstMatch(response);
    if (prepTimeMatch != null) {
      prepTime = double.tryParse(prepTimeMatch.group(1) ?? '0');
    }

    return MealSuggestion(
      id: id,
      name: name,
      mealType: mealType,
      items: items,
      estimatedNutrition: _createNutritionalSummary(
        calories,
        protein,
        carbs,
        fat,
      ),
      source: SuggestionSource.ai,
      createdAt: DateTime.now(),
      description: description,
      preparationTimeMinutes: prepTime,
    );
  }

  /// Create a nutritional summary
  NutritionalSummary _createNutritionalSummary(
    int calories,
    double protein,
    double carbs,
    double fat,
  ) {
    return NutritionalSummary(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
    );
  }

  /// Generate a fallback meal in case AI fails
  PlannedMeal _generateFallbackMeal(String mealType, {int variationIndex = 0}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final id = 'pm_fallback_${timestamp}_$variationIndex';

    // Create dynamic fallback meals with much more variety
    final mealData = _getDynamicFallbackMeal(mealType, variationIndex);

    // Convert nutrition values to doubles for compatibility
    final nutritionMap = _convertNutritionToDoubles(mealData['nutrition']);

    return PlannedMeal(
      id: id,
      mealType: mealType,
      items: [
        PlannedFoodItem(
          id: 'pfi_${mealData['id']}_$timestamp',
          name: mealData['name'] as String,
          quantity: (mealData['quantity'] as num).toDouble(),
          unit: mealData['unit'] as String,
          nutritionalValues: nutritionMap,
        ),
      ],
      estimatedNutrition: NutritionalSummary(
        calories: mealData['nutrition']['calories'] as int,
        protein: nutritionMap['protein'] ?? 0.0,
        carbs: nutritionMap['carbs'] ?? 0.0,
        fat: nutritionMap['fat'] ?? 0.0,
        fiber: nutritionMap['fiber'] ?? 0.0,
        sugar: nutritionMap['sugar'] ?? 0.0,
        sodium: nutritionMap['sodium'] ?? 0.0,
      ),
      source: PlannedMealSource.manual,
      notes: mealData['notes'] as String?,
    );
  }

  /// Get dynamic fallback meal data with extensive variety
  Map<String, dynamic> _getDynamicFallbackMeal(
    String mealType,
    int variationIndex,
  ) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSeed = (timestamp + variationIndex) % 1000;

    switch (mealType.toLowerCase()) {
      case 'breakfast':
        final breakfastOptions = [
          {
            'id': 'oatmeal_berries',
            'name': 'Steel Cut Oats with Mixed Berries',
            'quantity': 1,
            'unit': 'bowl',
            'nutrition': {'calories': 280, 'protein': 8, 'carbs': 52, 'fat': 6},
            'notes': 'Fiber-rich breakfast with antioxidants',
          },
          {
            'id': 'avocado_toast',
            'name': 'Avocado Toast with Hemp Seeds',
            'quantity': 2,
            'unit': 'slices',
            'nutrition': {
              'calories': 320,
              'protein': 12,
              'carbs': 28,
              'fat': 18,
            },
            'notes': 'Healthy fats and complete proteins',
          },
          {
            'id': 'protein_smoothie',
            'name': 'Green Protein Smoothie',
            'quantity': 1,
            'unit': 'glass',
            'nutrition': {
              'calories': 250,
              'protein': 25,
              'carbs': 20,
              'fat': 8,
            },
            'notes': 'Spinach, banana, protein powder blend',
          },
          {
            'id': 'chia_pudding',
            'name': 'Chia Seed Pudding with Mango',
            'quantity': 1,
            'unit': 'cup',
            'nutrition': {
              'calories': 220,
              'protein': 10,
              'carbs': 25,
              'fat': 12,
            },
            'notes': 'Omega-3 rich superfood breakfast',
          },
          {
            'id': 'quinoa_breakfast',
            'name': 'Breakfast Quinoa Bowl',
            'quantity': 1,
            'unit': 'bowl',
            'nutrition': {
              'calories': 300,
              'protein': 14,
              'carbs': 45,
              'fat': 8,
            },
            'notes': 'Complete protein grain with nuts',
          },
          {
            'id': 'egg_spinach',
            'name': 'Spinach and Mushroom Scrambled Eggs',
            'quantity': 3,
            'unit': 'eggs',
            'nutrition': {
              'calories': 260,
              'protein': 22,
              'carbs': 6,
              'fat': 16,
            },
            'notes': 'Vegetable-packed protein breakfast',
          },
          {
            'id': 'sweet_potato_hash',
            'name': 'Sweet Potato Hash with Poached Egg',
            'quantity': 1,
            'unit': 'serving',
            'nutrition': {
              'calories': 340,
              'protein': 16,
              'carbs': 38,
              'fat': 14,
            },
            'notes': 'Beta-carotene rich hearty breakfast',
          },
        ];
        return breakfastOptions[randomSeed % breakfastOptions.length];

      case 'lunch':
        final lunchOptions = [
          {
            'id': 'mediterranean_bowl',
            'name': 'Mediterranean Quinoa Bowl',
            'quantity': 1,
            'unit': 'bowl',
            'nutrition': {
              'calories': 420,
              'protein': 18,
              'carbs': 55,
              'fat': 16,
            },
            'notes': 'Olives, feta, cucumber, tomatoes',
          },
          {
            'id': 'asian_lettuce_wraps',
            'name': 'Asian Chicken Lettuce Wraps',
            'quantity': 4,
            'unit': 'wraps',
            'nutrition': {
              'calories': 280,
              'protein': 28,
              'carbs': 12,
              'fat': 14,
            },
            'notes': 'Low-carb protein-rich lunch',
          },
          {
            'id': 'lentil_soup',
            'name': 'Red Lentil and Vegetable Soup',
            'quantity': 1.5,
            'unit': 'cups',
            'nutrition': {
              'calories': 320,
              'protein': 18,
              'carbs': 52,
              'fat': 4,
            },
            'notes': 'Plant-based protein and fiber',
          },
          {
            'id': 'poke_bowl',
            'name': 'Tuna Poke Bowl with Brown Rice',
            'quantity': 1,
            'unit': 'bowl',
            'nutrition': {
              'calories': 450,
              'protein': 32,
              'carbs': 48,
              'fat': 16,
            },
            'notes': 'Fresh fish with complex carbs',
          },
          {
            'id': 'cauliflower_curry',
            'name': 'Chickpea and Cauliflower Curry',
            'quantity': 1,
            'unit': 'serving',
            'nutrition': {
              'calories': 380,
              'protein': 16,
              'carbs': 48,
              'fat': 14,
            },
            'notes': 'Spiced plant-based protein',
          },
          {
            'id': 'turkey_hummus_wrap',
            'name': 'Turkey and Hummus Whole Wheat Wrap',
            'quantity': 1,
            'unit': 'wrap',
            'nutrition': {
              'calories': 360,
              'protein': 26,
              'carbs': 32,
              'fat': 16,
            },
            'notes': 'Lean protein with plant proteins',
          },
        ];
        return lunchOptions[randomSeed % lunchOptions.length];

      case 'dinner':
        final dinnerOptions = [
          {
            'id': 'herb_salmon',
            'name': 'Herb-Crusted Salmon with Asparagus',
            'quantity': 1,
            'unit': 'fillet',
            'nutrition': {
              'calories': 480,
              'protein': 42,
              'carbs': 12,
              'fat': 28,
            },
            'notes': 'Omega-3 rich with green vegetables',
          },
          {
            'id': 'stuffed_peppers',
            'name': 'Turkey and Quinoa Stuffed Bell Peppers',
            'quantity': 2,
            'unit': 'peppers',
            'nutrition': {
              'calories': 420,
              'protein': 32,
              'carbs': 35,
              'fat': 18,
            },
            'notes': 'Complete meal in a vegetable',
          },
          {
            'id': 'stir_fry_tofu',
            'name': 'Sesame Tofu Vegetable Stir Fry',
            'quantity': 1,
            'unit': 'serving',
            'nutrition': {
              'calories': 380,
              'protein': 22,
              'carbs': 28,
              'fat': 20,
            },
            'notes': 'Plant-based protein with vegetables',
          },
          {
            'id': 'zucchini_lasagna',
            'name': 'Turkey and Zucchini Lasagna',
            'quantity': 1,
            'unit': 'slice',
            'nutrition': {
              'calories': 350,
              'protein': 28,
              'carbs': 18,
              'fat': 20,
            },
            'notes': 'Low-carb comfort food',
          },
          {
            'id': 'cod_vegetables',
            'name': 'Baked Cod with Roasted Root Vegetables',
            'quantity': 1,
            'unit': 'serving',
            'nutrition': {
              'calories': 320,
              'protein': 35,
              'carbs': 25,
              'fat': 8,
            },
            'notes': 'Lean white fish with complex carbs',
          },
          {
            'id': 'chicken_sweet_potato',
            'name': 'Grilled Chicken with Sweet Potato Mash',
            'quantity': 1,
            'unit': 'serving',
            'nutrition': {
              'calories': 410,
              'protein': 38,
              'carbs': 32,
              'fat': 14,
            },
            'notes': 'Beta-carotene and lean protein',
          },
        ];
        return dinnerOptions[randomSeed % dinnerOptions.length];

      default: // snack
        final snackOptions = [
          {
            'id': 'trail_mix',
            'name': 'Homemade Trail Mix',
            'quantity': 0.25,
            'unit': 'cup',
            'nutrition': {
              'calories': 180,
              'protein': 6,
              'carbs': 16,
              'fat': 12,
            },
            'notes': 'Nuts, seeds, and dried fruit',
          },
          {
            'id': 'protein_balls',
            'name': 'Almond Butter Protein Balls',
            'quantity': 2,
            'unit': 'pieces',
            'nutrition': {
              'calories': 160,
              'protein': 8,
              'carbs': 12,
              'fat': 10,
            },
            'notes': 'No-bake energy snack',
          },
          {
            'id': 'cottage_cheese_berries',
            'name': 'Cottage Cheese with Mixed Berries',
            'quantity': 0.5,
            'unit': 'cup',
            'nutrition': {
              'calories': 140,
              'protein': 14,
              'carbs': 15,
              'fat': 4,
            },
            'notes': 'High protein, low sugar',
          },
          {
            'id': 'veggie_chips_guac',
            'name': 'Baked Veggie Chips with Guacamole',
            'quantity': 1,
            'unit': 'serving',
            'nutrition': {
              'calories': 200,
              'protein': 4,
              'carbs': 20,
              'fat': 14,
            },
            'notes': 'Healthy fats and fiber',
          },
          {
            'id': 'dark_chocolate_almonds',
            'name': 'Dark Chocolate Covered Almonds',
            'quantity': 10,
            'unit': 'pieces',
            'nutrition': {
              'calories': 170,
              'protein': 6,
              'carbs': 10,
              'fat': 14,
            },
            'notes': 'Antioxidants and healthy fats',
          },
        ];
        return snackOptions[randomSeed % snackOptions.length];
    }
  }

  /// Convert common fractions to decimal numbers in JSON string
  String _convertFractionsToDecimals(String jsonString) {
    // Common fractions to decimal conversions
    final fractionMap = {
      r'"quantity":\s*1/2': '"quantity": 0.5',
      r'"quantity":\s*1/3': '"quantity": 0.33',
      r'"quantity":\s*2/3': '"quantity": 0.67',
      r'"quantity":\s*1/4': '"quantity": 0.25',
      r'"quantity":\s*3/4': '"quantity": 0.75',
      r'"quantity":\s*1/8': '"quantity": 0.125',
      r'"quantity":\s*3/8': '"quantity": 0.375',
      r'"quantity":\s*5/8': '"quantity": 0.625',
      r'"quantity":\s*7/8': '"quantity": 0.875',
      r'"quantity":\s*1/6': '"quantity": 0.17',
      r'"quantity":\s*5/6': '"quantity": 0.83',
      // Handle fractions in other numeric fields too
      r':\s*1/2': ': 0.5',
      r':\s*1/3': ': 0.33',
      r':\s*2/3': ': 0.67',
      r':\s*1/4': ': 0.25',
      r':\s*3/4': ': 0.75',
    };

    String result = jsonString;
    for (final entry in fractionMap.entries) {
      result = result.replaceAll(RegExp(entry.key), entry.value);
    }
    return result;
  }

  /// Helper to convert nutrition Map values to double
  Map<String, double> _convertNutritionToDoubles(
    Map<String, dynamic> nutrition,
  ) {
    final Map<String, double> result = {};

    for (final entry in nutrition.entries) {
      if (entry.value is int) {
        result[entry.key] = (entry.value as int).toDouble();
      } else if (entry.value is double) {
        result[entry.key] = entry.value as double;
      } else if (entry.value is num) {
        result[entry.key] = (entry.value as num).toDouble();
      } else {
        print(
          '⚠️ Warning: nutrition value for ${entry.key} is not a number: ${entry.value.runtimeType}',
        );
        // Default to 0.0 for non-numeric values
        result[entry.key] = 0.0;
      }
    }

    return result;
  }
}
