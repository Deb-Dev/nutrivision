import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'lib/services/ai_food_recognition_service.dart';
import 'lib/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print('🔥 Firebase initialized');

  // Test Firebase Remote Config
  try {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );

    await remoteConfig.setDefaults({
      'gemini_api_key': '',
      'ai_recognition_enabled': true,
      'max_food_items_per_image': 5,
      'min_confidence_threshold': 0.6,
    });

    await remoteConfig.fetchAndActivate();

    final apiKey = remoteConfig.getString('gemini_api_key');
    print(
      '🔑 Gemini API Key configured: ${apiKey.isNotEmpty ? "✅ YES (${apiKey.substring(0, 10)}...)" : "❌ NO"}',
    );
    print(
      '🤖 AI Recognition enabled: ${remoteConfig.getBool('ai_recognition_enabled') ? "✅" : "❌"}',
    );
    print(
      '📊 Max food items: ${remoteConfig.getInt('max_food_items_per_image')}',
    );
    print(
      '🎯 Min confidence: ${remoteConfig.getDouble('min_confidence_threshold')}',
    );

    // Test AI service initialization
    print('\n🧠 Testing AI Food Recognition Service...');
    await AIFoodRecognitionService.initialize();
    print('✅ AI Service initialized successfully!');
  } catch (e) {
    print('❌ Error: $e');
  }
}
