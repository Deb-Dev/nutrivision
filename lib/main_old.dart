import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Add this
import 'package:nutrivision/l10n/app_localizations.dart'; // Add this. Path might change after generation

import 'firebase_options.dart';
import 'package:nutrivision/auth_wrapper.dart'; // Import AuthWrapper

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Remote Config
  final remoteConfig = FirebaseRemoteConfig.instance;
  await remoteConfig.setConfigSettings(
    RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1), // Adjust as needed
    ),
  );

  // Set default values
  await remoteConfig.setDefaults(const {
    "dietary_preferences": "Vegan,Vegetarian,Pescetarian,Paleo,Keto,None",
    "allergies": "Gluten,Dairy,Peanuts,Tree Nuts,Soy,Shellfish,Eggs,Fish,None",
    "activity_levels":
        "Sedentary (little or no exercise),Lightly Active (light exercise/sports 1-3 days/week),Moderately Active (moderate exercise/sports 3-5 days/week),Very Active (hard exercise/sports 6-7 days a week),Extra Active (very hard exercise/sports & a physical job)",
    "dietary_goals": "Weight Loss,Maintain Weight,Muscle Gain",
    "terms_of_service_url":
        "https://example.com/terms", // Replace with actual URL
    "privacy_policy_url":
        "https://example.com/privacy", // Replace with actual URL
    // AI Configuration defaults
    "gemini_api_key": "AIzaSyA0DSdLGeDdcDWUWxs5G9ctCgUxcM3J_1Q",
    "ai_recognition_enabled": "true",
    "max_food_items_per_image": "5",
    "min_confidence_threshold": "0.6",
  });

  // Fetch and activate remote config
  try {
    await remoteConfig.fetchAndActivate();
  } catch (e) {
    print('Error fetching remote config: $e');
    // Handle error, perhaps proceed with defaults
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:
          'NutriVision', // This will be replaced by AppLocalizations.of(context)!.appTitle later
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate, // Add this
        GlobalMaterialLocalizations.delegate, // Add this
        GlobalWidgetsLocalizations.delegate, // Add this
        GlobalCupertinoLocalizations.delegate, // Add this
      ],
      supportedLocales: const [
        Locale('en', ''), // English, no country code
        Locale('es', ''), // Spanish, no country code
        Locale('fr', ''), // French, no country code
      ],
      home: const AuthWrapper(), // Change home to AuthWrapper
    );
  }
}
