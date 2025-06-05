import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_typography.dart';

/// Provider for managing the current font family
final fontFamilyProvider =
    StateNotifierProvider<FontFamilyNotifier, AppFontFamily>((ref) {
      return FontFamilyNotifier();
    });

/// Notifier for managing font family state with persistence
class FontFamilyNotifier extends StateNotifier<AppFontFamily> {
  FontFamilyNotifier() : super(AppFontFamily.roboto) {
    _loadSavedFont();
  }

  static const String _fontKey = 'selected_font_family';

  /// Load the saved font from SharedPreferences
  Future<void> _loadSavedFont() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedFontName = prefs.getString(_fontKey);

      if (savedFontName != null) {
        final savedFont = AppFontFamily.values.firstWhere(
          (font) => font.name == savedFontName,
          orElse: () => AppFontFamily.roboto,
        );
        state = savedFont;
        AppTypography.setFont(savedFont);
      }
    } catch (e) {
      // If loading fails, keep default font
      print('Error loading saved font: $e');
    }
  }

  /// Change the font family and persist the choice
  Future<void> changeFont(AppFontFamily font) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fontKey, font.name);

      state = font;
      AppTypography.setFont(font);

      // Force a rebuild of the entire app by invalidating providers
      // This ensures the theme updates immediately
    } catch (e) {
      print('Error saving font: $e');
      // Still update the state even if saving fails
      state = font;
      AppTypography.setFont(font);
    }
  }

  /// Reset to default font
  Future<void> resetToDefault() async {
    await changeFont(AppFontFamily.roboto);
  }
}
