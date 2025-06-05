import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'dart:convert';
import 'dart:developer' as developer;

class MealSuggestion {
  final String name;
  final String description;
  final List<String> tags;
  final int estimatedCalories;
  final String mealType;

  MealSuggestion({
    required this.name,
    required this.description,
    required this.tags,
    required this.estimatedCalories,
    required this.mealType,
  });

  factory MealSuggestion.fromJson(Map<String, dynamic> json) {
    return MealSuggestion(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      estimatedCalories: json['estimatedCalories'] ?? 0,
      mealType: json['mealType'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'tags': tags,
      'estimatedCalories': estimatedCalories,
      'mealType': mealType,
    };
  }
}

class MealSuggestionsService {
  static FirebaseRemoteConfig? _remoteConfig;
  static List<MealSuggestion>? _remoteMeals;
  static DateTime? _lastFetch;
  
  // Cached fallback meals
  static final List<MealSuggestion> _defaultMeals = [
    // Breakfast suggestions
    MealSuggestion(
      name: 'Greek Yogurt with Berries',
      description: 'High-protein breakfast with fresh berries and honey',
      tags: ['high-protein', 'vegetarian', 'quick'],
      estimatedCalories: 200,
      mealType: 'Breakfast',
    ),
    MealSuggestion(
      name: 'Tofu Scramble with Spinach',
      description: 'Vegan protein-rich breakfast with vegetables',
      tags: ['vegan', 'high-protein', 'vegetarian'],
      estimatedCalories: 250,
      mealType: 'Breakfast',
    ),
    MealSuggestion(
      name: 'Oatmeal with Nuts and Seeds',
      description: 'Fiber-rich breakfast with healthy fats',
      tags: ['vegan', 'vegetarian', 'high-fiber'],
      estimatedCalories: 300,
      mealType: 'Breakfast',
    ),
    MealSuggestion(
      name: 'Avocado Toast with Egg',
      description: 'Healthy fats and protein on whole grain bread',
      tags: ['vegetarian', 'high-protein', 'healthy-fats'],
      estimatedCalories: 350,
      mealType: 'Breakfast',
    ),
    MealSuggestion(
      name: 'Protein Smoothie Bowl',
      description: 'Blended fruits with protein powder and toppings',
      tags: ['high-protein', 'quick', 'vegetarian'],
      estimatedCalories: 280,
      mealType: 'Breakfast',
    ),

    // Lunch suggestions
    MealSuggestion(
      name: 'Quinoa Buddha Bowl',
      description: 'Complete protein with mixed vegetables and tahini dressing',
      tags: ['vegan', 'vegetarian', 'high-protein', 'high-fiber'],
      estimatedCalories: 450,
      mealType: 'Lunch',
    ),
    MealSuggestion(
      name: 'Grilled Chicken Salad',
      description: 'Lean protein with mixed greens and olive oil dressing',
      tags: ['high-protein', 'low-carb', 'gluten-free'],
      estimatedCalories: 380,
      mealType: 'Lunch',
    ),
    MealSuggestion(
      name: 'Lentil and Vegetable Soup',
      description: 'Plant-based protein with seasonal vegetables',
      tags: ['vegan', 'vegetarian', 'high-fiber', 'high-protein'],
      estimatedCalories: 320,
      mealType: 'Lunch',
    ),
    MealSuggestion(
      name: 'Salmon and Sweet Potato',
      description: 'Omega-3 rich fish with complex carbohydrates',
      tags: ['high-protein', 'pescatarian', 'healthy-fats'],
      estimatedCalories: 420,
      mealType: 'Lunch',
    ),
    MealSuggestion(
      name: 'Chickpea Curry with Rice',
      description: 'Spiced legumes with brown rice',
      tags: ['vegan', 'vegetarian', 'high-protein', 'high-fiber'],
      estimatedCalories: 400,
      mealType: 'Lunch',
    ),

    // Dinner suggestions
    MealSuggestion(
      name: 'Lean Beef Stir-fry',
      description: 'Protein with mixed vegetables and minimal oil',
      tags: ['high-protein', 'low-carb'],
      estimatedCalories: 350,
      mealType: 'Dinner',
    ),
    MealSuggestion(
      name: 'Baked Cod with Vegetables',
      description: 'Lean white fish with roasted seasonal vegetables',
      tags: ['high-protein', 'pescatarian', 'low-carb'],
      estimatedCalories: 300,
      mealType: 'Dinner',
    ),
    MealSuggestion(
      name: 'Black Bean and Quinoa Bowl',
      description: 'Complete vegan protein with colorful vegetables',
      tags: ['vegan', 'vegetarian', 'high-protein', 'high-fiber'],
      estimatedCalories: 380,
      mealType: 'Dinner',
    ),
    MealSuggestion(
      name: 'Turkey and Vegetable Lettuce Wraps',
      description: 'Lean protein wrapped in fresh lettuce',
      tags: ['high-protein', 'low-carb', 'gluten-free'],
      estimatedCalories: 250,
      mealType: 'Dinner',
    ),
    MealSuggestion(
      name: 'Stuffed Bell Peppers',
      description: 'Vegetables stuffed with quinoa and plant protein',
      tags: ['vegetarian', 'high-fiber', 'high-protein'],
      estimatedCalories: 320,
      mealType: 'Dinner',
    ),

    // Snack suggestions
    MealSuggestion(
      name: 'Apple with Almond Butter',
      description: 'Fresh fruit with healthy fats and protein',
      tags: ['vegetarian', 'healthy-fats', 'quick'],
      estimatedCalories: 200,
      mealType: 'Snack',
    ),
    MealSuggestion(
      name: 'Hummus with Vegetables',
      description: 'Plant-based protein with fresh crunchy vegetables',
      tags: ['vegan', 'vegetarian', 'high-fiber'],
      estimatedCalories: 150,
      mealType: 'Snack',
    ),
    MealSuggestion(
      name: 'Mixed Nuts and Seeds',
      description: 'Healthy fats and protein for sustained energy',
      tags: ['vegan', 'vegetarian', 'healthy-fats', 'high-protein'],
      estimatedCalories: 180,
      mealType: 'Snack',
    ),
    MealSuggestion(
      name: 'Greek Yogurt with Cucumber',
      description: 'Protein-rich snack with refreshing vegetables',
      tags: ['vegetarian', 'high-protein', 'low-carb'],
      estimatedCalories: 120,
      mealType: 'Snack',
    ),
    MealSuggestion(
      name: 'Protein Energy Balls',
      description: 'Homemade snack with dates, nuts, and protein powder',
      tags: ['vegetarian', 'high-protein', 'quick'],
      estimatedCalories: 160,
      mealType: 'Snack',
    ),  ];

  // Initialize Remote Config for dynamic meal suggestions
  static Future<void> _initializeRemoteConfig() async {
    try {
      _remoteConfig = FirebaseRemoteConfig.instance;
      await _remoteConfig!.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      // Set default values
      await _remoteConfig!.setDefaults({
        'meal_suggestions_enabled': true,
        'custom_meal_suggestions': '',
        'suggestion_algorithm_version': 'v1',
        'max_suggestions_per_request': 5,
      });

      await _fetchRemoteConfig();
    } catch (e) {
      developer.log('Failed to initialize Remote Config: $e');
    }
  }

  static Future<void> _fetchRemoteConfig() async {
    try {
      if (_remoteConfig == null) return;
      
      // Check if we should fetch (not too frequently)
      if (_lastFetch != null && 
          DateTime.now().difference(_lastFetch!).inMinutes < 30) {
        return;
      }

      await _remoteConfig!.fetchAndActivate();
      _lastFetch = DateTime.now();

      // Load custom meal suggestions if available
      String customMealsJson = _remoteConfig!.getString('custom_meal_suggestions');
      if (customMealsJson.isNotEmpty) {
        try {
          List<dynamic> mealsData = json.decode(customMealsJson);
          _remoteMeals = mealsData
              .map((data) => MealSuggestion.fromJson(data))
              .toList();
          developer.log('Loaded ${_remoteMeals!.length} remote meal suggestions');
        } catch (e) {
          developer.log('Failed to parse remote meal suggestions: $e');
        }
      }
    } catch (e) {
      developer.log('Failed to fetch Remote Config: $e');
    }
  }

  // Get all available meals (remote + default)
  static List<MealSuggestion> _getAllMeals() {
    List<MealSuggestion> allMeals = List.from(_defaultMeals);
    if (_remoteMeals != null) {
      allMeals.addAll(_remoteMeals!);
    }
    return allMeals;
  }

  Future<Map<String, dynamic>?> _getUserProfile() async {
    // Note: This method should be refactored to accept Firebase instances
    // as parameters for better dependency injection
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>?;
      }
    } catch (e) {
      developer.log('Error getting user profile: $e');
    }
    return null;
  }

  List<String> _getUserTags(Map<String, dynamic>? userProfile) {
    List<String> tags = [];

    if (userProfile == null) return tags;

    // Add dietary preferences
    List<dynamic> preferences = userProfile['dietaryPreferences'] ?? [];
    for (String pref in preferences) {
      switch (pref.toLowerCase()) {
        case 'vegan':
          tags.add('vegan');
          break;
        case 'vegetarian':
          tags.add('vegetarian');
          break;
        case 'pescatarian':
          tags.add('pescatarian');
          break;
        case 'gluten-free':
          tags.add('gluten-free');
          break;
      }
    }

    // Add dietary goals
    String goal = userProfile['dietaryGoals'] ?? '';
    switch (goal.toLowerCase()) {
      case 'weight loss':
        tags.add('low-carb');
        break;
      case 'muscle gain':
        tags.add('high-protein');
        break;
      case 'maintain weight':
        tags.add('balanced');
        break;
    }

    return tags;
  }

  Future<List<MealSuggestion>> getMealSuggestions({
    required String mealType,
    int count = 3,
  }) async {
    try {
      // Initialize Remote Config if not already done
      if (_remoteConfig == null) {
        await _initializeRemoteConfig();
      } else {
        await _fetchRemoteConfig();
      }

      // Get max suggestions from Remote Config
      int maxSuggestions = _remoteConfig?.getInt('max_suggestions_per_request') ?? 5;
      count = count > maxSuggestions ? maxSuggestions : count;

      final userProfile = await _getUserProfile();
      final userTags = _getUserTags(userProfile);

      // Filter meals by meal type using enhanced meal list
      List<MealSuggestion> candidateMeals = _getAllMeals()
          .where((meal) => meal.mealType.toLowerCase() == mealType.toLowerCase())
          .toList();

      if (userTags.isEmpty) {
        // No user preferences, return random suggestions
        candidateMeals.shuffle();
        return candidateMeals.take(count).toList();
      }

      // Score meals based on matching tags
      List<MapEntry<MealSuggestion, int>> scoredMeals = candidateMeals.map((meal) {
        int score = 0;
        for (String userTag in userTags) {
          if (meal.tags.contains(userTag)) {
            score++;
          }
        }
        return MapEntry(meal, score);
      }).toList();

      // Sort by score (highest first)
      scoredMeals.sort((a, b) => b.value.compareTo(a.value));

      // Return top suggestions
      return scoredMeals
          .take(count)
          .map((entry) => entry.key)
          .toList();

    } catch (e) {
      developer.log('Error getting meal suggestions: $e');
      // Fallback to random suggestions using enhanced meal list
      List<MealSuggestion> fallback = _getAllMeals()
          .where((meal) => meal.mealType.toLowerCase() == mealType.toLowerCase())
          .toList();
      fallback.shuffle();
      return fallback.take(count).toList();
    }
  }

  Future<List<MealSuggestion>> getPersonalizedSuggestions({
    String? focus, // e.g., 'high-protein', 'low-carb'
    int count = 5,
  }) async {
    try {
      // Initialize Remote Config if not already done
      if (_remoteConfig == null) {
        await _initializeRemoteConfig();
      } else {
        await _fetchRemoteConfig();
      }

      // Get max suggestions from Remote Config
      int maxSuggestions = _remoteConfig?.getInt('max_suggestions_per_request') ?? 5;
      count = count > maxSuggestions ? maxSuggestions : count;

      final userProfile = await _getUserProfile();
      final userTags = _getUserTags(userProfile);

      List<String> searchTags = List.from(userTags);
      if (focus != null) {
        searchTags.add(focus);
      }

      if (searchTags.isEmpty) {
        // No criteria, return random suggestions from all meal types
        List<MealSuggestion> allMeals = _getAllMeals();
        allMeals.shuffle();
        return allMeals.take(count).toList();
      }

      // Score all meals based on matching tags using enhanced meal list
      List<MapEntry<MealSuggestion, int>> scoredMeals = _getAllMeals().map((meal) {
        int score = 0;
        for (String searchTag in searchTags) {
          if (meal.tags.contains(searchTag)) {
            score++;
          }
        }
        return MapEntry(meal, score);
      }).toList();

      // Filter out meals with score 0 if we have any matches
      var filteredMeals = scoredMeals.where((entry) => entry.value > 0).toList();
      if (filteredMeals.isEmpty) {
        filteredMeals = scoredMeals; // Use all if no matches
      }

      // Sort by score (highest first)
      filteredMeals.sort((a, b) => b.value.compareTo(a.value));

      // Return top suggestions
      return filteredMeals
          .take(count)
          .map((entry) => entry.key)
          .toList();

    } catch (e) {
      developer.log('Error getting personalized suggestions: $e');
      // Fallback to random suggestions using enhanced meal list
      List<MealSuggestion> fallback = _getAllMeals();
      fallback.shuffle();
      return fallback.take(count).toList();
    }
  }

  static List<String> getAvailableFocusOptions() {
    return [
      'high-protein',
      'low-carb',
      'high-fiber',
      'healthy-fats',
      'quick',
      'vegan',
      'vegetarian',
      'pescatarian',
      'gluten-free',
    ];
  }

  static String getFocusDisplayName(String focus) {
    switch (focus) {
      case 'high-protein':
        return 'High Protein';
      case 'low-carb':
        return 'Low Carb';
      case 'high-fiber':
        return 'High Fiber';
      case 'healthy-fats':
        return 'Healthy Fats';
      case 'quick':
        return 'Quick & Easy';
      case 'vegan':
        return 'Vegan';
      case 'vegetarian':
        return 'Vegetarian';
      case 'pescatarian':
        return 'Pescatarian';
      case 'gluten-free':
        return 'Gluten-Free';
      default:
        return focus;
    }
  }
}
