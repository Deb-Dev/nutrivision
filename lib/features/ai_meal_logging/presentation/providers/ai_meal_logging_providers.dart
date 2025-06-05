import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/ai_meal_recognition.dart';
import '../../domain/repositories/ai_meal_logging_repository.dart';
import '../../domain/usecases/ai_meal_logging_usecases.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/result.dart';

part 'ai_meal_logging_providers.g.dart';

/// State for AI meal photo capture and analysis
class AIMealPhotoState {
  final File? selectedImage;
  final bool isAnalyzing;
  final AIMealRecognitionResult? analysisResult;
  final String? errorMessage;
  final bool hasPermissions;
  final bool isCameraInitialized;

  const AIMealPhotoState({
    this.selectedImage,
    this.isAnalyzing = false,
    this.analysisResult,
    this.errorMessage,
    this.hasPermissions = false,
    this.isCameraInitialized = false,
  });

  AIMealPhotoState copyWith({
    File? selectedImage,
    bool? isAnalyzing,
    AIMealRecognitionResult? analysisResult,
    String? errorMessage,
    bool? hasPermissions,
    bool? isCameraInitialized,
  }) {
    return AIMealPhotoState(
      selectedImage: selectedImage ?? this.selectedImage,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      analysisResult: analysisResult ?? this.analysisResult,
      errorMessage: errorMessage ?? this.errorMessage,
      hasPermissions: hasPermissions ?? this.hasPermissions,
      isCameraInitialized: isCameraInitialized ?? this.isCameraInitialized,
    );
  }
}

/// Notifier for AI meal photo capture and analysis
@riverpod
class AIMealPhotoNotifier extends _$AIMealPhotoNotifier {
  late final AnalyzeMealPhotoUseCase _analyzeMealPhotoUseCase;

  @override
  AIMealPhotoState build() {
    _analyzeMealPhotoUseCase = getIt<AnalyzeMealPhotoUseCase>();
    return const AIMealPhotoState();
  }

  /// Set camera permissions status
  void setPermissions(bool hasPermissions) {
    state = state.copyWith(hasPermissions: hasPermissions);
  }

  /// Set camera initialization status
  void setCameraInitialized(bool isInitialized) {
    state = state.copyWith(isCameraInitialized: isInitialized);
  }

  /// Set selected image
  void setSelectedImage(File? image) {
    state = state.copyWith(
      selectedImage: image,
      analysisResult: null,
      errorMessage: null,
    );
  }

  /// Analyze the selected meal photo
  Future<void> analyzeMealPhoto({String? mealType}) async {
    print('📱 [Provider] analyzeMealPhoto called');

    if (state.selectedImage == null) {
      print('❌ [Provider] No image selected');
      state = state.copyWith(errorMessage: 'No image selected');
      return;
    }

    print('✅ [Provider] Image available, starting analysis...');
    print('🔄 [Provider] Setting isAnalyzing = true');

    state = state.copyWith(
      isAnalyzing: true,
      errorMessage: null,
      analysisResult: null,
    );

    print(
      '📤 [Provider] Calling use case with image: ${state.selectedImage!.path}',
    );
    print('📤 [Provider] Meal type: ${mealType ?? 'null'}');

    final result = await _analyzeMealPhotoUseCase(
      imageFile: state.selectedImage!,
      mealType: mealType,
    );

    print('📥 [Provider] Use case returned result');

    result.fold(
      (failure) {
        print('❌ [Provider] Analysis failed with failure: ${failure.message}');
        state = state.copyWith(
          isAnalyzing: false,
          errorMessage: failure.message,
        );
      },
      (analysisResult) {
        print('✅ [Provider] Analysis completed successfully');
        print(
          '📊 [Provider] Found ${analysisResult.recognizedItems.length} items',
        );
        print(
          '⏱️ [Provider] Processing time: ${analysisResult.processingTime}s',
        );
        print('🔍 [Provider] Success: ${analysisResult.isSuccessful}');

        if (!analysisResult.isSuccessful &&
            analysisResult.errorMessage != null) {
          print(
            '⚠️ [Provider] Analysis marked as unsuccessful: ${analysisResult.errorMessage}',
          );
        }

        state = state.copyWith(
          isAnalyzing: false,
          analysisResult: analysisResult,
        );
      },
    );

    print('🏁 [Provider] analyzeMealPhoto completed');
  }

  /// Clear current state
  void clearState() {
    state = const AIMealPhotoState();
  }
}

/// State for AI meal confirmation and editing
class AIMealConfirmationState {
  final List<ConfirmedMealItem> confirmedItems;
  final bool isLogging;
  final bool isSearching;
  final List<FoodItem> searchResults;
  final String? errorMessage;
  final AIMealLog? loggedMeal;
  final NutritionalEstimate? totalNutrition;

  const AIMealConfirmationState({
    this.confirmedItems = const [],
    this.isLogging = false,
    this.isSearching = false,
    this.searchResults = const [],
    this.errorMessage,
    this.loggedMeal,
    this.totalNutrition,
  });

  AIMealConfirmationState copyWith({
    List<ConfirmedMealItem>? confirmedItems,
    bool? isLogging,
    bool? isSearching,
    List<FoodItem>? searchResults,
    String? errorMessage,
    AIMealLog? loggedMeal,
    NutritionalEstimate? totalNutrition,
  }) {
    return AIMealConfirmationState(
      confirmedItems: confirmedItems ?? this.confirmedItems,
      isLogging: isLogging ?? this.isLogging,
      isSearching: isSearching ?? this.isSearching,
      searchResults: searchResults ?? this.searchResults,
      errorMessage: errorMessage ?? this.errorMessage,
      loggedMeal: loggedMeal ?? this.loggedMeal,
      totalNutrition: totalNutrition ?? this.totalNutrition,
    );
  }
}

/// Provider for simple async operations without state management
@riverpod
Future<Result<AIMealRecognitionResult>> analyzeMealPhoto(
  AnalyzeMealPhotoRef ref,
  File imageFile, {
  String? mealType,
}) async {
  final useCase = getIt<AnalyzeMealPhotoUseCase>();
  return await useCase(imageFile: imageFile, mealType: mealType);
}

@riverpod
Future<Result<List<FoodItem>>> searchFoodDatabase(
  SearchFoodDatabaseRef ref,
  String query,
) async {
  final useCase = getIt<SearchFoodDatabaseUseCase>();
  return await useCase(query);
}

@riverpod
Future<Result<AIMealLog>> logAIMeal(
  LogAIMealRef ref, {
  required List<ConfirmedMealItem> confirmedItems,
  required String imageId,
  required AIMealRecognitionResult originalAnalysis,
  required String mealType,
  String? notes,
}) async {
  final useCase = getIt<LogAIMealUseCase>();
  return await useCase(
    confirmedItems: confirmedItems,
    imageId: imageId,
    originalAnalysis: originalAnalysis,
    mealType: mealType,
    notes: notes,
  );
}
