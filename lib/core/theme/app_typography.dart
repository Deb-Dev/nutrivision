import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Available font families for the app
enum AppFontFamily {
  roboto('Roboto', 'Default Material Design font'),
  openSans('Open Sans', 'Clean and modern font'),
  lato('Lato', 'Friendly and approachable font'),
  nunito('Nunito', 'Rounded and warm font'),
  poppins('Poppins', 'Geometric and contemporary font'),
  inter('Inter', 'Highly legible UI font'),
  sourceSerif('Source Serif 4', 'Professional serif font'),
  playfair('Playfair Display', 'Elegant display font'),
  montserrat('Montserrat', 'Urban and modern font'),
  raleway('Raleway', 'Sophisticated sans-serif font');

  const AppFontFamily(this.displayName, this.description);

  final String displayName;
  final String description;
}

/// Typography configuration for the app
class AppTypography {
  /// Current selected font family
  static AppFontFamily _currentFont = AppFontFamily.roboto;

  /// Get the current font family
  static AppFontFamily get currentFont => _currentFont;

  /// Set a new font family
  static void setFont(AppFontFamily font) {
    _currentFont = font;
  }

  /// Generate TextTheme based on the selected font
  static TextTheme getTextTheme({
    AppFontFamily? fontFamily,
    Brightness brightness = Brightness.light,
  }) {
    final selectedFont = fontFamily ?? _currentFont;

    // Get the appropriate TextStyle function from Google Fonts
    TextStyle Function({
      TextStyle? textStyle,
      Color? color,
      double? fontSize,
      FontWeight? fontWeight,
      double? letterSpacing,
      double? wordSpacing,
      TextBaseline? textBaseline,
      double? height,
      Locale? locale,
      Paint? foreground,
      Paint? background,
      List<Shadow>? shadows,
      List<FontFeature>? fontFeatures,
      TextDecoration? decoration,
      Color? decorationColor,
      TextDecorationStyle? decorationStyle,
      double? decorationThickness,
    })
    fontFunction;

    switch (selectedFont) {
      case AppFontFamily.roboto:
        fontFunction = GoogleFonts.roboto;
        break;
      case AppFontFamily.openSans:
        fontFunction = GoogleFonts.openSans;
        break;
      case AppFontFamily.lato:
        fontFunction = GoogleFonts.lato;
        break;
      case AppFontFamily.nunito:
        fontFunction = GoogleFonts.nunito;
        break;
      case AppFontFamily.poppins:
        fontFunction = GoogleFonts.poppins;
        break;
      case AppFontFamily.inter:
        fontFunction = GoogleFonts.inter;
        break;
      case AppFontFamily.sourceSerif:
        fontFunction = GoogleFonts.sourceSerif4;
        break;
      case AppFontFamily.playfair:
        fontFunction = GoogleFonts.playfairDisplay;
        break;
      case AppFontFamily.montserrat:
        fontFunction = GoogleFonts.montserrat;
        break;
      case AppFontFamily.raleway:
        fontFunction = GoogleFonts.raleway;
        break;
    }

    // Base color for text
    final baseColor = brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;

    return TextTheme(
      // Display styles (largest text)
      displayLarge: fontFunction(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        color: baseColor,
      ),
      displayMedium: fontFunction(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: baseColor,
      ),
      displaySmall: fontFunction(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: baseColor,
      ),

      // Headline styles
      headlineLarge: fontFunction(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: baseColor,
      ),
      headlineMedium: fontFunction(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: baseColor,
      ),
      headlineSmall: fontFunction(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: baseColor,
      ),

      // Title styles
      titleLarge: fontFunction(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        color: baseColor,
      ),
      titleMedium: fontFunction(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: baseColor,
      ),
      titleSmall: fontFunction(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: baseColor,
      ),

      // Label styles
      labelLarge: fontFunction(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: baseColor,
      ),
      labelMedium: fontFunction(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: baseColor,
      ),
      labelSmall: fontFunction(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: baseColor,
      ),

      // Body styles
      bodyLarge: fontFunction(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: baseColor,
      ),
      bodyMedium: fontFunction(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: baseColor,
      ),
      bodySmall: fontFunction(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: baseColor,
      ),
    );
  }

  /// Generate complete theme with custom typography
  static ThemeData getTheme({
    AppFontFamily? fontFamily,
    ColorScheme? colorScheme,
    Brightness brightness = Brightness.light,
  }) {
    final textTheme = getTextTheme(
      fontFamily: fontFamily,
      brightness: brightness,
    );

    final defaultColorScheme = brightness == Brightness.dark
        ? ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.dark,
          )
        : ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.light,
          );

    final baseTheme = brightness == Brightness.dark
        ? ThemeData.dark()
        : ThemeData.light();

    return baseTheme.copyWith(
      colorScheme: colorScheme ?? defaultColorScheme,
      textTheme: textTheme,
      useMaterial3: true,

      // Apply text theme to specific components
      appBarTheme: baseTheme.appBarTheme.copyWith(
        titleTextStyle: textTheme.titleLarge,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(textStyle: textTheme.labelLarge),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: textTheme.labelLarge),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(textStyle: textTheme.labelLarge),
      ),

      inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
        labelStyle: textTheme.bodyLarge,
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: (colorScheme ?? defaultColorScheme).onSurface.withOpacity(0.6),
        ),
      ),

      cardTheme: baseTheme.cardTheme.copyWith(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// Widget for font selection and preview
class FontSelector extends StatefulWidget {
  final AppFontFamily currentFont;
  final ValueChanged<AppFontFamily> onFontChanged;

  const FontSelector({
    super.key,
    required this.currentFont,
    required this.onFontChanged,
  });

  @override
  State<FontSelector> createState() => _FontSelectorState();
}

class _FontSelectorState extends State<FontSelector> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Choose App Font',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),

          // Font preview text
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preview Text',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'The quick brown fox jumps over the lazy dog',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'abcdefghijklmnopqrstuvwxyz 1234567890',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),

          // Font options
          ...AppFontFamily.values.map((font) => _buildFontOption(font)),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFontOption(AppFontFamily font) {
    final isSelected = font == widget.currentFont;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: isSelected ? 4 : 1,
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
        child: InkWell(
          onTap: () => widget.onFontChanged(font),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        font.displayName,
                        style: AppTypography.getTextTheme(fontFamily: font)
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer
                                  : null,
                            ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  font.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isSelected
                        ? Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer.withOpacity(0.7)
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sample: NutriVision helps you track your nutrition goals',
                  style: AppTypography.getTextTheme(fontFamily: font).bodyMedium
                      ?.copyWith(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : null,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
