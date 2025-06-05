import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers/theme_provider.dart';

/// Demo screen to showcase font switching and typography
class FontDemoScreen extends ConsumerWidget {
  const FontDemoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFont = ref.watch(fontFamilyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Font Demo & Experimentation'),
        actions: [
          PopupMenuButton<AppFontFamily>(
            icon: const Icon(Icons.font_download),
            onSelected: (font) async {
              await ref.read(fontFamilyProvider.notifier).changeFont(font);
              // Show a snackbar confirming the change
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Font changed to ${font.displayName}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            itemBuilder: (context) => AppFontFamily.values.map((font) {
              return PopupMenuItem<AppFontFamily>(
                value: font,
                child: Row(
                  children: [
                    if (font == currentFont)
                      const Icon(Icons.check, size: 20, color: Colors.green),
                    if (font != currentFont) const SizedBox(width: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            font.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            font.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current font info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Font',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentFont.displayName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    currentFont.description,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Typography showcase
            Text(
              'Typography Showcase',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            _buildTypographySection(context, 'Display Styles', [
              ('Display Large', Theme.of(context).textTheme.displayLarge),
              ('Display Medium', Theme.of(context).textTheme.displayMedium),
              ('Display Small', Theme.of(context).textTheme.displaySmall),
            ]),

            _buildTypographySection(context, 'Headlines', [
              ('Headline Large', Theme.of(context).textTheme.headlineLarge),
              ('Headline Medium', Theme.of(context).textTheme.headlineMedium),
              ('Headline Small', Theme.of(context).textTheme.headlineSmall),
            ]),

            _buildTypographySection(context, 'Titles', [
              ('Title Large', Theme.of(context).textTheme.titleLarge),
              ('Title Medium', Theme.of(context).textTheme.titleMedium),
              ('Title Small', Theme.of(context).textTheme.titleSmall),
            ]),

            _buildTypographySection(context, 'Body Text', [
              ('Body Large', Theme.of(context).textTheme.bodyLarge),
              ('Body Medium', Theme.of(context).textTheme.bodyMedium),
              ('Body Small', Theme.of(context).textTheme.bodySmall),
            ]),

            _buildTypographySection(context, 'Labels', [
              ('Label Large', Theme.of(context).textTheme.labelLarge),
              ('Label Medium', Theme.of(context).textTheme.labelMedium),
              ('Label Small', Theme.of(context).textTheme.labelSmall),
            ]),

            const SizedBox(height: 24),

            // Sample content
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sample Content',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Welcome to NutriVision',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track your nutrition with AI-powered meal logging. This is how your content will look with the selected font family.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Key Features:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...[
                    'AI meal recognition',
                    'Nutritional tracking',
                    'Goal setting',
                    'Progress reports',
                  ].map(
                    (feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            feature,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.check),
        label: const Text('Done'),
      ),
    );
  }

  Widget _buildTypographySection(
    BuildContext context,
    String title,
    List<(String, TextStyle?)> styles,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        ...styles.map(
          (styleInfo) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    styleInfo.$1,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: Text('Sample Text', style: styleInfo.$2)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
