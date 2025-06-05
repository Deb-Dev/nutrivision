import 'dart:developer';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/ai_meal_recognition.dart';
import '../../domain/repositories/ai_meal_logging_repository.dart';
import '../services/gemini_ai_service.dart';
import '../models/ai_meal_models.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/base_repository.dart';
import '../../../../core/di/injection.dart';
import '../../../../services/food_database_service.dart' as legacy;

@Injectable(as: AIMealLoggingRepository)
class AIMealLoggingRepositoryImpl extends BaseRepository
    implements AIMealLoggingRepository {
  final GeminiAIService _aiService;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AIMealLoggingRepositoryImpl(this._aiService, this._firestore, this._auth);

  @override
  Future<Either<Failure, AIMealRecognitionResult>> analyzeMealPhoto({
    required File imageFile,
    String? mealType,
  }) async {
    log('🗃️ [REPOSITORY] analyzeMealPhoto() - Starting repository call');
    log('📁 [REPOSITORY] Image file path: ${imageFile.path}');
    log('🍽️ [REPOSITORY] Meal type: $mealType');

    return safeCall(() async {
      log('🔄 [REPOSITORY] Calling AI service...');
      final result = await _aiService.analyzeMealPhoto(imageFile);
      log(
        '✅ [REPOSITORY] AI service returned result: ${result.isSuccessful ? 'SUCCESS' : 'FAILED'}',
      );
      if (result.isSuccessful) {
        log(
          '📊 [REPOSITORY] Found ${result.recognizedItems.length} recognized items',
        );
      } else {
        log('❌ [REPOSITORY] Error: ${result.errorMessage}');
      }
      return result;
    });
  }

  @override
  Future<Either<Failure, AIMealLog>> logAIMeal({
    required List<ConfirmedMealItem> confirmedItems,
    required String imageId,
    required AIMealRecognitionResult originalAnalysis,
    required String mealType,
    String? notes,
  }) async {
    log('🗃️ [REPOSITORY] logAIMeal() - Starting meal save');
    log('📋 [REPOSITORY] Confirmed items count: ${confirmedItems.length}');
    log('📷 [REPOSITORY] Image ID: $imageId');
    log('🍽️ [REPOSITORY] Meal type: $mealType');

    return safeCall(() async {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      log('👤 [REPOSITORY] User authenticated: ${user.uid}');

      // Calculate total nutrition
      log('🔢 [REPOSITORY] Calculating total nutrition...');
      final totalNutrition = _calculateTotalNutrition(confirmedItems);
      log(
        '📊 [REPOSITORY] Total nutrition calculated: ${totalNutrition.calories} calories',
      );

      // Create meal log entity
      log('📝 [REPOSITORY] Creating meal log object...');
      final mealLog = AIMealLog(
        id: '', // Will be set by Firestore
        items: confirmedItems,
        loggedAt: DateTime.now(),
        imageId: imageId,
        originalAnalysis: originalAnalysis,
        totalNutrition: totalNutrition,
        mealType: mealType,
        notes: notes,
      );

      try {
        log('� [REPOSITORY] Converting to Firestore model...');
        // Convert to model for proper Firestore serialization
        final mealLogModel = AIMealLogModel.fromEntity(mealLog);

        // Convert to Firestore data
        log('� [REPOSITORY] Preparing Firestore data...');
        final firestoreData = mealLogModel.toFirestore();

        log('💾 [REPOSITORY] Saving to Firestore...');
        final docRef = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('ai_meal_logs')
            .add(firestoreData);

        log('✅ [REPOSITORY] Successfully saved with ID: ${docRef.id}');

        // Return with generated ID
        return mealLog.copyWith(id: docRef.id);
      } catch (e, stackTrace) {
        log('❌ [REPOSITORY] Error during Firestore save: $e');
        log('❌ [REPOSITORY] Stack trace: $stackTrace');
        rethrow;
      }
    });
  }

  @override
  Future<Either<Failure, List<AIMealLog>>> getAIMealLogs({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    log(
      '🗃️ [REPOSITORY] getAIMealLogs() - Fetching logs from ${startDate.toIso8601String()} to ${endDate.toIso8601String()}',
    );

    return safeCall(() async {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      log('👤 [REPOSITORY] User authenticated: ${user.uid}');

      try {
        log('🔍 [REPOSITORY] Querying Firestore for meal logs...');
        final query = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('ai_meal_logs')
            .where(
              'loggedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
            )
            .where('loggedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
            .orderBy('loggedAt', descending: true)
            .get();

        log('✅ [REPOSITORY] Found ${query.docs.length} meal logs');

        final mealLogs = query.docs.map((doc) {
          // Use the model conversion pattern for proper deserialization
          return AIMealLogModel.fromFirestore(doc).toEntity();
        }).toList();

        log(
          '🔄 [REPOSITORY] Successfully converted ${mealLogs.length} meal logs to entities',
        );
        return mealLogs;
      } catch (e, stackTrace) {
        log('❌ [REPOSITORY] Error fetching meal logs: $e');
        log('❌ [REPOSITORY] Stack trace: $stackTrace');
        rethrow;
      }
    });
  }

  @override
  Future<Either<Failure, AIMealLog>> getAIMealLogById(String id) async {
    log('🗃️ [REPOSITORY] getAIMealLogById() - Fetching log with ID: $id');

    return safeCall(() async {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      log('👤 [REPOSITORY] User authenticated: ${user.uid}');

      try {
        log('🔍 [REPOSITORY] Querying Firestore for meal log...');
        final doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('ai_meal_logs')
            .doc(id)
            .get();

        if (!doc.exists) {
          log('❌ [REPOSITORY] Meal log not found');
          throw Exception('Meal log not found');
        }

        log('✅ [REPOSITORY] Found meal log, converting to entity');
        // Use the model conversion pattern for proper deserialization
        return AIMealLogModel.fromFirestore(doc).toEntity();
      } catch (e, stackTrace) {
        log('❌ [REPOSITORY] Error fetching meal log: $e');
        log('❌ [REPOSITORY] Stack trace: $stackTrace');
        rethrow;
      }
    });
  }

  @override
  Future<Either<Failure, AIMealLog>> updateAIMealLog({
    required String id,
    required List<ConfirmedMealItem> confirmedItems,
    String? notes,
  }) async {
    return safeCall(() async {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Calculate new total nutrition
      final totalNutrition = _calculateTotalNutrition(confirmedItems);

      try {
        log(
          '🔄 [REPOSITORY] Converting confirmed items to Firestore models...',
        );
        // Convert entities to models for proper Firestore serialization
        final confirmedItemModels = confirmedItems
            .map((item) => ConfirmedMealItemModel.fromEntity(item))
            .toList();

        // Convert total nutrition to model
        final totalNutritionModel = NutritionalEstimateModel.fromEntity(
          totalNutrition,
        );

        log('💾 [REPOSITORY] Updating document in Firestore...');
        // Update document with properly serialized data
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('ai_meal_logs')
            .doc(id)
            .update({
              'items': confirmedItemModels
                  .map((item) => item.toFirestore())
                  .toList(),
              'totalNutrition': totalNutritionModel.toFirestore(),
              'notes': notes,
              'updatedAt': Timestamp.now(),
            });

        log('✅ [REPOSITORY] Successfully updated meal log with ID: $id');

        // Return updated meal log
        final result = await getAIMealLogById(id);
        return result.fold(
          (failure) => throw Exception('Failed to retrieve updated meal log'),
          (mealLog) => mealLog,
        );
      } catch (e, stackTrace) {
        log('❌ [REPOSITORY] Error during Firestore update: $e');
        log('❌ [REPOSITORY] Stack trace: $stackTrace');
        rethrow;
      }
    });
  }

  @override
  Future<Either<Failure, Unit>> deleteAIMealLog(String id) async {
    return safeCall(() async {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('ai_meal_logs')
          .doc(id)
          .delete();

      return unit;
    });
  }

  @override
  Future<Either<Failure, List<FoodItem>>> searchFoodDatabase(
    String query,
  ) async {
    return safeCall(() async {
      // Use the existing USDA Food Database Service
      final foodDatabaseService = getIt<legacy.FoodDatabaseService>();
      final foodItems = await foodDatabaseService.searchFoods(query);

      // Convert from existing FoodItem model to AI meal logging FoodItem model
      return foodItems
          .map(
            (item) => FoodItem(
              id: item.id,
              name: item.name,
              brand: item.brandName ?? '',
              nutritionPer100g: {
                'calories': item.getCalories(),
                'protein': item.getProtein(),
                'carbs': item.getCarbohydrates(),
                'fat': item.getFat(),
                'fiber': item.getNutrientValue(1079), // Total dietary fiber
                'sugar': item.getNutrientValue(2000), // Total sugars
                'sodium': item.getNutrientValue(1093), // Sodium, Na
              },
              servingSizes: ['100g', '1 serving', '1 cup', '1 piece'],
            ),
          )
          .toList();
    });
  }

  @override
  Future<Either<Failure, FoodItem>> getFoodItemById(String foodId) async {
    return safeCall(() async {
      // Use the existing USDA Food Database Service
      final foodDatabaseService = getIt<legacy.FoodDatabaseService>();
      final foodItem = await foodDatabaseService.getFoodDetails(foodId);

      if (foodItem == null) {
        throw Exception('Food item not found');
      }

      // Convert from existing FoodItem model to AI meal logging FoodItem model
      return FoodItem(
        id: foodItem.id,
        name: foodItem.name,
        brand: foodItem.brandName ?? '',
        nutritionPer100g: {
          'calories': foodItem.getCalories(),
          'protein': foodItem.getProtein(),
          'carbs': foodItem.getCarbohydrates(),
          'fat': foodItem.getFat(),
          'fiber': foodItem.getNutrientValue(1079), // Total dietary fiber
          'sugar': foodItem.getNutrientValue(2000), // Total sugars
          'sodium': foodItem.getNutrientValue(1093), // Sodium, Na
        },
        servingSizes: ['100g', '1 serving', '1 cup', '1 piece'],
      );
    });
  }

  /// Calculate total nutrition from confirmed meal items
  NutritionalEstimate _calculateTotalNutrition(List<ConfirmedMealItem> items) {
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalFiber = 0;
    double totalSugar = 0;
    double totalSodium = 0;

    for (final item in items) {
      final nutrition = item.nutrition;
      totalCalories += nutrition.calories;
      totalProtein += nutrition.protein;
      totalCarbs += nutrition.carbs;
      totalFat += nutrition.fat;
      totalFiber += nutrition.fiber ?? 0;
      totalSugar += nutrition.sugar ?? 0;
      totalSodium += nutrition.sodium ?? 0;
    }

    return NutritionalEstimate(
      calories: totalCalories.round(),
      protein: totalProtein,
      carbs: totalCarbs,
      fat: totalFat,
      fiber: totalFiber,
      sugar: totalSugar,
      sodium: totalSodium,
    );
  }
}
