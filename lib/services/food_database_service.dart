import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:firebase_remote_config/firebase_remote_config.dart';

class FoodItem {
  final String id;
  final String name;
  final String description;
  final List<FoodNutrient> nutrients;
  final String? brandName;
  final String? upc;

  FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.nutrients,
    this.brandName,
    this.upc,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    // Ensure we have the required fdcId
    if (json['fdcId'] == null) {
      throw ArgumentError('FoodItem requires fdcId');
    }
    
    return FoodItem(
      id: json['fdcId'].toString(),
      name: json['description'] ?? '',
      description: json['description'] ?? '',
      nutrients: (json['foodNutrients'] as List<dynamic>?)
              ?.map((nutrient) {
                try {
                  return FoodNutrient.fromJson(nutrient as Map<String, dynamic>);
                } catch (e) {
                  developer.log('Error parsing nutrient: $e', name: 'FoodDatabaseService');
                  return null;
                }
              })
              .where((nutrient) => nutrient != null)
              .cast<FoodNutrient>()
              .toList() ??
          [],
      brandName: json['brandName'],
      upc: json['gtinUpc'],
    );
  }

  double getCalories() {
    return getNutrientValue(1008); // Energy (calories)
  }

  double getProtein() {
    return getNutrientValue(1003); // Protein
  }

  double getCarbohydrates() {
    return getNutrientValue(1005); // Carbohydrates
  }

  double getFat() {
    return getNutrientValue(1004); // Total lipid (fat)
  }

  double getNutrientValue(int nutrientId) {
    final nutrient = nutrients.firstWhere(
      (n) => n.nutrientId == nutrientId,
      orElse: () => FoodNutrient(
        nutrientId: nutrientId,
        nutrientName: '',
        value: 0.0,
        unitName: '',
      ),
    );
    return nutrient.value;
  }
}

class FoodNutrient {
  final int nutrientId;
  final String nutrientName;
  final double value;
  final String unitName;

  FoodNutrient({
    required this.nutrientId,
    required this.nutrientName,
    required this.value,
    required this.unitName,
  });

  factory FoodNutrient.fromJson(Map<String, dynamic> json) {
    return FoodNutrient(
      nutrientId: json['nutrientId'] ?? 0,
      nutrientName: json['nutrientName'] ?? '',
      value: double.tryParse(json['value']?.toString() ?? '0') ?? 0.0,
      unitName: json['unitName'] ?? '',
    );
  }
}

class ServingSize {
  final String description;
  final double gramWeight;

  ServingSize({
    required this.description,
    required this.gramWeight,
  });

  factory ServingSize.fromJson(Map<String, dynamic> json) {
    return ServingSize(
      description: json['description'] ?? '',
      gramWeight: (json['gramWeight'] ?? 100.0).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServingSize &&
          runtimeType == other.runtimeType &&
          description == other.description &&
          gramWeight == other.gramWeight;

  @override
  int get hashCode => description.hashCode ^ gramWeight.hashCode;

  @override
  String toString() => 'ServingSize(description: $description, gramWeight: $gramWeight)';
}

class FoodDatabaseService {
  static const String _baseUrl = 'https://api.nal.usda.gov/fdc/v1';
  late String _apiKey;
  
  FoodDatabaseService({String? apiKey}) {
    if (apiKey != null) {
      _apiKey = apiKey;
    } else {
      _initializeApiKey();
    }
  }

  void _initializeApiKey() {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      _apiKey = remoteConfig.getString('usda_api_key');
      
      // Fallback to demo key for testing (limited requests)
      if (_apiKey.isEmpty) {
        _apiKey = 'DEMO_KEY';
      }
    } catch (e) {
      // Firebase not initialized, use demo key
      developer.log('Firebase not initialized, using DEMO_KEY: $e');
      _apiKey = 'DEMO_KEY';
    }
  }

  Future<List<FoodItem>> searchFoods(String query, {int pageSize = 25}) async {
    if (query.trim().isEmpty) return [];

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/foods/search'),
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': _apiKey,
        },
        body: jsonEncode({
          'query': query.trim(),
          'pageSize': pageSize,
          'dataType': ['Foundation', 'SR Legacy', 'Branded'],
          'sortBy': 'dataType.keyword',
          'sortOrder': 'asc',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final foods = data['foods'] as List<dynamic>?;
        
        if (foods != null) {
          return foods.map((food) => FoodItem.fromJson(food)).toList();
        }
      } else if (response.statusCode == 403) {
        throw Exception('API key invalid or rate limit exceeded');
      } else {
        throw Exception('Failed to search foods: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error searching foods: $e', name: 'FoodDatabaseService');
      throw Exception('Failed to search foods: $e');
    }

    return [];
  }

  Future<FoodItem?> getFoodByUpc(String upc) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/foods/search'),
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': _apiKey,
        },
        body: jsonEncode({
          'query': upc,
          'pageSize': 1,
          'dataType': ['Branded'],
          'requireAllWords': true,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final foods = data['foods'] as List<dynamic>?;
        
        if (foods != null && foods.isNotEmpty) {
          // Check if any food has matching UPC
          for (final food in foods) {
            if (food['gtinUpc'] == upc) {
              return FoodItem.fromJson(food);
            }
          }
          // If no exact UPC match, return the first result
          return FoodItem.fromJson(foods.first);
        }
      }
    } catch (e) {
      developer.log('Error searching food by UPC: $e', name: 'FoodDatabaseService');
      throw Exception('Failed to find food by barcode: $e');
    }

    return null;
  }

  Future<FoodItem?> getFoodDetails(String fdcId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/food/$fdcId'),
        headers: {
          'X-API-Key': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return FoodItem.fromJson(data);
      }
    } catch (e) {
      developer.log('Error getting food details: $e', name: 'FoodDatabaseService');
      throw Exception('Failed to get food details: $e');
    }

    return null;
  }

  List<ServingSize> getCommonServingSizes() {
    return [
      ServingSize(description: '1 gram', gramWeight: 1.0),
      ServingSize(description: '1 ounce', gramWeight: 28.35),
      ServingSize(description: '100 grams', gramWeight: 100.0),
      ServingSize(description: '1 cup', gramWeight: 240.0),
      ServingSize(description: '1 tablespoon', gramWeight: 15.0),
      ServingSize(description: '1 teaspoon', gramWeight: 5.0),
      ServingSize(description: '1 medium piece', gramWeight: 150.0),
      ServingSize(description: '1 large piece', gramWeight: 200.0),
      ServingSize(description: '1 small piece', gramWeight: 100.0),
    ];
  }
}
