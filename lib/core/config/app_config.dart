import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_config.g.dart';

/// Application configuration
class AppConfig {
  final String appName;
  final String version;
  final String buildNumber;
  final AppEnvironment environment;
  final bool debugMode;
  final Level logLevel;
  final Map<String, dynamic> featureFlags;

  const AppConfig({
    required this.appName,
    required this.version,
    required this.buildNumber,
    required this.environment,
    required this.debugMode,
    required this.logLevel,
    required this.featureFlags,
  });
}

/// Application environment
enum AppEnvironment { development, staging, production }

/// Application configuration provider
@riverpod
AppConfig appConfig(AppConfigRef ref) {
  return AppConfig(
    appName: 'NutriVision',
    version: '1.0.0',
    buildNumber: '1',
    environment: kDebugMode
        ? AppEnvironment.development
        : AppEnvironment.production,
    debugMode: kDebugMode,
    logLevel: kDebugMode ? Level.debug : Level.warning,
    featureFlags: {
      'ai_recognition': true,
      'meal_suggestions': true,
      'social_sharing': false,
      'premium_features': false,
    },
  );
}

/// Platform information provider
@riverpod
PlatformInfo platformInfo(PlatformInfoRef ref) {
  return PlatformInfo(
    isAndroid: Platform.isAndroid,
    isIOS: Platform.isIOS,
    isWeb: kIsWeb,
    isDesktop: Platform.isWindows || Platform.isMacOS || Platform.isLinux,
  );
}

/// Platform information
class PlatformInfo {
  final bool isAndroid;
  final bool isIOS;
  final bool isWeb;
  final bool isDesktop;

  const PlatformInfo({
    required this.isAndroid,
    required this.isIOS,
    required this.isWeb,
    required this.isDesktop,
  });

  bool get isMobile => isAndroid || isIOS;
}
