import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/base_repository.dart';
import '../../../../core/models/meal_models.dart' as meal_models;
import '../../domain/entities/meal_suggestion.dart';
import '../../domain/entities/meal_plan.dart';
import '../../../ai_meal_logging/data/services/gemini_ai_service.dart';

/// Service for generating single meal suggestions with rejection learning
@injectable
class SingleMealSuggestionService extends BaseRepository {
  final FirebaseFirestore _firestore;
  final GeminiAIService _geminiService;

  // Collection references
  late final CollectionReference<Map<String, dynamic>> _suggestionsCollection;
  late final CollectionReference<Map<String, dynamic>>
  _rejectionFeedbackCollection;

  SingleMealSuggestionService(this._firestore, this._geminiService) {
    _suggestionsCollection = _firestore.collection('mealSuggestions');
    _rejectionFeedbackCollection = _firestore.collection(
      'suggestionRejections',
    );
  }

  /// Generate a single personalized meal suggestion
  Future<MealSuggestion> generateSingleSuggestion({
    required String userId,
    required String mealType,
    required DateTime date,
    List<String> recentRejections = const [],
    String? rejectionReason,
  }) async {
    try {
      print('🍽️ Generating single $mealType suggestion for user $userId');

      // Get comprehensive user context
      final userContext = await _buildUserContext(userId, mealType, date);

      // Get recent rejections to avoid similar suggestions
      final rejectionContext = await _buildRejectionContext(
        userId,
        mealType,
        recentRejections,
        rejectionReason,
      );

      // Generate AI suggestion with full context
      final suggestion = await _generateAISuggestionWithContext(
        userContext,
        rejectionContext,
        mealType,
      );

      // Store suggestion for future learning
      await _storeSuggestionForLearning(userId, suggestion, mealType, date);

      return suggestion;
    } catch (e, stackTrace) {
      print('❌ Error generating single suggestion: $e');
      print('❌ Stack trace: $stackTrace');
      // Fallback to a basic suggestion if AI fails
      return _generateFallbackSuggestion(mealType);
    }
  }

  /// Record a rejection with feedback for learning
  Future<void> recordRejection({
    required String userId,
    required String suggestionId,
    required String mealType,
    String? reason,
    String? userNote,
  }) async {
    try {
      await _rejectionFeedbackCollection.add({
        'userId': userId,
        'suggestionId': suggestionId,
        'mealType': mealType,
        'reason': reason,
        'userNote': userNote,
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      print('📝 Recorded rejection feedback: $reason');
    } catch (e) {
      print('❌ Error recording rejection: $e');
    }
  }

  /// Build comprehensive user context for AI suggestions
  Future<Map<String, dynamic>> _buildUserContext(
    String userId,
    String mealType,
    DateTime date,
  ) async {
    try {
      // Get user profile
      final userProfile = await _getUserProfile(userId);

      // Get nutrition goals
      final nutritionGoals = await _getNutritionGoals(userId);

      // Get recent meals to avoid repetition
      final recentMeals = await _getRecentLoggedMeals(userId, days: 7);

      // Get favorite meals for preference learning
      final favoriteMeals = await _getFavoriteMeals(userId);

      // Get today's planned nutrition to fill gaps
      final todaysNutrition = await _getTodaysPlannedNutrition(userId, date);

      return {
        'userProfile': userProfile,
        'nutritionGoals': nutritionGoals,
        'recentMeals': recentMeals,
        'favoriteMeals': favoriteMeals,
        'todaysNutrition': todaysNutrition,
        'mealType': mealType,
        'date': date.toIso8601String(),
      };
    } catch (e) {
      print('❌ Error building user context: $e');
      return {};
    }
  }

  /// Build rejection context to improve future suggestions
  Future<Map<String, dynamic>> _buildRejectionContext(
    String userId,
    String mealType,
    List<String> recentRejections,
    String? rejectionReason,
  ) async {
    try {
      // Temporary: skip Firebase query to avoid index issues
      // TODO: Set up proper Firebase index later
      print('⚠️ Skipping rejection context query to avoid index requirement');

      return {
        'recentRejections': recentRejections,
        'currentRejectionReason': rejectionReason,
        'rejectionPatterns': <Map<String, dynamic>>[], // Empty for now
      };

      /* Original query (requires Firebase index):
      final recentRejectionData = await _rejectionFeedbackCollection
          .where('userId', isEqualTo: userId)
          .limit(50)
          .get();

      // Filter and sort in memory to avoid composite index
      final mealTypeRejections = recentRejectionData.docs
          .where((doc) {
            final data = doc.data();
            return data['mealType'] == mealType;
          })
          .toList();

      // Sort by rejectedAt in memory
      mealTypeRejections.sort((a, b) {
        final aTime = a.data()['rejectedAt'] as Timestamp?;
        final bTime = b.data()['rejectedAt'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime); // Descending order
      });

      final rejectionPatterns = mealTypeRejections
          .take(10)
          .map((doc) {
            final data = doc.data();
            return {
              'reason': data['reason'],
              'userNote': data['userNote'],
              'rejectedAt': data['rejectedAt'],
            };
          }).toList();

      return {
        'recentRejections': recentRejections,
        'currentRejectionReason': rejectionReason,
        'rejectionPatterns': rejectionPatterns,
      };
      */
    } catch (e) {
      print('❌ Error building rejection context: $e');
      return {};
    }
  }

  /// Generate AI suggestion with full context
  Future<MealSuggestion> _generateAISuggestionWithContext(
    Map<String, dynamic> userContext,
    Map<String, dynamic> rejectionContext,
    String mealType,
  ) async {
    final prompt = _buildEnhancedPrompt(
      userContext,
      rejectionContext,
      mealType,
    );

    try {
      final responseText = await _geminiService.generateMealSuggestion(prompt);
      final response = {'text': responseText};

      return _parseMealSuggestionFromResponse(response, mealType);
    } catch (e) {
      print('❌ AI suggestion failed: $e');
      throw e;
    }
  }

  /// Build enhanced prompt with user context and rejection learning
  String _buildEnhancedPrompt(
    Map<String, dynamic> userContext,
    Map<String, dynamic> rejectionContext,
    String mealType,
  ) {
    final userProfile = userContext['userProfile'] ?? {};
    final nutritionGoals = userContext['nutritionGoals'] ?? {};
    final recentMeals = userContext['recentMeals'] ?? [];
    final rejectionPatterns = rejectionContext['rejectionPatterns'] ?? [];

    return '''
You are a personalized nutrition coach. Generate ONE specific $mealType suggestion for this user.

USER PROFILE:
- Age: ${userProfile['age'] ?? 'Unknown'}
- Goal: ${userProfile['dietaryGoal'] ?? 'general health'}
- Activity Level: ${userProfile['activityLevel'] ?? 'moderate'}
- Dietary Preferences: ${userProfile['dietaryPreferences'] ?? 'none specified'}
- Allergies: ${userProfile['allergies'] ?? 'none'}

NUTRITION TARGETS:
- Daily Calories: ${nutritionGoals['targetCalories'] ?? 2000}
- Protein: ${nutritionGoals['targetProtein'] ?? 150}g
- Carbs: ${nutritionGoals['targetCarbs'] ?? 200}g
- Fat: ${nutritionGoals['targetFat'] ?? 70}g

RECENT MEALS (avoid repetition):
${_formatMealsList(recentMeals)}

LEARNING FROM REJECTIONS:
${_formatRejectionsList(rejectionPatterns)}

REQUIREMENTS:
1. Suggest ONE specific meal with exact ingredients and quantities
2. Ensure it fits their dietary goal and restrictions
3. Avoid recently eaten or rejected meal patterns
4. Target appropriate nutrition for $mealType
5. Make it practical and appealing

Format your response as JSON:
{
  "name": "Meal Name",
  "description": "Brief appetizing description",
  "ingredients": [
    {
      "name": "ingredient name",
      "quantity": "amount",
      "unit": "measurement"
    }
  ],
  "nutrition": {
    "calories": number,
    "protein": number,
    "carbs": number,
    "fat": number
  },
  "cookingTime": "X minutes",
  "difficulty": "easy/medium/hard",
  "tags": ["tag1", "tag2"]
}
''';
  }

  /// Parse AI response into MealSuggestion
  MealSuggestion _parseMealSuggestionFromResponse(
    Map<String, dynamic> response,
    String mealType,
  ) {
    try {
      // Try to parse JSON from AI response
      final content = response['text'] ?? '';
      print(
        '🔍 Parsing AI response content: ${content.substring(0, content.length.clamp(0, 200))}...',
      );

      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(content);

      if (jsonMatch != null) {
        final jsonString = jsonMatch.group(0)!;
        print(
          '🔍 Found JSON match: ${jsonString.substring(0, jsonString.length.clamp(0, 200))}...',
        );

        try {
          final jsonData = json.decode(jsonString);
          print('🔍 Decoded JSON data: $jsonData');
          print('🔍 JSON data type: ${jsonData.runtimeType}');

          if (jsonData is Map<String, dynamic>) {
            print('🔍 JSON data keys: ${jsonData.keys.toList()}');
            return _createMealSuggestionFromJson(jsonData, mealType);
          } else {
            print(
              '❌ JSON data is not a Map<String, dynamic>, got: ${jsonData.runtimeType}',
            );
          }
        } catch (jsonError, jsonStackTrace) {
          print('❌ JSON decode error: $jsonError');
          print('❌ JSON stack trace: $jsonStackTrace');
          print('❌ Raw JSON string: $jsonString');
        }
      }
    } catch (e, stackTrace) {
      print('❌ Error parsing AI response: $e');
      print('❌ Stack trace: $stackTrace');
    }

    // Fallback parsing if JSON fails
    print('🔄 Using fallback suggestion for $mealType');
    return _createFallbackFromResponse(response, mealType);
  }

  /// Create MealSuggestion from parsed JSON
  MealSuggestion _createMealSuggestionFromJson(
    Map<String, dynamic> data,
    String mealType,
  ) {
    try {
      print('🔍 Creating meal suggestion from JSON: $data');

      final ingredientsRaw = data['ingredients'];
      print(
        '🔍 Raw ingredients: $ingredientsRaw (type: ${ingredientsRaw.runtimeType})',
      );

      final ingredients = <dynamic>[];
      if (ingredientsRaw is List) {
        ingredients.addAll(ingredientsRaw);
      } else if (ingredientsRaw != null) {
        print(
          '⚠️ Ingredients is not a List, got: ${ingredientsRaw.runtimeType}',
        );
        // Try to convert to list if possible
        ingredients.add(ingredientsRaw);
      }

      print('🔍 Processing ${ingredients.length} ingredients');

      return MealSuggestion(
        id: 'suggestion_${DateTime.now().millisecondsSinceEpoch}',
        name: data['name']?.toString() ?? 'Suggested $mealType',
        mealType: mealType,
        items: ingredients.asMap().entries.map<SuggestedFoodItem>((entry) {
          final index = entry.key;
          final ingredient = entry.value;
          print(
            '🔍 Processing ingredient $index: $ingredient (type: ${ingredient.runtimeType})',
          );

          // Safe access to ingredient properties
          final ingredientMap = ingredient is Map<String, dynamic>
              ? ingredient
              : <String, dynamic>{};

          return SuggestedFoodItem(
            id: 'item_${DateTime.now().millisecondsSinceEpoch}_$index',
            name: ingredientMap['name']?.toString() ?? 'Unknown ingredient',
            quantity:
                double.tryParse(
                  ingredientMap['quantity']?.toString() ?? '1.0',
                ) ??
                1.0,
            unit: ingredientMap['unit']?.toString() ?? 'serving',
            nutritionalValues: {},
          );
        }).toList(),
        estimatedNutrition: _parseNutritionSafely(data['nutrition'], mealType),
        source: SuggestionSource.ai,
        createdAt: DateTime.now(),
        description:
            data['description']?.toString() ?? 'A nutritious $mealType option',
        preparationTimeMinutes: _parsePreparationTime(data['cookingTime']),
        attributes: {
          'difficulty': data['difficulty']?.toString() ?? 'easy',
          'tags': _parseTags(data['tags']),
        },
      );
    } catch (e, stackTrace) {
      print('❌ Error creating meal suggestion from JSON: $e');
      print('❌ Stack trace: $stackTrace');
      return _generateFallbackSuggestion(mealType);
    }
  }

  /// Safely parse nutrition data
  meal_models.NutritionalSummary _parseNutritionSafely(
    dynamic nutritionData,
    String mealType,
  ) {
    try {
      if (nutritionData is Map<String, dynamic>) {
        return meal_models.NutritionalSummary(
          calories: _parseIntSafely(nutritionData['calories'], 300),
          protein: _parseDoubleSafely(nutritionData['protein'], 20.0),
          carbs: _parseDoubleSafely(nutritionData['carbs'], 30.0),
          fat: _parseDoubleSafely(nutritionData['fat'], 10.0),
        );
      }
    } catch (e) {
      print('⚠️ Error parsing nutrition data: $e');
    }

    // Fallback nutrition values
    return meal_models.NutritionalSummary(
      calories: 300,
      protein: 20.0,
      carbs: 30.0,
      fat: 10.0,
    );
  }

  /// Safely parse integer values
  int _parseIntSafely(dynamic value, int fallback) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  /// Safely parse double values
  double _parseDoubleSafely(dynamic value, double fallback) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  /// Safely parse preparation time
  double? _parsePreparationTime(dynamic timeData) {
    if (timeData == null) return 15.0;

    final timeString = timeData.toString();
    final numericPart = timeString.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(numericPart) ?? 15.0;
  }

  /// Safely parse tags
  List<String> _parseTags(dynamic tagsData) {
    if (tagsData is List) {
      return tagsData.map((tag) => tag.toString()).toList();
    } else if (tagsData is String) {
      return [tagsData];
    }
    return [];
  }

  /// Generate fallback suggestion if AI fails
  MealSuggestion _generateFallbackSuggestion(String mealType) {
    final fallbackMeals = {
      'breakfast': {
        'name': 'Greek Yogurt with Berries',
        'description': 'Protein-rich breakfast with antioxidants',
        'calories': 250,
        'protein': 20.0,
      },
      'lunch': {
        'name': 'Grilled Chicken Salad',
        'description': 'Lean protein with fresh vegetables',
        'calories': 400,
        'protein': 35.0,
      },
      'dinner': {
        'name': 'Baked Salmon with Quinoa',
        'description': 'Omega-3 rich fish with complete protein grain',
        'calories': 500,
        'protein': 40.0,
      },
      'snack': {
        'name': 'Apple with Almond Butter',
        'description': 'Balanced snack with fiber and healthy fats',
        'calories': 150,
        'protein': 4.0,
      },
    };

    final meal = fallbackMeals[mealType] ?? fallbackMeals['snack']!;

    return MealSuggestion(
      id: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
      name: meal['name'] as String,
      mealType: mealType,
      items: [
        SuggestedFoodItem(
          id: 'fallback_item',
          name: meal['name'] as String,
          quantity: 1.0,
          unit: 'serving',
          nutritionalValues: {},
        ),
      ],
      estimatedNutrition: meal_models.NutritionalSummary(
        calories: meal['calories'] as int,
        protein: meal['protein'] as double,
        carbs: 20.0,
        fat: 8.0,
      ),
      source: SuggestionSource.personalized,
      createdAt: DateTime.now(),
      description: meal['description'] as String,
    );
  }

  /// Accept a suggestion and add it to the meal plan
  Future<void> acceptSuggestion({
    required String userId,
    required MealSuggestion suggestion,
    required String mealType,
    required DateTime date,
  }) async {
    try {
      print('✅ Adding accepted suggestion to meal plan: ${suggestion.name}');
      print('🔍 Suggestion ID: ${suggestion.id}');
      print('🔍 User ID: $userId');
      print('🔍 Meal Type: $mealType');
      print('🔍 Date: $date');

      // Create planned meal from the suggestion
      final plannedMeal = PlannedMeal(
        id: 'pm_${suggestion.id}_${DateTime.now().millisecondsSinceEpoch}',
        mealType: mealType,
        items: suggestion.items
            .map(
              (item) => PlannedFoodItem(
                id: item.id,
                name: item.name,
                quantity: item.quantity,
                unit: item.unit,
                nutritionalValues: item.nutritionalValues,
                imageUrl: item.imageUrl,
                notes: item.notes,
              ),
            )
            .toList(),
        estimatedNutrition: meal_models.NutritionalSummary(
          calories: suggestion.estimatedNutrition.calories,
          protein: suggestion.estimatedNutrition.protein,
          carbs: suggestion.estimatedNutrition.carbs,
          fat: suggestion.estimatedNutrition.fat,
          fiber: suggestion.estimatedNutrition.fiber,
          sugar: suggestion.estimatedNutrition.sugar,
          sodium: suggestion.estimatedNutrition.sodium,
        ),
        isCompleted: false,
        source: PlannedMealSource.suggested,
      );

      // Find or create an active meal plan for the user
      print('🔍 Finding or creating active meal plan...');
      MealPlan? activeMealPlan = await _findOrCreateActiveMealPlan(
        userId,
        date,
      );

      // Add the planned meal to the meal plan's structure
      final dateKey = DateTime(date.year, date.month, date.day);
      final dailyPlan = activeMealPlan.plannedMeals[dateKey];

      final DailyMealPlan updatedDailyPlan;
      if (dailyPlan != null) {
        // Update existing daily plan
        final updatedMeals = Map<String, PlannedMeal>.from(dailyPlan.meals);
        updatedMeals[mealType] = plannedMeal;
        updatedDailyPlan = dailyPlan.copyWith(meals: updatedMeals);
      } else {
        // Create new daily plan
        updatedDailyPlan = DailyMealPlan(
          id: 'dp_${dateKey.toIso8601String().split('T')[0]}_$userId',
          date: dateKey,
          meals: {mealType: plannedMeal},
        );
      }

      // Update the meal plan
      final updatedPlannedMeals = Map<DateTime, DailyMealPlan>.from(
        activeMealPlan.plannedMeals,
      );
      updatedPlannedMeals[dateKey] = updatedDailyPlan;

      final updatedMealPlan = activeMealPlan.copyWith(
        plannedMeals: updatedPlannedMeals,
        lastModifiedAt: DateTime.now(),
      );

      // Save the updated meal plan to Firestore
      print('🔍 Updating meal plan in Firestore...');
      await _updateMealPlanInFirestore(updatedMealPlan);
      print('✅ Meal plan updated successfully');

      // Update the suggestion to mark it as accepted
      print('🔍 Updating suggestion as accepted...');
      await _suggestionsCollection.doc(suggestion.id).set({
        'accepted': true,
        'acceptedAt': Timestamp.fromDate(DateTime.now()),
        'addedToMealPlan': true,
        'plannedMealId': plannedMeal.id,
        'mealPlanId': updatedMealPlan.id,
      }, SetOptions(merge: true));
      print('✅ Suggestion marked as accepted');

      print('✅ Successfully added suggestion to meal plan: ${plannedMeal.id}');
    } catch (e) {
      print('❌ Error accepting suggestion: $e');
      rethrow;
    }
  }

  /// Find or create an active meal plan for the user
  Future<MealPlan> _findOrCreateActiveMealPlan(
    String userId,
    DateTime date,
  ) async {
    try {
      // First, try to find an existing active meal plan
      final querySnapshot = await _firestore
          .collection('mealPlans')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        print('🔍 Found existing active meal plan');
        return _convertFirestoreDocToMealPlan(querySnapshot.docs.first);
      }

      // No active meal plan found, create a new one
      print('🔍 Creating new meal plan for user');
      return await _createNewMealPlan(userId, date);
    } catch (e) {
      print('❌ Error finding/creating meal plan: $e');
      rethrow;
    }
  }

  /// Create a new meal plan for the user
  Future<MealPlan> _createNewMealPlan(String userId, DateTime date) async {
    final id = 'mp_${DateTime.now().millisecondsSinceEpoch}_$userId';
    final startDate = DateTime(date.year, date.month, date.day);

    // Create empty daily plans for the week
    final Map<DateTime, DailyMealPlan> plannedMeals = {};
    for (int i = 0; i < 7; i++) {
      final planDate = startDate.add(Duration(days: i));
      final dailyPlanId =
          'dp_${planDate.toIso8601String().split('T')[0]}_$userId';

      plannedMeals[planDate] = DailyMealPlan(
        id: dailyPlanId,
        date: planDate,
        meals: {},
      );
    }

    final mealPlan = MealPlan(
      id: id,
      userId: userId,
      name: 'My Meal Plan - ${date.month}/${date.day}',
      createdAt: DateTime.now(),
      lastModifiedAt: DateTime.now(),
      plannedMeals: plannedMeals,
      isActive: true,
      source: MealPlanSource.user,
    );

    // Save to Firestore
    await _updateMealPlanInFirestore(mealPlan);
    print('✅ Created new meal plan: ${mealPlan.id}');

    return mealPlan;
  }

  /// Update meal plan in Firestore
  Future<void> _updateMealPlanInFirestore(MealPlan mealPlan) async {
    final data = {
      'id': mealPlan.id,
      'userId': mealPlan.userId,
      'name': mealPlan.name,
      'createdAt': Timestamp.fromDate(mealPlan.createdAt),
      'lastModifiedAt': Timestamp.fromDate(
        mealPlan.lastModifiedAt ?? DateTime.now(),
      ),
      'plannedMeals': _convertPlannedMealsToFirestore(mealPlan.plannedMeals),
      'description': mealPlan.description,
      'isActive': mealPlan.isActive,
      'source': mealPlan.source.toString().split('.').last,
      'metadata': mealPlan.metadata,
    };

    await _firestore.collection('mealPlans').doc(mealPlan.id).set(data);
  }

  /// Convert Firestore document to MealPlan
  MealPlan _convertFirestoreDocToMealPlan(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return MealPlan(
      id: data['id'] as String,
      userId: data['userId'] as String,
      name: data['name'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastModifiedAt: data['lastModifiedAt'] != null
          ? (data['lastModifiedAt'] as Timestamp).toDate()
          : null,
      plannedMeals: _convertFirestoreToPlannedMeals(data['plannedMeals'] ?? {}),
      description: data['description'] as String?,
      isActive: data['isActive'] as bool? ?? false,
      source: _parseMealPlanSource(data['source'] as String?),
      metadata: (data['metadata'] as Map<String, dynamic>?) ?? {},
    );
  }

  /// Convert PlannedMeals map to Firestore format
  Map<String, dynamic> _convertPlannedMealsToFirestore(
    Map<DateTime, DailyMealPlan> plannedMeals,
  ) {
    final Map<String, dynamic> result = {};

    plannedMeals.forEach((date, dailyPlan) {
      final dateString = date.toIso8601String().split('T')[0];
      result[dateString] = {
        'id': dailyPlan.id,
        'date': dateString,
        'meals': _convertMealsToFirestore(dailyPlan.meals),
        'isCompleted': dailyPlan.isCompleted,
        'notes': dailyPlan.notes,
      };
    });

    return result;
  }

  /// Convert meals map to Firestore format
  Map<String, dynamic> _convertMealsToFirestore(
    Map<String, PlannedMeal> meals,
  ) {
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

  /// Convert Firestore data to PlannedMeals map
  Map<DateTime, DailyMealPlan> _convertFirestoreToPlannedMeals(
    Map<String, dynamic> firestoreData,
  ) {
    final Map<DateTime, DailyMealPlan> result = {};

    firestoreData.forEach((dateString, dailyData) {
      final date = DateTime.parse(dateString);
      final data = dailyData as Map<String, dynamic>;

      result[date] = DailyMealPlan(
        id: data['id'] as String,
        date: date,
        meals: _convertFirestoreToMeals(data['meals'] ?? {}),
        isCompleted: data['isCompleted'] as bool? ?? false,
        notes: data['notes'] as String?,
      );
    });

    return result;
  }

  /// Convert Firestore data to meals map
  Map<String, PlannedMeal> _convertFirestoreToMeals(
    Map<String, dynamic> mealsData,
  ) {
    final Map<String, PlannedMeal> result = {};

    mealsData.forEach((mealType, mealData) {
      final data = mealData as Map<String, dynamic>;

      result[mealType] = PlannedMeal(
        id: data['id'] as String,
        mealType: data['mealType'] as String,
        items: (data['items'] as List)
            .map(
              (itemData) => PlannedFoodItem(
                id: itemData['id'] as String,
                name: itemData['name'] as String,
                quantity: (itemData['quantity'] as num).toDouble(),
                unit: itemData['unit'] as String,
                nutritionalValues: Map<String, double>.from(
                  itemData['nutritionalValues'] ?? {},
                ),
                recipeId: itemData['recipeId'] as String?,
                imageUrl: itemData['imageUrl'] as String?,
                notes: itemData['notes'] as String?,
              ),
            )
            .toList(),
        estimatedNutrition: meal_models.NutritionalSummary(
          calories: (data['estimatedNutrition']['calories'] as num).toInt(),
          protein: (data['estimatedNutrition']['protein'] as num).toDouble(),
          carbs: (data['estimatedNutrition']['carbs'] as num).toDouble(),
          fat: (data['estimatedNutrition']['fat'] as num).toDouble(),
          fiber:
              (data['estimatedNutrition']['fiber'] as num?)?.toDouble() ?? 0.0,
          sugar:
              (data['estimatedNutrition']['sugar'] as num?)?.toDouble() ?? 0.0,
          sodium:
              (data['estimatedNutrition']['sodium'] as num?)?.toDouble() ?? 0.0,
        ),
        isCompleted: data['isCompleted'] as bool? ?? false,
        completedAt: data['completedAt'] != null
            ? DateTime.tryParse(data['completedAt'] as String)
            : null,
        actualMealId: data['actualMealId'] as String?,
        notes: data['notes'] as String?,
        source: _parsePlannedMealSource(data['source'] as String?),
      );
    });

    return result;
  }

  /// Parse source from string
  PlannedMealSource _parsePlannedMealSource(String? sourceString) {
    if (sourceString == null) return PlannedMealSource.suggested;

    switch (sourceString.toLowerCase()) {
      case 'manual':
        return PlannedMealSource.manual;
      case 'suggested':
        return PlannedMealSource.suggested;
      case 'favorite':
        return PlannedMealSource.favorite;
      case 'recipe':
        return PlannedMealSource.recipe;
      default:
        return PlannedMealSource.suggested;
    }
  }

  /// Parse meal plan source from string
  MealPlanSource _parseMealPlanSource(String? sourceString) {
    if (sourceString == null) return MealPlanSource.ai;

    switch (sourceString.toLowerCase()) {
      case 'user':
        return MealPlanSource.user;
      case 'ai':
        return MealPlanSource.ai;
      case 'dietitian':
        return MealPlanSource.dietitian;
      case 'template':
        return MealPlanSource.template;
      default:
        return MealPlanSource.ai;
    }
  }

  /// Format rejections list for AI prompt
  String _formatRejectionsList(List<dynamic> rejectionPatterns) {
    if (rejectionPatterns.isEmpty) {
      return 'No previous rejections to learn from.';
    }

    try {
      return rejectionPatterns
          .map((rejection) {
            if (rejection is Map<String, dynamic>) {
              final reason = rejection['reason'] ?? 'unspecified';
              final userNote = rejection['userNote'] ?? '';
              return '- Rejected because: $reason${userNote.isNotEmpty ? ' - $userNote' : ''}';
            } else {
              return '- ${rejection.toString()}';
            }
          })
          .join('\n');
    } catch (e) {
      print('❌ Error formatting rejections list: $e');
      return 'No previous rejections (formatting error)';
    }
  }

  /// Store suggestion for learning purposes
  Future<void> _storeSuggestionForLearning(
    String userId,
    MealSuggestion suggestion,
    String mealType,
    DateTime date,
  ) async {
    try {
      // Convert suggestion to Firestore-compatible format
      final suggestionData = {
        'id': suggestion.id,
        'name': suggestion.name,
        'mealType': suggestion.mealType,
        'description': suggestion.description,
        'imageUrl': suggestion.imageUrl,
        'preparationTimeMinutes': suggestion.preparationTimeMinutes,
        'isFavorite': suggestion.isFavorite,
        'userRating': suggestion.userRating,
        'source': suggestion.source.toString().split('.').last,
        'createdAt': suggestion.createdAt?.toIso8601String(),
        'attributes': suggestion.attributes,
        'items': suggestion.items
            .map(
              (item) => {
                'id': item.id,
                'name': item.name,
                'quantity': item.quantity,
                'unit': item.unit,
                'nutritionalValues': item.nutritionalValues,
                'alternativeFor': item.alternativeFor,
                'alternatives': item.alternatives,
                'imageUrl': item.imageUrl,
                'notes': item.notes,
                'metadata': item.metadata,
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
      };

      await _suggestionsCollection.doc(suggestion.id).set({
        'id': suggestion.id,
        'userId': userId,
        'mealType': mealType,
        'date': date.toIso8601String(),
        'suggestion': suggestionData,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✅ Stored suggestion ${suggestion.id} for learning');
    } catch (e) {
      print('❌ Error storing suggestion for learning: $e');
    }
  }

  /// Get user profile (placeholder implementation)
  Future<Map<String, dynamic>> _getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('userProfiles').doc(userId).get();
      if (doc.exists) {
        return doc.data() ?? {};
      }
    } catch (e) {
      print('❌ Error getting user profile: $e');
    }

    // Return default profile if not found
    return {
      'age': 30,
      'dietaryGoal': 'maintain',
      'activityLevel': 'moderate',
      'dietaryPreferences': [],
      'allergies': [],
    };
  }

  /// Get nutrition goals (placeholder implementation)
  Future<Map<String, dynamic>> _getNutritionGoals(String userId) async {
    try {
      final doc = await _firestore
          .collection('nutritionGoals')
          .doc(userId)
          .get();
      if (doc.exists) {
        return doc.data() ?? {};
      }
    } catch (e) {
      print('❌ Error getting nutrition goals: $e');
    }

    // Return default goals if not found
    return {
      'targetCalories': 2000,
      'targetProtein': 150,
      'targetCarbs': 200,
      'targetFat': 70,
    };
  }

  /// Get recent logged meals (placeholder implementation)
  Future<List<Map<String, dynamic>>> _getRecentLoggedMeals(
    String userId, {
    int days = 7,
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      final querySnapshot = await _firestore
          .collection('mealHistory')
          .where('userId', isEqualTo: userId)
          .where('loggedAt', isGreaterThan: Timestamp.fromDate(cutoffDate))
          .orderBy('loggedAt', descending: true)
          .limit(20)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('❌ Error getting recent meals: $e');
      return [];
    }
  }

  /// Get favorite meals (placeholder implementation)
  Future<List<Map<String, dynamic>>> _getFavoriteMeals(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('favoriteMeals')
          .where('userId', isEqualTo: userId)
          .limit(10)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('❌ Error getting favorite meals: $e');
      return [];
    }
  }

  /// Get today's planned nutrition (placeholder implementation)
  Future<Map<String, dynamic>> _getTodaysPlannedNutrition(
    String userId,
    DateTime date,
  ) async {
    try {
      // This would typically calculate from existing planned meals for today
      return {'calories': 0, 'protein': 0.0, 'carbs': 0.0, 'fat': 0.0};
    } catch (e) {
      print('❌ Error getting today\'s nutrition: $e');
      return {'calories': 0, 'protein': 0.0, 'carbs': 0.0, 'fat': 0.0};
    }
  }

  /// Format meals list for AI prompt
  String _formatMealsList(List<Map<String, dynamic>> meals) {
    if (meals.isEmpty) {
      return 'No recent meals logged.';
    }

    try {
      return meals
          .take(5)
          .map((meal) {
            final description = meal['description'] ?? 'Unknown meal';
            final loggedAt = meal['loggedAt'];
            String timeStr = 'Unknown time';

            if (loggedAt is Timestamp) {
              final date = loggedAt.toDate();
              timeStr = '${date.month}/${date.day}';
            }

            return '- $description ($timeStr)';
          })
          .join('\n');
    } catch (e) {
      print('❌ Error formatting meals list: $e');
      return 'Recent meals available (formatting error)';
    }
  }

  /// Create fallback response when AI fails
  MealSuggestion _createFallbackFromResponse(
    Map<String, dynamic> response,
    String mealType,
  ) {
    final fallbackMeals = {
      'breakfast': {
        'name': 'Oatmeal with Berries',
        'description':
            'Nutritious breakfast with whole grains and antioxidants',
        'items': [
          {'name': 'Rolled oats', 'quantity': 1.0, 'unit': 'cup'},
          {'name': 'Mixed berries', 'quantity': 0.5, 'unit': 'cup'},
          {'name': 'Almond milk', 'quantity': 1.0, 'unit': 'cup'},
        ],
        'nutrition': {
          'calories': 350,
          'protein': 12.0,
          'carbs': 65.0,
          'fat': 8.0,
        },
      },
      'lunch': {
        'name': 'Grilled Chicken Salad',
        'description': 'Protein-rich salad with mixed greens',
        'items': [
          {'name': 'Chicken breast', 'quantity': 4.0, 'unit': 'oz'},
          {'name': 'Mixed greens', 'quantity': 2.0, 'unit': 'cups'},
          {'name': 'Olive oil', 'quantity': 1.0, 'unit': 'tbsp'},
        ],
        'nutrition': {
          'calories': 280,
          'protein': 35.0,
          'carbs': 8.0,
          'fat': 12.0,
        },
      },
      'dinner': {
        'name': 'Baked Salmon with Vegetables',
        'description': 'Omega-3 rich fish with roasted vegetables',
        'items': [
          {'name': 'Salmon fillet', 'quantity': 5.0, 'unit': 'oz'},
          {'name': 'Broccoli', 'quantity': 1.0, 'unit': 'cup'},
          {'name': 'Sweet potato', 'quantity': 1.0, 'unit': 'medium'},
        ],
        'nutrition': {
          'calories': 420,
          'protein': 40.0,
          'carbs': 35.0,
          'fat': 15.0,
        },
      },
    };

    final fallback = fallbackMeals[mealType] ?? fallbackMeals['lunch']!;
    final nutrition = fallback['nutrition'] as Map<String, dynamic>;

    return MealSuggestion(
      id: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
      name: fallback['name'] as String,
      description: fallback['description'] as String,
      mealType: mealType,
      items: (fallback['items'] as List)
          .map(
            (item) => SuggestedFoodItem(
              id: 'item_${DateTime.now().millisecondsSinceEpoch}_${item['name']}',
              name: item['name'] as String,
              quantity: item['quantity'] as double,
              unit: item['unit'] as String,
            ),
          )
          .toList(),
      estimatedNutrition: meal_models.NutritionalSummary(
        calories: nutrition['calories'] as int,
        protein: nutrition['protein'] as double,
        carbs: nutrition['carbs'] as double,
        fat: nutrition['fat'] as double,
      ),
      source: SuggestionSource.ai,
      createdAt: DateTime.now(),
      attributes: {
        'cookingTime': '15-20 minutes',
        'difficulty': 'easy',
        'tags': ['healthy', 'balanced'],
      },
    );
  }

  // Add missing methods at the end of class
}
