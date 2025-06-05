import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration management
class Environment {
  /// Load environment variables
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      // .env file not found or error loading it - this is fine, we'll use defaults
      // This allows the app to run without a .env file in development/production
      print('Warning: .env file not found, using default environment values');
    }
  }

  /// Get string value from environment
  static String getString(String key, {String? defaultValue}) {
    return dotenv.env[key] ?? defaultValue ?? '';
  }

  /// Get boolean value from environment
  static bool getBool(String key, {bool defaultValue = false}) {
    final value = dotenv.env[key]?.toLowerCase();
    return value == 'true' || value == '1';
  }

  /// Get integer value from environment
  static int getInt(String key, {int defaultValue = 0}) {
    final value = dotenv.env[key];
    return int.tryParse(value ?? '') ?? defaultValue;
  }

  /// Get double value from environment
  static double getDouble(String key, {double defaultValue = 0.0}) {
    final value = dotenv.env[key];
    return double.tryParse(value ?? '') ?? defaultValue;
  }

  // Specific environment getters
  static String get geminiApiKey =>
      getString('GEMINI_API_KEY', defaultValue: '');
  static String get firebaseProjectId =>
      getString('FIREBASE_PROJECT_ID', defaultValue: '');
  static String get foodDatabaseApiUrl => getString(
    'FOOD_DATABASE_API_URL',
    defaultValue: 'https://api.nal.usda.gov/fdc/v1',
  );

  static bool get aiRecognitionEnabled =>
      getBool('AI_RECOGNITION_ENABLED', defaultValue: true);
  static bool get analyticsEnabled =>
      getBool('ANALYTICS_ENABLED', defaultValue: true);
  static bool get crashlyticsEnabled =>
      getBool('CRASHLYTICS_ENABLED', defaultValue: true);
  static bool get debugLogging => getBool('DEBUG_LOGGING', defaultValue: false);
  static bool get mockServices => getBool('MOCK_SERVICES', defaultValue: false);
  static bool get isDevelopment =>
      getBool('IS_DEVELOPMENT', defaultValue: true);
}
