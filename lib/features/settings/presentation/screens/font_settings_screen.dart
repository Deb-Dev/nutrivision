import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers/theme_provider.dart';

/// Screen for selecting and previewing different fonts
class FontSettingsScreen extends ConsumerWidget {
  const FontSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFont = ref.watch(fontFamilyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Font Settings'),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              ref.read(fontFamilyProvider.notifier).resetToDefault();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Font reset to default'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
      body: FontSelector(
        currentFont: currentFont,
        onFontChanged: (font) async {
          await ref.read(fontFamilyProvider.notifier).changeFont(font);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Font changed to ${font.displayName}'),
                duration: const Duration(seconds: 2),
                action: SnackBarAction(
                  label: 'Restart App',
                  onPressed: () {
                    // Show dialog explaining that restart is needed for full effect
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Restart Required'),
                        content: const Text(
                          'To see the font changes throughout the entire app, please restart the application.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

/// Preview widget showing different text styles with the selected font
class FontPreviewCard extends ConsumerWidget {
  final AppFontFamily font;
  final bool isSelected;
  final VoidCallback? onTap;

  const FontPreviewCard({
    super.key,
    required this.font,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = AppTypography.getTextTheme(
      fontFamily: font,
      brightness: Theme.of(context).brightness,
    );

    return Card(
      elevation: isSelected ? 8 : 2,
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with font name and selection indicator
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          font.displayName,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          font.description,
                          style: textTheme.bodyMedium?.copyWith(
                            color: isSelected
                                ? Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer
                                      .withOpacity(0.7)
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 20,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Typography samples
              _buildTypographySample(
                'Display Text',
                textTheme.headlineMedium,
                isSelected,
                context,
              ),

              const SizedBox(height: 8),

              _buildTypographySample(
                'Nutrition Goals & Meal Tracking',
                textTheme.titleMedium,
                isSelected,
                context,
              ),

              const SizedBox(height: 8),

              _buildTypographySample(
                'Track your daily nutrition intake and reach your health goals with personalized meal recommendations.',
                textTheme.bodyMedium,
                isSelected,
                context,
              ),

              const SizedBox(height: 8),

              _buildTypographySample(
                'PROTEIN • CARBS • FATS',
                textTheme.labelMedium,
                isSelected,
                context,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypographySample(
    String text,
    TextStyle? style,
    bool isSelected,
    BuildContext context,
  ) {
    return Text(
      text,
      style: style?.copyWith(
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : null,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
