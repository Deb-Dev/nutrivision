import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_typography.dart';
import 'theme_provider.dart';

/// Provider for managing the app's theme with font integration
final appThemeProvider = Provider<ThemeData>((ref) {
  final currentFont = ref.watch(fontFamilyProvider);

  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
    useMaterial3: true,
    textTheme: AppTypography.getTextTheme(
      fontFamily: currentFont,
      brightness: Brightness.light,
    ),
  );
});

/// Provider for managing the app's dark theme with font integration
final appDarkThemeProvider = Provider<ThemeData>((ref) {
  final currentFont = ref.watch(fontFamilyProvider);

  return ThemeData.dark().copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.green,
      brightness: Brightness.dark,
    ),
    textTheme: AppTypography.getTextTheme(
      fontFamily: currentFont,
      brightness: Brightness.dark,
    ),
  );
});

/// Provider to watch for theme changes and trigger rebuilds
final themeUpdateProvider = StateProvider<int>((ref) => 0);
