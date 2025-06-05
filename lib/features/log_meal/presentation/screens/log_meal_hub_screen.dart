import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrivision/features/ai_meal_logging/presentation/pages/ai_photo_meal_page.dart';
import 'package:nutrivision/enhanced_log_meal_screen.dart';
import 'package:nutrivision/features/advanced_meal_mgmt/presentation/screens/favorite_meals_screen.dart';
import 'package:nutrivision/l10n/app_localizations.dart';

/// Hub screen for all meal logging methods
/// This is the central point for users to log meals through various methods
class LogMealHubScreen extends ConsumerStatefulWidget {
  const LogMealHubScreen({super.key});

  @override
  ConsumerState<LogMealHubScreen> createState() => _LogMealHubScreenState();
}

class _LogMealHubScreenState extends ConsumerState<LogMealHubScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.logMealTitle ?? 'Log Meal'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.logYourMeal ?? 'Log Your Meal',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),

            // AI Photo Recognition
            _buildLoggingOption(
              context,
              icon: Icons.camera_alt,
              title: l10n.aiPhotoRecognition ?? 'AI Photo Recognition',
              subtitle:
                  l10n.takePhotoForLogging ??
                  'Take a photo of your meal for instant logging',
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AIPhotoMealPage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Manual Food Search
            _buildLoggingOption(
              context,
              icon: Icons.search,
              title: l10n.searchFoods ?? 'Search Foods',
              subtitle:
                  l10n.searchFoodsDescription ??
                  'Search our database of foods and recipes',
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EnhancedLogMealScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Create Custom Meal
            _buildLoggingOption(
              context,
              icon: Icons.edit_note,
              title: l10n.createCustomMeal ?? 'Create Custom Meal',
              subtitle:
                  l10n.createCustomMealDescription ??
                  'Build and save your own meal',
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EnhancedLogMealScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Favorites
            _buildLoggingOption(
              context,
              icon: Icons.favorite,
              title: l10n.favorites ?? 'Favorites',
              subtitle:
                  l10n.favoritesDescription ??
                  'Quickly log your favorite meals',
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FavoriteMealsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoggingOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
