import 'package:flutter_test/flutter_test.dart';
import 'package:nutrivision/services/food_database_service.dart';

void main() {
  group('FoodDatabaseService', () {
    late FoodDatabaseService service;

    setUp(() {
      service = FoodDatabaseService();
    });

    test('should parse food nutrients correctly', () {
      // Test the fixed JSON parsing
      final json = {
        'nutrientId': 1087,
        'nutrientName': 'Calcium, Ca',
        'value': 10.5,
        'unitName': 'MG',
      };

      final nutrient = FoodNutrient.fromJson(json);

      expect(nutrient.nutrientId, equals(1087));
      expect(nutrient.nutrientName, equals('Calcium, Ca'));
      expect(nutrient.value, equals(10.5));
      expect(nutrient.unitName, equals('MG'));
    });

    test('should handle null values in nutrient JSON', () {
      final json = <String, dynamic>{
        'nutrientId': null,
        'nutrientName': null,
        'value': null,
        'unitName': null,
      };

      final nutrient = FoodNutrient.fromJson(json);

      expect(nutrient.nutrientId, equals(0));
      expect(nutrient.nutrientName, equals(''));
      expect(nutrient.value, equals(0.0));
      expect(nutrient.unitName, equals(''));
    });

    test('should parse food item correctly', () {
      final json = {
        'fdcId': 123456,
        'description': 'Test Food',
        'brandName': 'Test Brand',
        'gtinUpc': '123456789',
        'foodNutrients': [
          {
            'nutrientId': 1008,
            'nutrientName': 'Energy',
            'value': 100.0,
            'unitName': 'kcal',
          }
        ],
      };

      final foodItem = FoodItem.fromJson(json);

      expect(foodItem.id, equals('123456'));
      expect(foodItem.name, equals('Test Food'));
      expect(foodItem.description, equals('Test Food'));
      expect(foodItem.brandName, equals('Test Brand'));
      expect(foodItem.upc, equals('123456789'));
      expect(foodItem.nutrients, hasLength(1));
      expect(foodItem.getCalories(), equals(100.0));
    });

    test('should handle missing fdcId', () {
      final json = <String, dynamic>{
        'description': 'Test Food',
      };

      expect(() => FoodItem.fromJson(json), throwsArgumentError);
    });

    test('should handle ServingSize equality correctly', () {
      final serving1 = ServingSize(description: '100 grams', gramWeight: 100.0);
      final serving2 = ServingSize(description: '100 grams', gramWeight: 100.0);
      final serving3 = ServingSize(description: '1 cup', gramWeight: 240.0);

      expect(serving1, equals(serving2));
      expect(serving1, isNot(equals(serving3)));
      expect(serving1.hashCode, equals(serving2.hashCode));
      expect(serving1.hashCode, isNot(equals(serving3.hashCode)));
    });

    test('should get common serving sizes consistently', () {
      final servingSizes1 = service.getCommonServingSizes();
      final servingSizes2 = service.getCommonServingSizes();
      
      expect(servingSizes1.length, equals(servingSizes2.length));
      
      // Check that corresponding items are equal
      for (int i = 0; i < servingSizes1.length; i++) {
        expect(servingSizes1[i], equals(servingSizes2[i]));
      }
    });
  });
}
