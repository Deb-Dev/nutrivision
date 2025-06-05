import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

// Data models for food recognition
class RecognizedFoodItem {
  final String name;
  final double confidence; // 0.0 to 1.0
  final String estimatedServing;
  final NutritionalEstimate nutritionalEstimate;

  RecognizedFoodItem({
    required this.name,
    required this.confidence,
    required this.estimatedServing,
    required this.nutritionalEstimate,
  });

  factory RecognizedFoodItem.fromJson(Map<String, dynamic> json) {
    return RecognizedFoodItem(
      name: json['name'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      estimatedServing: json['estimated_serving'] as String,
      nutritionalEstimate: NutritionalEstimate.fromJson(json['nutrition']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'confidence': confidence,
      'estimated_serving': estimatedServing,
      'nutrition': nutritionalEstimate.toJson(),
    };
  }
}

class NutritionalEstimate {
  final int calories;
  final double protein; // grams
  final double carbs; // grams
  final double fat; // grams

  NutritionalEstimate({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory NutritionalEstimate.fromJson(Map<String, dynamic> json) {
    return NutritionalEstimate(
      calories: json['calories'] as int,
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }
}

class FoodRecognitionResult {
  final List<RecognizedFoodItem> recognizedItems;
  final bool isSuccessful;
  final String? errorMessage;
  final double processingTime; // seconds

  FoodRecognitionResult({
    required this.recognizedItems,
    required this.isSuccessful,
    this.errorMessage,
    required this.processingTime,
  });
}

// Custom exceptions
class FoodRecognitionError implements Exception {
  final String message;
  FoodRecognitionError(this.message);

  @override
  String toString() => 'FoodRecognitionError: $message';
}

class AIFoodRecognitionService {
  static GenerativeModel? _visionModel;
  static bool _isInitialized = false;

  // Configuration from Firebase Remote Config
  static String? _apiKey;
  static bool _aiRecognitionEnabled = true;
  static int _maxFoodItemsPerImage = 5;
  static double _minConfidenceThreshold = 0.6;

  /// Initialize the AI service with hardcoded configuration
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Use hardcoded configuration for now
      _apiKey = "AIzaSyA0DSdLGeDdcDWUWxs5G9ctCgUxcM3J_1Q";
      _aiRecognitionEnabled = true;
      _maxFoodItemsPerImage = 5;
      _minConfidenceThreshold = 0.6;

      // Debug: Print configuration values
      print('🔑 AI Service Configuration:');
      print('  - API Key: ***${_apiKey!.substring(_apiKey!.length - 4)}');
      print('  - AI Enabled: $_aiRecognitionEnabled');
      print('  - Max Items: $_maxFoodItemsPerImage');
      print('  - Min Confidence: $_minConfidenceThreshold');

      if (_apiKey == null || _apiKey!.isEmpty) {
        throw FoodRecognitionError('Gemini API key not configured.');
      }

      if (!_aiRecognitionEnabled) {
        throw FoodRecognitionError('AI recognition is currently disabled');
      }

      // Initialize Gemini model
      _visionModel = GenerativeModel(
        model: 'gemini-1.5-pro-vision-latest',
        apiKey: _apiKey!,
        generationConfig: GenerationConfig(
          maxOutputTokens: 2048,
          temperature: 0.4,
        ),
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
          SafetySetting(
            HarmCategory.sexuallyExplicit,
            HarmBlockThreshold.medium,
          ),
          SafetySetting(
            HarmCategory.dangerousContent,
            HarmBlockThreshold.medium,
          ),
        ],
      );

      _isInitialized = true;
    } catch (e) {
      throw FoodRecognitionError('Failed to initialize AI service: $e');
    }
  }

  /// Analyze meal photo and return recognized food items
  static Future<FoodRecognitionResult> analyzeMealPhoto(File imageFile) async {
    if (!_isInitialized) {
      await initialize();
    }

    final stopwatch = Stopwatch()..start();

    try {
      // Read and validate image
      final imageBytes = await imageFile.readAsBytes();
      if (imageBytes.isEmpty) {
        throw FoodRecognitionError('Invalid or empty image file');
      }

      // Create the analysis prompt
      final prompt = _createFoodAnalysisPrompt();

      // Create content with image and prompt
      final content = [
        Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
      ];

      // Generate content with retry mechanism
      final response = await _generateContentWithRetry(content);

      if (response.text == null || response.text!.isEmpty) {
        throw FoodRecognitionError('Empty response from AI service');
      }

      // Parse the response
      final result = _parseAIResponse(response.text!);

      stopwatch.stop();

      return FoodRecognitionResult(
        recognizedItems: result,
        isSuccessful: true,
        processingTime: stopwatch.elapsedMilliseconds / 1000.0,
      );
    } catch (e) {
      stopwatch.stop();

      return FoodRecognitionResult(
        recognizedItems: [],
        isSuccessful: false,
        errorMessage: e.toString(),
        processingTime: stopwatch.elapsedMilliseconds / 1000.0,
      );
    }
  }

  /// Create a comprehensive prompt for food analysis
  static String _createFoodAnalysisPrompt() {
    return '''
Analyze this food image and identify all visible food items. Return ONLY a valid JSON response with this exact structure:

{
  "items": [
    {
      "name": "Food Name",
      "confidence": 0.95,
      "estimated_serving": "1 cup",
      "nutrition": {
        "calories": 150,
        "protein": 5.2,
        "carbs": 25.0,
        "fat": 3.1
      }
    }
  ]
}

Guidelines:
1. Include only items with confidence > $_minConfidenceThreshold
2. Maximum $_maxFoodItemsPerImage food items
3. Use standard serving sizes (cup, tablespoon, piece, slice, etc.)
4. Provide realistic nutritional estimates per serving
5. Use common food names (e.g., "Grilled Chicken Breast" not "Poultry")
6. Return valid JSON only, no explanations or markdown

Focus on clearly visible, identifiable food items only.
''';
  }

  /// Generate content with retry mechanism for reliability
  static Future<GenerateContentResponse> _generateContentWithRetry(
    Iterable<Content> content, {
    int maxRetries = 3,
  }) async {
    int attempt = 0;

    while (true) {
      try {
        return await _visionModel!.generateContent(content);
      } catch (e) {
        attempt++;

        if (attempt >= maxRetries) {
          if (e is GenerativeAIException) {
            throw FoodRecognitionError('AI API Error: ${e.message}');
          } else if (e is SocketException) {
            throw FoodRecognitionError(
              'Network connection failed. Please check your internet connection.',
            );
          } else {
            throw FoodRecognitionError('AI analysis failed: $e');
          }
        }

        // Exponential backoff delay
        final delay = Duration(milliseconds: 1000 * (1 << (attempt - 1)));
        await Future.delayed(delay);
      }
    }
  }

  /// Parse AI response and extract food items
  static List<RecognizedFoodItem> _parseAIResponse(String responseText) {
    try {
      // Clean the response text (remove markdown if present)
      String jsonText = responseText.trim();
      if (jsonText.startsWith('```json')) {
        jsonText = jsonText.substring(7);
      }
      if (jsonText.endsWith('```')) {
        jsonText = jsonText.substring(0, jsonText.length - 3);
      }
      jsonText = jsonText.trim();

      // Parse JSON
      final Map<String, dynamic> parsed = jsonDecode(jsonText);

      if (!parsed.containsKey('items') || parsed['items'] is! List) {
        throw FoodRecognitionError(
          'Invalid response format: missing items array',
        );
      }

      final List<dynamic> itemsJson = parsed['items'];
      final List<RecognizedFoodItem> items = [];

      for (final itemJson in itemsJson) {
        try {
          final item = RecognizedFoodItem.fromJson(itemJson);

          // Apply confidence threshold filter
          if (item.confidence >= _minConfidenceThreshold) {
            items.add(item);
          }
        } catch (e) {
          // Skip invalid items but continue processing
          continue;
        }
      }

      if (items.isEmpty) {
        throw FoodRecognitionError(
          'No food items detected with sufficient confidence',
        );
      }

      return items;
    } catch (e) {
      if (e is FoodRecognitionError) {
        rethrow;
      }
      throw FoodRecognitionError('Failed to parse AI response: $e');
    }
  }

  /// Check if the service is properly initialized and enabled
  static bool get isAvailable => _isInitialized && _aiRecognitionEnabled;

  /// Get current configuration values
  static Map<String, dynamic> get configuration => {
    'ai_recognition_enabled': _aiRecognitionEnabled,
    'max_food_items_per_image': _maxFoodItemsPerImage,
    'min_confidence_threshold': _minConfidenceThreshold,
    'is_initialized': _isInitialized,
  };
}
