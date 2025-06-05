import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'firebase_options.dart';
import 'core/di/injection.dart';
import 'core/utils/environment.dart';
import 'core/providers/app_theme_provider.dart';
import 'features/auth/presentation/widgets/auth_wrapper_new.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment variables
  await Environment.initialize();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize dependency injection
  await configureDependencies();

  // Initialize Remote Config
  await _initializeRemoteConfig();

  runApp(const ProviderScope(child: NutriVisionApp()));
}

/// Initialize Firebase Remote Config
Future<void> _initializeRemoteConfig() async {
  try {
    final remoteConfig = FirebaseRemoteConfig.instance;

    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );

    // Set default values
    await remoteConfig.setDefaults(const {
      "dietary_preferences": "Vegan,Vegetarian,Pescetarian,Paleo,Keto,None",
      "allergies":
          "Gluten,Dairy,Peanuts,Tree Nuts,Soy,Shellfish,Eggs,Fish,None",
      "activity_levels":
          "Sedentary (little or no exercise),Lightly Active (light exercise/sports 1-3 days/week),Moderately Active (moderate exercise/sports 3-5 days/week),Very Active (hard exercise/sports 6-7 days a week),Extra Active (very hard exercise/sports & a physical job)",
      "dietary_goals": "Weight Loss,Maintain Weight,Muscle Gain",
      "terms_of_service_url": "https://example.com/terms",
      "privacy_policy_url": "https://example.com/privacy",
      "ai_recognition_enabled": "true",
      "max_food_items_per_image": "5",
      "min_confidence_threshold": "0.6",
    });

    // Fetch and activate remote config
    await remoteConfig.fetchAndActivate();
  } catch (e) {
    // Handle remote config initialization error
    debugPrint('Error initializing remote config: $e');
  }
}

/// Main app widget
class NutriVisionApp extends ConsumerWidget {
  const NutriVisionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the theme providers
    final lightTheme = ref.watch(appThemeProvider);
    final darkTheme = ref.watch(appDarkThemeProvider);

    return MaterialApp(
      title: 'NutriVision',
      theme: lightTheme,
      darkTheme: darkTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('es', ''),
        Locale('fr', ''),
      ],
      home: const AuthWrapper(), // Using the updated auth wrapper
      // Error handling
      builder: (context, child) {
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          return _ErrorWidget(errorDetails: errorDetails);
        };
        return child!;
      },
    );
  }
}

/// Custom error widget for better error handling
class _ErrorWidget extends StatelessWidget {
  final FlutterErrorDetails errorDetails;

  const _ErrorWidget({required this.errorDetails});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: Colors.red.shade700),
              ),
              const SizedBox(height: 8),
              Text(
                Environment.debugLogging
                    ? errorDetails.toString()
                    : 'Please restart the app',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
