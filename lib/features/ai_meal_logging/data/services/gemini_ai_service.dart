import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:crypto/crypto.dart';
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
  
  // Cache for meal suggestions to avoid duplicate API calls
  final Map<String, String> _mealSuggestionCache = {};
  final Map<String, DateTime> _mealSuggestionTimestamps = {};
  final Duration _cacheExpiration = const Duration(minutes: 30);
  
  // Active requests tracking to prevent duplicate calls
  final Map<String, Future<String>> _activeMealSuggestionRequests = {};

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
    dev.log('🤖 [AI SERVICE] analyzeMealPhoto() - Starting AI analysis');
    dev.log('📁 [AI SERVICE] Image file: ${imageFile.path}');

    if (!_isInitialized) {
      dev.log('⏳ [AI SERVICE] Service not initialized, initializing...');
      await initialize();
    }

    // Check if AI recognition is enabled and model is available
    if (!_aiRecognitionEnabled || _visionModel == null) {
      dev.log('❌ [AI SERVICE] AI recognition disabled or model null');
      dev.log('🔧 [AI SERVICE] _aiRecognitionEnabled: $_aiRecognitionEnabled');
      dev.log(
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

    dev.log('✅ [AI SERVICE] AI service ready, starting analysis...');
    final stopwatch = Stopwatch()..start();
    final analyzedAt = DateTime.now();

    try {
      // Read and validate image
      dev.log('📖 [AI SERVICE] Reading image bytes...');
      final imageBytes = await imageFile.readAsBytes();
      dev.log('📊 [AI SERVICE] Image size: ${imageBytes.length} bytes');
      if (imageBytes.isEmpty) {
        throw Exception('Invalid or empty image file');
      }

      // Create the analysis prompt
      dev.log('📝 [AI SERVICE] Creating analysis prompt...');
      final prompt = _createFoodAnalysisPrompt();
      dev.log('📄 [AI SERVICE] Prompt created (length: ${prompt.length} chars)');

      // Create content with image and prompt
      dev.log('🔧 [AI SERVICE] Creating content for API call...');
      final content = [
        Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
      ];

      // Generate content with retry mechanism
      dev.log('🚀 [AI SERVICE] Calling Gemini API...');
      final response = await _generateContentWithRetry(content);
      dev.log('📥 [AI SERVICE] API response received');

      if (response.text == null || response.text!.isEmpty) {
        dev.log('❌ [AI SERVICE] Empty response from API');
        throw Exception('Empty response from AI service');
      }

      dev.log(
        '📝 [AI SERVICE] Response text length: ${response.text!.length} chars',
      );
      dev.log('� [AI SERVICE] Raw Gemini response: ${response.text!}');
      dev.log('�🔍 [AI SERVICE] Parsing AI response...');

      // Parse the response
      final recognizedItems = _parseAIResponse(response.text!);
      dev.log('✅ [AI SERVICE] Parsed ${recognizedItems.length} recognized items');

      stopwatch.stop();
      dev.log(
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
      dev.log('❌ [AI SERVICE] Error during analysis: $e');
      dev.log('⏱️ [AI SERVICE] Failed after ${stopwatch.elapsedMilliseconds}ms');

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

  /// Generate meal suggestions based on preferences and requirements
  Future<String> generateMealSuggestion(String prompt) async {
    dev.log(
      '🤖 [AI SERVICE] generateMealSuggestion() - Starting meal suggestion generation',
    );
    
    // Generate hash for this prompt
    final promptHash = _hashPrompt(prompt);
    
    // Check if this exact request is already in progress
    if (_activeMealSuggestionRequests.containsKey(promptHash)) {
      dev.log('� [AI SERVICE] Request already in progress, returning existing future');
      return _activeMealSuggestionRequests[promptHash]!;
    }
    
    // Check for cached response
    if (_hasCachedResponse(prompt)) {
      dev.log('💡 [AI SERVICE] Using cached response for prompt');
      return _getCachedResponse(prompt);
    }
    
    dev.log('�📝 [AI SERVICE] Prompt hash: $promptHash');
    dev.log('📝 [AI SERVICE] No cache hit, generating new response');

    // Create a future for this request
    final completer = _generateNewMealSuggestion(prompt, promptHash);
    
    // Store in active requests
    _activeMealSuggestionRequests[promptHash] = completer;
    
    try {
      // Wait for completion
      final result = await completer;
      return result;
    } finally {
      // Remove from active requests when done
      _activeMealSuggestionRequests.remove(promptHash);
    }
  }
  
  /// Generate a new meal suggestion
  Future<String> _generateNewMealSuggestion(String prompt, String promptHash) async {
    if (!_isInitialized) {
      dev.log('⏳ [AI SERVICE] Service not initialized, initializing...');
      await initialize();
    }

    // Check if AI recognition is enabled and model is available
    if (!_aiRecognitionEnabled || _visionModel == null) {
      dev.log('❌ [AI SERVICE] AI recognition disabled or model null');
      throw Exception('AI service is not available for meal suggestions');
    }

    try {
      dev.log('🔄 [AI SERVICE] Sending meal suggestion request to Gemini...');

      // Create content for text-only prompt
      final content = [Content.text(prompt)];

      // Generate response
      final response = await _visionModel!.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        dev.log('❌ [AI SERVICE] Empty response from Gemini');
        throw Exception('Empty response from AI service');
      }

      dev.log('✅ [AI SERVICE] Received meal suggestion response');
      dev.log(
        '📄 [AI SERVICE] Response length: ${response.text!.length} characters',
      );

      // Cache the response
      _cacheResponse(prompt, response.text!);

      return response.text!;
    } catch (e) {
      dev.log('❌ [AI SERVICE] Meal suggestion generation failed: $e');
      throw Exception('Failed to generate meal suggestion: $e');
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
    dev.log(
      '🔄 [AI SERVICE] _generateContentWithRetry() - Starting API call with retry logic',
    );

    if (_visionModel == null) {
      dev.log('❌ [AI SERVICE] Vision model is null!');
      throw Exception(
        'AI vision model not initialized - check API key configuration',
      );
    }

    int attempt = 0;

    while (true) {
      try {
        attempt++;
        dev.log('📡 [AI SERVICE] API attempt $attempt/$maxRetries...');
        final response = await _visionModel!.generateContent(content);
        dev.log('✅ [AI SERVICE] API call successful on attempt $attempt');
        return response;
      } catch (e) {
        dev.log('❌ [AI SERVICE] API attempt $attempt failed: $e');

        if (attempt >= maxRetries) {
          dev.log(
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
        dev.log('⏳ [AI SERVICE] Waiting ${delay.inMilliseconds}ms before retry...');
        await Future.delayed(delay);
      }
    }
  }

  /// Transform API response to match our model structure
  Map<String, dynamic> _transformApiResponseToModel(
    Map<String, dynamic> apiJson,
  ) {
    dev.log('🔄 [AI SERVICE] Transforming API response: $apiJson');

    try {
      // Handle different field naming conventions
      final transformedJson = <String, dynamic>{
        'name': apiJson['name'],
        'confidence': apiJson['confidence'] is String 
            ? double.tryParse(apiJson['confidence'] as String) ?? 0.0 
            : (apiJson['confidence'] ?? 0.0),
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

      dev.log('✅ [AI SERVICE] Transformation successful: $transformedJson');
      return transformedJson;
    } catch (e) {
      dev.log('❌ [AI SERVICE] Transformation failed: $e');
      rethrow;
    }
  }

  /// Parse AI response and extract food items
  List<RecognizedFoodItem> _parseAIResponse(String responseText) {
    try {
      dev.log('🔍 [AI SERVICE] Starting response parsing...');
      dev.log('📄 [AI SERVICE] Raw response to parse: $responseText');

      // Clean the response text (remove markdown if present)
      String jsonText = responseText.trim();
      dev.log('🧹 [AI SERVICE] Trimmed response: $jsonText');

      if (jsonText.startsWith('```json')) {
        jsonText = jsonText.substring(7);
        dev.log('🧹 [AI SERVICE] Removed ```json prefix');
      }
      if (jsonText.endsWith('```')) {
        jsonText = jsonText.substring(0, jsonText.length - 3);
        dev.log('🧹 [AI SERVICE] Removed ``` suffix');
      }
      jsonText = jsonText.trim();
      dev.log('🧹 [AI SERVICE] Final cleaned JSON: $jsonText');

      // Parse JSON
      dev.log('🔧 [AI SERVICE] Attempting JSON decode...');
      final Map<String, dynamic> parsed = jsonDecode(jsonText);
      dev.log('✅ [AI SERVICE] JSON decode successful');
      dev.log('📋 [AI SERVICE] Parsed keys: ${parsed.keys.toList()}');

      if (!parsed.containsKey('items') || parsed['items'] is! List) {
        dev.log('❌ [AI SERVICE] Invalid response format: missing items array');
        throw Exception('Invalid response format: missing items array');
      }

      final List<dynamic> itemsJson = parsed['items'];
      dev.log('📋 [AI SERVICE] Found ${itemsJson.length} items in JSON');
      dev.log('📋 [AI SERVICE] Items JSON: $itemsJson');

      final List<RecognizedFoodItem> items = [];
      dev.log('🔍 [AI SERVICE] Processing item  $itemsJson');

      for (int i = 0; i < itemsJson.length; i++) {
        final itemJson = itemsJson[i];
        try {
          dev.log('🔍 [AI SERVICE] Processing item $i: $itemJson');
          dev.log('🔍 [AI SERVICE] Item keys: ${(itemJson as Map).keys.toList()}');

          // Transform the JSON structure to match our model
          final transformedJson = _transformApiResponseToModel(
            Map<String, dynamic>.from(itemJson),
          );
          dev.log('🔄 [AI SERVICE] Transformed item: $transformedJson');

          final item = RecognizedFoodItem.fromJson(transformedJson);
          dev.log(
            '✅ [AI SERVICE] Successfully parsed item: ${item.name} (confidence: ${item.confidence})',
          );

          // Apply confidence threshold filter
          // if (item.confidence >= _minConfidenceThreshold) {
          dev.log(
            '🔍 [AI SERVICE] Found item: ${item.name} (confidence: ${item.confidence})',
          );
          dev.log('🍽️ [AI SERVICE] Estimated serving: ${item.estimatedServing}');
          dev.log(
            '📊 [AI SERVICE] Nutritional estimate: ${item.nutritionalEstimate}',
          );

          items.add(item);
          dev.log(
            '➕ [AI SERVICE] Added item to final list. Current count: ${items.length}',
          );
          // }
        } catch (e, stackTrace) {
          dev.log('❌ [AI SERVICE] Failed to parse item $i: $e');
          dev.log('❌ [AI SERVICE] Stack trace: $stackTrace');
          dev.log('❌ [AI SERVICE] Raw item JSON: $itemJson');
          // Skip invalid items but continue processing
          continue;
        }
      }

      dev.log('📊 [AI SERVICE] Final parsed items count: ${items.length}');

      if (items.isEmpty) {
        dev.log(
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
        dev.log('📈 [AI SERVICE] Extracted confidences: $confidences');
        throw Exception(
          'No food items detected with sufficient confidence. Confidences returned: $confidences and names: $names',
        );
      }

      dev.log('✅ [AI SERVICE] Returning ${items.length} parsed items');
      return items;
    } catch (e) {
      dev.log('❌ [AI SERVICE] Parsing failed: $e');
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

  /// Check if a prompt has a valid cached response
  bool _hasCachedResponse(String prompt) {
    final promptHash = _hashPrompt(prompt);
    if (!_mealSuggestionCache.containsKey(promptHash) ||
        !_mealSuggestionTimestamps.containsKey(promptHash)) {
      return false;
    }
    
    final timestamp = _mealSuggestionTimestamps[promptHash]!;
    final now = DateTime.now();
    return now.difference(timestamp) < _cacheExpiration;
  }
  
  /// Get cached response for a prompt
  String _getCachedResponse(String prompt) {
    final promptHash = _hashPrompt(prompt);
    return _mealSuggestionCache[promptHash]!;
  }
  
  /// Cache a response for a prompt
  void _cacheResponse(String prompt, String response) {
    final promptHash = _hashPrompt(prompt);
    _mealSuggestionCache[promptHash] = response;
    _mealSuggestionTimestamps[promptHash] = DateTime.now();
  }
  
  /// Create a hash of the prompt for caching
  String _hashPrompt(String prompt) {
    final bytes = utf8.encode(prompt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
