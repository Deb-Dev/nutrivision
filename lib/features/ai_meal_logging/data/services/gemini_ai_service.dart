import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/ai_meal_recognition.dart';
import '../../../../core/utils/environment.dart' as env;

/// Service for AI-powered food recognition using Google Gemini
@injectable
class GeminiAIService {
  GenerativeModel? _visionModel;
  bool _isInitialized = false;

  // Configuration
  late final String _apiKey;
  late final bool _aiRecognitionEnabled;
  late final int _maxFoodItemsPerImage;
  late final double _minConfidenceThreshold;

  /// Initialize the AI service with environment configuration
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Load configuration from environment
    _apiKey = env.Environment.geminiApiKey;
    _aiRecognitionEnabled = env.Environment.isDevelopment
        ? true
        : env.Environment.aiRecognitionEnabled;
    _maxFoodItemsPerImage = 5;
    _minConfidenceThreshold = 0.6;

    if (_apiKey.isEmpty) {
      print(
        'Warning: Gemini API key not configured - AI meal recognition will be disabled',
      );
      _aiRecognitionEnabled = false;
      _isInitialized = true;
      return;
    }

    if (!_aiRecognitionEnabled) {
      print('AI recognition is disabled via configuration');
      _isInitialized = true;
      return;
    }

    try {
      // Initialize Gemini model
      _visionModel = GenerativeModel(
        model: 'gemini-1.5-pro',
        apiKey: _apiKey,
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
      print('✅ Gemini AI Service initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize Gemini AI Service: $e');
      _aiRecognitionEnabled = false;
      _visionModel = null;
      _isInitialized = true;
    }
  }

  /// Analyze meal photo and return recognized food items
  Future<AIMealRecognitionResult> analyzeMealPhoto(File imageFile) async {
    log('🤖 [AI SERVICE] analyzeMealPhoto() - Starting AI analysis');
    log('📁 [AI SERVICE] Image file: ${imageFile.path}');

    if (!_isInitialized) {
      log('⏳ [AI SERVICE] Service not initialized, initializing...');
      await initialize();
    }

    // Check if AI recognition is enabled and model is available
    if (!_aiRecognitionEnabled || _visionModel == null) {
      log('❌ [AI SERVICE] AI recognition disabled or model null');
      log('🔧 [AI SERVICE] _aiRecognitionEnabled: $_aiRecognitionEnabled');
      log(
        '🔧 [AI SERVICE] _visionModel: ${_visionModel != null ? 'NOT NULL' : 'NULL'}',
      );
      return AIMealRecognitionResult(
        recognizedItems: [],
        isSuccessful: false,
        errorMessage:
            'AI meal recognition is disabled - API key not configured',
        processingTime: 0.0,
        analyzedAt: DateTime.now(),
        imageId: _generateImageId(imageFile),
      );
    }

    log('✅ [AI SERVICE] AI service ready, starting analysis...');
    final stopwatch = Stopwatch()..start();
    final analyzedAt = DateTime.now();

    try {
      // Read and validate image
      log('📖 [AI SERVICE] Reading image bytes...');
      final imageBytes = await imageFile.readAsBytes();
      log('📊 [AI SERVICE] Image size: ${imageBytes.length} bytes');
      if (imageBytes.isEmpty) {
        throw Exception('Invalid or empty image file');
      }

      // Create the analysis prompt
      log('📝 [AI SERVICE] Creating analysis prompt...');
      final prompt = _createFoodAnalysisPrompt();
      log('📄 [AI SERVICE] Prompt created (length: ${prompt.length} chars)');

      // Create content with image and prompt
      log('🔧 [AI SERVICE] Creating content for API call...');
      final content = [
        Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
      ];

      // Generate content with retry mechanism
      log('🚀 [AI SERVICE] Calling Gemini API...');
      final response = await _generateContentWithRetry(content);
      log('📥 [AI SERVICE] API response received');

      if (response.text == null || response.text!.isEmpty) {
        log('❌ [AI SERVICE] Empty response from API');
        throw Exception('Empty response from AI service');
      }

      log(
        '📝 [AI SERVICE] Response text length: ${response.text!.length} chars',
      );
      log('� [AI SERVICE] Raw Gemini response: ${response.text!}');
      log('�🔍 [AI SERVICE] Parsing AI response...');

      // Parse the response
      final recognizedItems = _parseAIResponse(response.text!);
      log('✅ [AI SERVICE] Parsed ${recognizedItems.length} recognized items');

      stopwatch.stop();
      log(
        '⏱️ [AI SERVICE] Total processing time: ${stopwatch.elapsedMilliseconds}ms',
      );

      return AIMealRecognitionResult(
        recognizedItems: recognizedItems,
        isSuccessful: true,
        processingTime: stopwatch.elapsedMilliseconds / 1000.0,
        analyzedAt: analyzedAt,
        imageId: _generateImageId(imageFile),
      );
    } catch (e) {
      stopwatch.stop();
      log('❌ [AI SERVICE] Error during analysis: $e');
      log('⏱️ [AI SERVICE] Failed after ${stopwatch.elapsedMilliseconds}ms');

      return AIMealRecognitionResult(
        recognizedItems: [],
        isSuccessful: false,
        errorMessage: e.toString(),
        processingTime: stopwatch.elapsedMilliseconds / 1000.0,
        analyzedAt: analyzedAt,
        imageId: _generateImageId(imageFile),
      );
    }
  }

  /// Create a comprehensive prompt for food analysis
  String _createFoodAnalysisPrompt() {
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
        "fat": 3.1,
        "fiber": 2.0,
        "sugar": 8.0,
        "sodium": 200.0
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
  Future<GenerateContentResponse> _generateContentWithRetry(
    Iterable<Content> content, {
    int maxRetries = 3,
  }) async {
    log(
      '🔄 [AI SERVICE] _generateContentWithRetry() - Starting API call with retry logic',
    );

    if (_visionModel == null) {
      log('❌ [AI SERVICE] Vision model is null!');
      throw Exception(
        'AI vision model not initialized - check API key configuration',
      );
    }

    int attempt = 0;

    while (true) {
      try {
        attempt++;
        log('📡 [AI SERVICE] API attempt $attempt/$maxRetries...');
        final response = await _visionModel!.generateContent(content);
        log('✅ [AI SERVICE] API call successful on attempt $attempt');
        return response;
      } catch (e) {
        log('❌ [AI SERVICE] API attempt $attempt failed: $e');

        if (attempt >= maxRetries) {
          log(
            '💥 [AI SERVICE] All $maxRetries attempts failed, throwing exception',
          );
          if (e is GenerativeAIException) {
            throw Exception('AI API Error: ${e.message}');
          } else if (e is SocketException) {
            throw Exception(
              'Network connection failed. Please check your internet connection.',
            );
          } else {
            throw Exception('AI analysis failed: $e');
          }
        }

        // Exponential backoff delay
        final delay = Duration(milliseconds: 1000 * (1 << (attempt - 1)));
        log('⏳ [AI SERVICE] Waiting ${delay.inMilliseconds}ms before retry...');
        await Future.delayed(delay);
      }
    }
  }

  /// Transform API response to match our model structure
  Map<String, dynamic> _transformApiResponseToModel(
    Map<String, dynamic> apiJson,
  ) {
    log('🔄 [AI SERVICE] Transforming API response: $apiJson');

    try {
      // Handle different field naming conventions
      final transformedJson = <String, dynamic>{
        'name': apiJson['name'],
        'confidence': apiJson['confidence'],
        'estimatedServing':
            apiJson['estimated_serving'] ?? apiJson['estimatedServing'],
      };

      // Handle nutrition field transformation
      final nutrition = apiJson['nutrition'] ?? apiJson['nutritionalEstimate'];
      if (nutrition != null) {
        transformedJson['nutritionalEstimate'] = nutrition;
      } else {
        // Create a default nutrition estimate if missing
        transformedJson['nutritionalEstimate'] = {
          'calories': 0,
          'protein': 0.0,
          'carbs': 0.0,
          'fat': 0.0,
          'fiber': 0.0,
          'sugar': 0.0,
          'sodium': 0.0,
        };
      }

      // Optional fields
      if (apiJson.containsKey('foodId')) {
        transformedJson['foodId'] = apiJson['foodId'];
      }
      if (apiJson.containsKey('boundingBox')) {
        transformedJson['boundingBox'] = apiJson['boundingBox'];
      }

      log('✅ [AI SERVICE] Transformation successful: $transformedJson');
      return transformedJson;
    } catch (e) {
      log('❌ [AI SERVICE] Transformation failed: $e');
      rethrow;
    }
  }

  /// Parse AI response and extract food items
  List<RecognizedFoodItem> _parseAIResponse(String responseText) {
    try {
      log('🔍 [AI SERVICE] Starting response parsing...');
      log('📄 [AI SERVICE] Raw response to parse: $responseText');

      // Clean the response text (remove markdown if present)
      String jsonText = responseText.trim();
      log('🧹 [AI SERVICE] Trimmed response: $jsonText');

      if (jsonText.startsWith('```json')) {
        jsonText = jsonText.substring(7);
        log('🧹 [AI SERVICE] Removed ```json prefix');
      }
      if (jsonText.endsWith('```')) {
        jsonText = jsonText.substring(0, jsonText.length - 3);
        log('🧹 [AI SERVICE] Removed ``` suffix');
      }
      jsonText = jsonText.trim();
      log('🧹 [AI SERVICE] Final cleaned JSON: $jsonText');

      // Parse JSON
      log('🔧 [AI SERVICE] Attempting JSON decode...');
      final Map<String, dynamic> parsed = jsonDecode(jsonText);
      log('✅ [AI SERVICE] JSON decode successful');
      log('📋 [AI SERVICE] Parsed keys: ${parsed.keys.toList()}');

      if (!parsed.containsKey('items') || parsed['items'] is! List) {
        log('❌ [AI SERVICE] Invalid response format: missing items array');
        throw Exception('Invalid response format: missing items array');
      }

      final List<dynamic> itemsJson = parsed['items'];
      log('📋 [AI SERVICE] Found ${itemsJson.length} items in JSON');
      log('📋 [AI SERVICE] Items JSON: $itemsJson');

      final List<RecognizedFoodItem> items = [];
      log('🔍 [AI SERVICE] Processing item  $itemsJson');

      for (int i = 0; i < itemsJson.length; i++) {
        final itemJson = itemsJson[i];
        try {
          log('🔍 [AI SERVICE] Processing item $i: $itemJson');
          log('🔍 [AI SERVICE] Item keys: ${(itemJson as Map).keys.toList()}');

          // Transform the JSON structure to match our model
          final transformedJson = _transformApiResponseToModel(
            Map<String, dynamic>.from(itemJson),
          );
          log('🔄 [AI SERVICE] Transformed item: $transformedJson');

          final item = RecognizedFoodItem.fromJson(transformedJson);
          log(
            '✅ [AI SERVICE] Successfully parsed item: ${item.name} (confidence: ${item.confidence})',
          );

          // Apply confidence threshold filter
          // if (item.confidence >= _minConfidenceThreshold) {
          log(
            '🔍 [AI SERVICE] Found item: ${item.name} (confidence: ${item.confidence})',
          );
          log('🍽️ [AI SERVICE] Estimated serving: ${item.estimatedServing}');
          log(
            '📊 [AI SERVICE] Nutritional estimate: ${item.nutritionalEstimate}',
          );

          items.add(item);
          log(
            '➕ [AI SERVICE] Added item to final list. Current count: ${items.length}',
          );
          // }
        } catch (e, stackTrace) {
          log('❌ [AI SERVICE] Failed to parse item $i: $e');
          log('❌ [AI SERVICE] Stack trace: $stackTrace');
          log('❌ [AI SERVICE] Raw item JSON: $itemJson');
          // Skip invalid items but continue processing
          continue;
        }
      }

      log('📊 [AI SERVICE] Final parsed items count: ${items.length}');

      if (items.isEmpty) {
        log(
          '⚠️ [AI SERVICE] No items in final list, extracting confidences...',
        );
        final confidences = itemsJson
            .where(
              (itemJson) =>
                  itemJson is Map && itemJson.containsKey('confidence'),
            )
            .map((itemJson) => itemJson['confidence'])
            .toList();

        final names = itemsJson
            .where(
              (itemJson) => itemJson is Map && itemJson.containsKey('name'),
            )
            .map((itemJson) => itemJson['name'])
            .toList();
        log('📈 [AI SERVICE] Extracted confidences: $confidences');
        throw Exception(
          'No food items detected with sufficient confidence. Confidences returned: $confidences and names: $names',
        );
      }

      log('✅ [AI SERVICE] Returning ${items.length} parsed items');
      return items;
    } catch (e) {
      log('❌ [AI SERVICE] Parsing failed: $e');
      throw Exception('Failed to parse AI response: $e');
    }
  }

  /// Generate a unique image ID
  String _generateImageId(File imageFile) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = imageFile.path.split('/').last;
    return 'img_${timestamp}_${fileName.hashCode}';
  }

  /// Check if the service is properly initialized and enabled
  bool get isAvailable => _isInitialized && _aiRecognitionEnabled;

  /// Get current configuration values
  Map<String, dynamic> get configuration => {
    'ai_recognition_enabled': _aiRecognitionEnabled,
    'max_food_items_per_image': _maxFoodItemsPerImage,
    'min_confidence_threshold': _minConfidenceThreshold,
    'is_initialized': _isInitialized,
  };
}
