import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/base_repository.dart';
import '../../domain/entities/meal_suggestion.dart';
import '../../domain/repositories/meal_suggestion_repository.dart';
import '../models/meal_suggestion_model.dart';
import '../services/meal_suggestion_service.dart';

/// Implementation of the meal suggestion repository
@Injectable(as: MealSuggestionRepository)
class MealSuggestionRepositoryImpl extends BaseRepository
    implements MealSuggestionRepository {
  final FirebaseFirestore _firestore;
  final MealSuggestionService _mealSuggestionService;

  // Collection reference
  late final CollectionReference<Map<String, dynamic>> _suggestionsCollection;
  
  // Cache for suggestions to prevent duplicate calls
  final Map<String, List<MealSuggestion>> _cachedSuggestions = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  
  // Cache expiration time (5 minutes)
  final Duration _cacheExpiration = const Duration(minutes: 5);

  MealSuggestionRepositoryImpl(this._firestore, this._mealSuggestionService) {
    _suggestionsCollection = _firestore.collection('mealSuggestions');
  }

  @override
  Future<Either<Failure, List<MealSuggestion>>> getMealSuggestions(
    String userId,
    String mealType,
    Map<String, dynamic> preferences,
    Map<String, dynamic> nutritionalRequirements,
  ) async {
    return safeCall(() async {
      // Create a cache key based on user ID and meal type
      final cacheKey = '${userId}_$mealType';
      final forceRefresh = preferences['forceRefresh'] as bool? ?? false;
      
      // Check if we have a valid cached response
      if (!forceRefresh && _isCacheValid(cacheKey)) {
        print('✅ Using cached suggestions for $mealType');
        return _cachedSuggestions[cacheKey]!;
      }
      
      print('🔍 Cache miss or force refresh, generating new suggestions for $mealType');
      
      final today = DateTime.now();
      final limit = 5; // Default limit
      final List<MealSuggestion> suggestions = [];

      print(
        '🔍 Generating $limit meal suggestions for $mealType (1 AI + ${limit - 1} fallback)',
      );

      // Generate ONE AI suggestion first (to save API costs)
      try {
        print('🤖 Attempting to generate AI suggestion...');

        final aiPreferences = {
          ...preferences,
          'variationIndex': 0,
          'requestType': 'primary',
        };

        final primaryMeal = await _mealSuggestionService.getMealSuggestion(
          userId,
          mealType,
          today,
          aiPreferences,
        );

        // Convert to MealSuggestion entity
        final primarySuggestion = MealSuggestion(
          id: 'ai_suggestion_${DateTime.now().millisecondsSinceEpoch}',
          name: primaryMeal.items.isNotEmpty
              ? primaryMeal.items.first.name
              : 'AI Suggested $mealType',
          mealType: mealType,
          items: primaryMeal.items
              .map(
                (item) => SuggestedFoodItem(
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
          estimatedNutrition: primaryMeal.estimatedNutrition,
          source: SuggestionSource.ai,
          createdAt: DateTime.now(),
          description: primaryMeal.notes,
        );

        suggestions.add(primarySuggestion);
        print('✅ AI suggestion generated successfully');
      } catch (e) {
        print('❌ AI suggestion failed: $e');
        // Continue with fallback suggestions
      }

      // Generate remaining suggestions using fallback meals (NO AI calls)
      // This provides variety without expensive AI calls
      print(
        '🍽️ Generating ${limit - suggestions.length} fallback suggestions...',
      );
      for (var i = suggestions.length; i < limit; i++) {
        try {
          // Generate fallback meal suggestion directly without AI service call
          final fallbackSuggestion = _generateDirectFallbackMeal(mealType, i);

          suggestions.add(fallbackSuggestion);
        } catch (e) {
          print('❌ Error generating fallback suggestion $i: $e');
          continue;
        }
      }

      print(
        '✅ Generated ${suggestions.length} total suggestions (max 1 AI call)',
      );

      // Also fetch saved/favorited suggestions
      final savedSuggestions = await _getSavedSuggestions(userId, mealType);

      // Combine AI and saved suggestions
      final allSuggestions = [...suggestions, ...savedSuggestions];

      // Cache the results
      _cachedSuggestions[cacheKey] = suggestions;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return allSuggestions;
    });
  }

  @override
  Future<Either<Failure, MealSuggestion>> saveMealSuggestion(
    MealSuggestion suggestion,
  ) async {
    return safeCall(() async {
      // Convert to model
      final suggestionModel = MealSuggestionModel(
        id: suggestion.id,
        name: suggestion.name,
        mealType: suggestion.mealType,
        items: suggestion.items
            .map(
              (item) => SuggestedFoodItemModel.fromJson({
                'id': item.id,
                'name': item.name,
                'quantity': item.quantity,
                'unit': item.unit,
                'nutritionalValues': item.nutritionalValues,
                'imageUrl': item.imageUrl,
                'notes': item.notes,
              }),
            )
            .toList(),
        estimatedNutrition: suggestion.estimatedNutrition,
        source: suggestion.source,
        createdAt: suggestion.createdAt?.toIso8601String(),
        imageUrl: suggestion.imageUrl,
        description: suggestion.description,
        preparationTimeMinutes: suggestion.preparationTimeMinutes,
        attributes: suggestion.attributes,
        isFavorite: suggestion.isFavorite,
        userRating: suggestion.userRating,
      );

      // Save to Firestore
      final docRef = _suggestionsCollection.doc(suggestion.id);
      await docRef.set(suggestionModel.toFirestore());

      // Get the updated document with the generated ID
      final docSnapshot = await docRef.get();

      return MealSuggestionModel.fromFirestore(docSnapshot).toDomain();
    });
  }

  @override
  Future<Either<Failure, MealSuggestion>> getMealSuggestionById(
    String id,
  ) async {
    return safeCall(() async {
      final docSnapshot = await _suggestionsCollection.doc(id).get();

      if (!docSnapshot.exists) {
        throw Exception('Meal suggestion not found');
      }

      return MealSuggestionModel.fromFirestore(docSnapshot).toDomain();
    });
  }

  @override
  Future<Either<Failure, bool>> deleteMealSuggestion(String id) async {
    return safeCall(() async {
      await _suggestionsCollection.doc(id).delete();
      return true;
    });
  }

  @override
  Future<Either<Failure, List<MealSuggestion>>> getFavoriteMealSuggestions(
    String userId,
  ) async {
    return safeCall(() async {
      final querySnapshot = await _suggestionsCollection
          .where('userId', isEqualTo: userId)
          .where('isFavorite', isEqualTo: true)
          .get();

      final suggestions = querySnapshot.docs
          .map((doc) => MealSuggestionModel.fromFirestore(doc).toDomain())
          .toList();

      return suggestions;
    });
  }

  @override
  Future<Either<Failure, MealSuggestion>> rateMealSuggestion(
    String id,
    double rating,
  ) async {
    return safeCall(() async {
      final docRef = _suggestionsCollection.doc(id);
      await docRef.update({'userRating': rating});

      final docSnapshot = await docRef.get();
      return MealSuggestionModel.fromFirestore(docSnapshot).toDomain();
    });
  }

  @override
  Future<Either<Failure, List<MealSuggestion>>> getMealSuggestionsByCuisine(
    String userId,
    String cuisine,
    String mealType,
  ) async {
    return safeCall(() async {
      final querySnapshot = await _suggestionsCollection
          .where('userId', isEqualTo: userId)
          .where('mealType', isEqualTo: mealType)
          .where('cuisine', isEqualTo: cuisine)
          .limit(10)
          .get();

      final suggestions = querySnapshot.docs
          .map((doc) => MealSuggestionModel.fromFirestore(doc).toDomain())
          .toList();

      return suggestions;
    });
  }

  @override
  Future<Either<Failure, List<MealSuggestion>>> getPopularMealSuggestions(
    String mealType,
    int limit,
  ) async {
    return safeCall(() async {
      final querySnapshot = await _suggestionsCollection
          .where('mealType', isEqualTo: mealType)
          .orderBy('userRating', descending: true)
          .limit(limit)
          .get();

      final suggestions = querySnapshot.docs
          .map((doc) => MealSuggestionModel.fromFirestore(doc).toDomain())
          .toList();

      return suggestions;
    });
  }

  @override
  Future<Either<Failure, List<MealSuggestion>>> getSimilarMealSuggestions(
    String mealId,
    int limit,
  ) async {
    return safeCall(() async {
      // Get the original meal first
      final originalDoc = await _suggestionsCollection.doc(mealId).get();
      if (!originalDoc.exists) {
        throw Exception('Original meal not found');
      }

      final originalMeal = MealSuggestionModel.fromFirestore(
        originalDoc,
      ).toDomain();

      // Find similar meals by matching meal type and cuisine
      final querySnapshot = await _suggestionsCollection
          .where('mealType', isEqualTo: originalMeal.mealType)
          .limit(limit + 1) // Get one extra to exclude the original
          .get();

      final suggestions = querySnapshot.docs
          .where((doc) => doc.id != mealId) // Exclude the original meal
          .map((doc) => MealSuggestionModel.fromFirestore(doc).toDomain())
          .take(limit)
          .toList();

      return suggestions;
    });
  }

  // This method is not in the interface - removing it
  Future<Either<Failure, bool>> toggleFavoriteSuggestion(
    String suggestionId,
    bool isFavorite,
  ) async {
    return safeCall(() async {
      final docRef = _suggestionsCollection.doc(suggestionId);
      await docRef.update({'isFavorite': isFavorite});

      return true;
    });
  }

  /// Private method to get saved suggestions from Firestore
  Future<List<MealSuggestion>> _getSavedSuggestions(
    String userId,
    String mealType,
  ) async {
    try {
      final querySnapshot = await _suggestionsCollection
          .where('userId', isEqualTo: userId)
          .where('mealType', isEqualTo: mealType)
          .where('source', isEqualTo: 'saved')
          .limit(5)
          .get();

      final suggestions = querySnapshot.docs
          .map((doc) => MealSuggestionModel.fromFirestore(doc).toDomain())
          .toList();
          
      return suggestions;
    } catch (e) {
      print('Error fetching saved suggestions: $e');
      return []; // Return empty list on error
    }
  }

  /// Generate fallback meal directly without AI service calls
  MealSuggestion _generateDirectFallbackMeal(
    String mealType,
    int variationIndex,
  ) {
    final id =
        'fallback_${DateTime.now().millisecondsSinceEpoch}_$variationIndex';

    // Define fallback meals by type and variation
    final fallbackMeals = _getFallbackMealsByType(mealType);
    final selectedMeal = fallbackMeals[variationIndex % fallbackMeals.length];

    return MealSuggestion(
      id: id,
      name: selectedMeal['name'],
      mealType: mealType,
      items: selectedMeal['items'].map<SuggestedFoodItem>((item) {
        return SuggestedFoodItem(
          id: 'sfi_${item['name'].replaceAll(' ', '_').toLowerCase()}_$variationIndex',
          name: item['name'],
          quantity: item['quantity'],
          unit: item['unit'],
          nutritionalValues: item['nutrition'],
          imageUrl: null,
          notes: null,
        );
      }).toList(),
      estimatedNutrition: selectedMeal['totalNutrition'],
      source: SuggestionSource.personalized,
      createdAt: DateTime.now(),
      description: selectedMeal['description'],
    );
  }

  /// Get fallback meals by meal type
  List<Map<String, dynamic>> _getFallbackMealsByType(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return [
          {
            'name': 'Protein Scrambled Eggs',
            'description': 'High-protein breakfast with vegetables',
            'items': [
              {
                'name': 'Scrambled Eggs',
                'quantity': 2.0,
                'unit': 'large',
                'nutrition': {
                  'calories': 140,
                  'protein': 12,
                  'carbs': 1,
                  'fat': 10,
                },
              },
              {
                'name': 'Spinach',
                'quantity': 50.0,
                'unit': 'g',
                'nutrition': {
                  'calories': 12,
                  'protein': 1.5,
                  'carbs': 2,
                  'fat': 0.2,
                },
              },
              {
                'name': 'Whole Grain Toast',
                'quantity': 1.0,
                'unit': 'slice',
                'nutrition': {
                  'calories': 80,
                  'protein': 3,
                  'carbs': 14,
                  'fat': 1.5,
                },
              },
            ],
            'totalNutrition': {
              'calories': 232,
              'protein': 16.5,
              'carbs': 17,
              'fat': 11.7,
              'fiber': 3,
              'sugar': 3,
              'sodium': 350,
            },
          },
          {
            'name': 'Berry Smoothie Bowl',
            'description': 'Antioxidant-rich smoothie with protein',
            'items': [
              {
                'name': 'Mixed Berries',
                'quantity': 100.0,
                'unit': 'g',
                'nutrition': {
                  'calories': 57,
                  'protein': 1,
                  'carbs': 12,
                  'fat': 0.3,
                },
              },
              {
                'name': 'Greek Yogurt',
                'quantity': 150.0,
                'unit': 'g',
                'nutrition': {
                  'calories': 130,
                  'protein': 15,
                  'carbs': 6,
                  'fat': 4,
                },
              },
              {
                'name': 'Granola',
                'quantity': 30.0,
                'unit': 'g',
                'nutrition': {
                  'calories': 140,
                  'protein': 4,
                  'carbs': 18,
                  'fat': 6,
                },
              },
            ],
            'totalNutrition': {
              'calories': 327,
              'protein': 20,
              'carbs': 36,
              'fat': 10.3,
              'fiber': 6,
              'sugar': 22,
              'sodium': 80,
            },
          },
          {
            'name': 'Avocado Toast Deluxe',
            'description': 'Healthy fats with whole grains',
            'items': [
              {
                'name': 'Avocado',
                'quantity': 0.5,
                'unit': 'medium',
                'nutrition': {
                  'calories': 160,
                  'protein': 2,
                  'carbs': 9,
                  'fat': 15,
                },
              },
              {
                'name': 'Sourdough Bread',
                'quantity': 1.0,
                'unit': 'slice',
                'nutrition': {
                  'calories': 90,
                  'protein': 3,
                  'carbs': 18,
                  'fat': 1,
                },
              },
              {
                'name': 'Hemp Seeds',
                'quantity': 10.0,
                'unit': 'g',
                'nutrition': {
                  'calories': 55,
                  'protein': 3,
                  'carbs': 1,
                  'fat': 4.5,
                },
              },
            ],
            'totalNutrition': {
              'calories': 305,
              'protein': 8,
              'carbs': 28,
              'fat': 20.5,
              'fiber': 12,
              'sugar': 2,
              'sodium': 220,
            },
          },
          {
            'name': 'Oatmeal Power Bowl',
            'description': 'Fiber-rich oats with protein and healthy fats',
            'items': [
              {
                'name': 'Steel Cut Oats',
                'quantity': 40.0,
                'unit': 'g',
                'nutrition': {
                  'calories': 150,
                  'protein': 5,
                  'carbs': 27,
                  'fat': 3,
                },
              },
              {
                'name': 'Almond Butter',
                'quantity': 15.0,
                'unit': 'g',
                'nutrition': {
                  'calories': 90,
                  'protein': 3,
                  'carbs': 3,
                  'fat': 8,
                },
              },
              {
                'name': 'Banana',
                'quantity': 0.5,
                'unit': 'medium',
                'nutrition': {
                  'calories': 53,
                  'protein': 0.7,
                  'carbs': 13,
                  'fat': 0.2,
                },
              },
            ],
            'totalNutrition': {
              'calories': 293,
              'protein': 8.7,
              'carbs': 43,
              'fat': 11.2,
              'fiber': 8,
              'sugar': 12,
              'sodium': 120,
            },
          },
        ];

      case 'lunch':
        return [
          {
            'name': 'Mediterranean Quinoa Bowl',
            'description': 'Protein-rich quinoa with Mediterranean flavors',
            'items': [
              {
                'name': 'Cooked Quinoa',
                'quantity': 80.0,
                'unit': 'g',
                'nutrition': {
                  'calories': 120,
                  'protein': 4,
                  'carbs': 22,
                  'fat': 2,
                },
              },
              {
                'name': 'Grilled Chicken Breast',
                'quantity': 80.0,
                'unit': 'g',
                'nutrition': {
                  'calories': 140,
                  'protein': 26,
                  'carbs': 0,
                  'fat': 3,
                },
              },
              {
                'name': 'Cucumber',
                'quantity': 50.0,
                'unit': 'g',
                'nutrition': {
                  'calories': 8,
                  'protein': 0.3,
                  'carbs': 2,
                  'fat': 0.1,
                },
              },
              {
                'name': 'Cherry Tomatoes',
                'quantity': 60.0,
                'unit': 'g',
                'nutrition': {
                  'calories': 11,
                  'protein': 0.5,
                  'carbs': 2.4,
                  'fat': 0.1,
                },
              },
              {
                'name': 'Feta Cheese',
                'quantity': 30.0,
                'unit': 'g',
                'nutrition': {
                  'calories': 75,
                  'protein': 4,
                  'carbs': 1,
                  'fat': 6,
                },
              },
            ],
            'totalNutrition': {
              'calories': 354,
              'protein': 34.8,
              'carbs': 27.4,
              'fat': 11.2,
              'fiber': 4,
              'sugar': 6,
              'sodium': 480,
            },
          },
          {
            'name': 'Asian Vegetable Stir-Fry',
            'description': 'Colorful vegetables with tofu and brown rice',
            'items': [
              {
                'name': 'Brown Rice',
                'quantity': 60.0,
                'unit': 'g',
                'nutrition': {
                  'calories': 110,
                  'protein': 2.5,
                  'carbs': 23,
                  'fat': 1,
                },
              },
              {
                'name': 'Firm Tofu',
                'quantity': 100.0,
                'unit': 'g',
                'nutrition': {
                  'calories': 144,
                  'protein': 15,
                  'carbs': 3,
                  'fat': 9,
                },
              },
              {
                'name': 'Mixed Vegetables',
                'quantity': 150.0,
                'unit': 'g',
                'nutrition': {
                  'calories': 65,
                  'protein': 3,
                  'carbs': 13,
                  'fat': 0.5,
                },
              },
              {
                'name': 'Sesame Oil',
                'quantity': 5.0,
                'unit': 'ml',
                'nutrition': {
                  'calories': 40,
                  'protein': 0,
                  'carbs': 0,
                  'fat': 4.5,
                },
              },
            ],
            'totalNutrition': {
              'calories': 359,
              'protein': 20.5,
              'carbs': 39,
              'fat': 15,
              'fiber': 6,
              'sugar': 8,
              'sodium': 350,
            },
          },
          {
            'name': 'Turkey and Avocado Wrap',
            'description': 'Lean protein wrap with healthy fats',
            'items': [
              {
                'name': 'Whole Wheat Tortilla',
                'quantity': 1.0,
                'unit': 'large',
                'nutrition': {
                  'calories': 130,
                  'protein': 4,
                  'carbs': 22,
                  'fat': 3,
                },
              },
              {
                'name': 'Sliced Turkey',
                'quantity': 80.0,
                'unit': 'g',
                'nutrition': {
                  'calories': 120,
                  'protein': 20,
                  'carbs': 0,
                  'fat': 4,
                },
              },
              {
                'name': 'Avocado',
                'quantity': 0.3,
                'unit': 'medium',
                'nutrition': {
                  'calories': 96,
                  'protein': 1.2,
                  'carbs': 5.4,
                  'fat': 9,
                },
              },
              {
                'name': 'Mixed Greens',
                'quantity': 40.0,
                'unit': 'g',
                'nutrition': {
                  'calories': 8,
                  'protein': 0.8,
                  'carbs': 1.6,
                  'fat': 0.1,
                },
              },
            ],
            'totalNutrition': {
              'calories': 354,
              'protein': 26,
              'carbs': 29,
              'fat': 16.1,
              'fiber': 8,
              'sugar': 4,
              'sodium': 480,
            },
          },
          {
            'name': 'Lentil Power Salad',
            'description': 'Plant-based protein with fresh vegetables',
            'items': [
              {
                'name': 'Cooked Lentils',
                'quantity': 100.0,
                'unit': 'g',
                'nutrition': {
                  'calories': 116,
                  'protein': 9,
                  'carbs': 20,
                  'fat': 0.4,
                },
              },
              {
                'name': 'Mixed Greens',
                'quantity': 80.0,
                'unit': 'g',
                'nutrition': {
                  'calories': 16,
                  'protein': 1.6,
                  'carbs': 3.2,
                  'fat': 0.2,
                },
              },
              {
                'name': 'Roasted Chickpeas',
                'quantity': 40.0,
                'unit': 'g',
                'nutrition': {
                  'calories': 65,
                  'protein': 3,
                  'carbs': 11,
                  'fat': 1,
                },
              },
              {
                'name': 'Olive Oil Dressing',
                'quantity': 10.0,
                'unit': 'ml',
                'nutrition': {
                  'calories': 80,
                  'protein': 0,
                  'carbs': 0,
                  'fat': 9,
                },
              },
            ],
            'totalNutrition': {
              'calories': 277,
              'protein': 13.6,
              'carbs': 34.2,
              'fat': 10.6,
              'fiber': 12,
              'sugar': 6,
              'sodium': 280,
            },
          },
        ];

      case 'dinner':
        return [
          {
            'name': 'Baked Salmon with Vegetables',
            'description': 'Omega-3 rich salmon with roasted vegetables',
            'items': [
              {
                'name': 'Salmon Fillet',
                'quantity': 120.0,
                'unit': 'g',
                'nutrition': {
                  'calories': 206,
                  'protein': 28,
                  'carbs': 0,
                  'fat': 9,
                },
              },
              {
                'name': 'Roasted Sweet Potato',
                'quantity': 100.0,
                'unit': 'g',
                'nutrition': {
                  'calories': 90,
                  'protein': 2,
                  'carbs': 21,
                  'fat': 0.1,
                },
              },
              {
                'name': 'Steamed Broccoli',
                'quantity': 100.0,
                'unit': 'g',
                'nutrition': {
                  'calories': 34,
                  'protein': 3,
                  'carbs': 7,
                  'fat': 0.4,
                },
              },
              {
                'name': 'Olive Oil',
                'quantity': 5.0,
                'unit': 'ml',
                'nutrition': {
                  'calories': 40,
                  'protein': 0,
                  'carbs': 0,
                  'fat': 4.5,
                },
              },
            ],
            'totalNutrition': {
              'calories': 370,
              'protein': 33,
              'carbs': 28,
              'fat': 14,
              'fiber': 5,
              'sugar': 12,
              'sodium': 280,
            },
          },
          {
            'name': 'Lean Beef Stir-Fry',
            'description': 'High-protein beef with colorful vegetables',
            'items': [
              {
                'name': 'Lean Beef Strips',
                'quantity': 100.0,
                'unit': 'g',
                'nutrition': {
                  'calories': 180,
                  'protein': 26,
                  'carbs': 0,
                  'fat': 8,
                },
              },
              {
                'name': 'Bell Peppers',
                'quantity': 80.0,
                'unit': 'g',
                'nutrition': {
                  'calories': 20,
                  'protein': 0.8,
                  'carbs': 5,
                  'fat': 0.2,
                },
              },
              {
                'name': 'Snap Peas',
                'quantity': 60.0,
                'unit': 'g',
                'nutrition': {
                  'calories': 25,
                  'protein': 2,
                  'carbs': 5,
                  'fat': 0.1,
                },
              },
              {
                'name': 'Brown Rice',
                'quantity': 60.0,
                'unit': 'g',
                'nutrition': {
                  'calories': 110,
                  'protein': 2.5,
                  'carbs': 23,
                  'fat': 1,
                },
              },
            ],
            'totalNutrition': {
              'calories': 335,
              'protein': 31.3,
              'carbs': 33,
              'fat': 9.3,
              'fiber': 4,
              'sugar': 8,
              'sodium': 320,
            },
          },
          {
            'name': 'Mediterranean Stuffed Peppers',
            'description': 'Protein-packed peppers with Mediterranean flavors',
            'items': [
              {
                'name': 'Bell Peppers',
                'quantity': 150.0,
                'unit': 'g',
                'nutrition': {
                  'calories': 38,
                  'protein': 1.5,
                  'carbs': 9,
                  'fat': 0.3,
                },
              },
              {
                'name': 'Ground Turkey',
                'quantity': 80.0,
                'unit': 'g',
                'nutrition': {
                  'calories': 120,
                  'protein': 20,
                  'carbs': 0,
                  'fat': 4,
                },
              },
              {
                'name': 'Cooked Quinoa',
                'quantity': 60.0,
                'unit': 'g',
                'nutrition': {
                  'calories': 90,
                  'protein': 3,
                  'carbs': 16.5,
                  'fat': 1.5,
                },
              },
              {
                'name': 'Diced Tomatoes',
                'quantity': 60.0,
                'unit': 'g',
                'nutrition': {
                  'calories': 11,
                  'protein': 0.5,
                  'carbs': 2.4,
                  'fat': 0.1,
                },
              },
            ],
            'totalNutrition': {
              'calories': 259,
              'protein': 25,
              'carbs': 27.9,
              'fat': 5.9,
              'fiber': 6,
              'sugar': 10,
              'sodium': 240,
            },
          },
          {
            'name': 'Chickpea Curry Bowl',
            'description': 'Plant-based protein with aromatic spices',
            'items': [
              {
                'name': 'Cooked Chickpeas',
                'quantity': 120.0,
                'unit': 'g',
                'nutrition': {
                  'calories': 195,
                  'protein': 9,
                  'carbs': 33,
                  'fat': 3,
                },
              },
              {
                'name': 'Coconut Milk',
                'quantity': 50.0,
                'unit': 'ml',
                'nutrition': {
                  'calories': 115,
                  'protein': 1,
                  'carbs': 3,
                  'fat': 11,
                },
              },
              {
                'name': 'Spinach',
                'quantity': 60.0,
                'unit': 'g',
                'nutrition': {
                  'calories': 14,
                  'protein': 1.8,
                  'carbs': 2.4,
                  'fat': 0.2,
                },
              },
              {
                'name': 'Basmati Rice',
                'quantity': 50.0,
                'unit': 'g',
                'nutrition': {
                  'calories': 90,
                  'protein': 2,
                  'carbs': 20,
                  'fat': 0.5,
                },
              },
            ],
            'totalNutrition': {
              'calories': 414,
              'protein': 13.8,
              'carbs': 58.4,
              'fat': 14.7,
              'fiber': 8,
              'sugar': 6,
              'sodium': 380,
            },
          },
        ];

      default:
        return [
          {
            'name': 'Balanced Meal',
            'description': 'Well-rounded nutritional meal',
            'items': [
              {
                'name': 'Grilled Protein',
                'quantity': 100.0,
                'unit': 'g',
                'nutrition': {
                  'calories': 150,
                  'protein': 25,
                  'carbs': 0,
                  'fat': 5,
                },
              },
              {
                'name': 'Vegetables',
                'quantity': 150.0,
                'unit': 'g',
                'nutrition': {
                  'calories': 50,
                  'protein': 2,
                  'carbs': 10,
                  'fat': 0.5,
                },
              },
              {
                'name': 'Whole Grains',
                'quantity': 60.0,
                'unit': 'g',
                'nutrition': {
                  'calories': 120,
                  'protein': 3,
                  'carbs': 25,
                  'fat': 1,
                },
              },
            ],
            'totalNutrition': {
              'calories': 320,
              'protein': 30,
              'carbs': 35,
              'fat': 6.5,
              'fiber': 5,
              'sugar': 5,
              'sodium': 300,
            },
          },
        ];
    }
  }

  /// Check if cache for a given key is still valid
  bool _isCacheValid(String cacheKey) {
    if (!_cachedSuggestions.containsKey(cacheKey) || 
        !_cacheTimestamps.containsKey(cacheKey)) {
      return false;
    }
    
    final timestamp = _cacheTimestamps[cacheKey]!;
    final now = DateTime.now();
    return now.difference(timestamp) < _cacheExpiration;
  }
}