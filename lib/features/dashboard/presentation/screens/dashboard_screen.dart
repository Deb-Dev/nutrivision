import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrivision/signin_screen.dart';
import 'package:nutrivision/enhanced_log_meal_screen.dart';
import 'package:nutrivision/features/advanced_meal_mgmt/presentation/screens/meal_history_screen.dart'
    as NewMealHistoryScreen;
import 'package:nutrivision/features/advanced_meal_mgmt/presentation/providers/meal_history_provider.dart';
import 'package:nutrivision/core/models/meal_models.dart';
import 'package:nutrivision/meal_suggestions_screen.dart';
import 'package:nutrivision/features/ai_meal_logging/presentation/pages/ai_photo_meal_page.dart';
import 'package:nutrivision/features/advanced_meal_mgmt/presentation/screens/advanced_meal_management_screen.dart';
import 'package:nutrivision/features/advanced_meal_mgmt/presentation/screens/nutrition_analytics_screen.dart';
import 'package:nutrivision/features/advanced_meal_mgmt/presentation/screens/nutritional_goals_screen.dart';
import 'package:nutrivision/features/advanced_meal_mgmt/presentation/screens/favorite_meals_screen.dart';
import 'package:nutrivision/l10n/app_localizations.dart';
import '../providers/dashboard_providers.dart';
import 'package:nutrivision/core/providers/firebase_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(firebaseAuthProvider).signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SignInScreen()),
      (Route<dynamic> route) => false,
    );
  }

  Widget _buildNutrientInfoRow(
    String label,
    dynamic consumed,
    dynamic target,
    String unit,
    AppLocalizations l10n,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            '$consumed / ${target ?? 'N/A'} $unit',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final dashboardState = ref.watch(dashboardProvider);
    final dashboardNotifier = ref.read(dashboardProvider.notifier);

    if (dashboardState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (dashboardState.user == null || dashboardState.userData == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(dashboardState.errorMessage ?? l10n.couldNotLoadUserData),
              ElevatedButton(
                onPressed: () => dashboardNotifier.loadDashboardData(),
                child: Text(l10n.retryButton),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboardTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refreshData,
            onPressed: () => dashboardNotifier.refreshData(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.signOut,
            onPressed: () => _signOut(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.welcomeBackMessage(
                dashboardState.userData?['name'] ??
                    dashboardState.user?.email ??
                    l10n.userGeneric,
              ),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new),
                  tooltip: l10n.previousDay,
                  onPressed: () {
                    final newDate =
                        (dashboardState.selectedDisplayDate ?? DateTime.now())
                            .subtract(const Duration(days: 1));
                    dashboardNotifier.changeDate(newDate);
                  },
                ),
                Text(
                  _isToday(dashboardState.selectedDisplayDate ?? DateTime.now())
                      ? l10n.todaysSummary
                      : l10n.summaryForDate(
                          (dashboardState.selectedDisplayDate ?? DateTime.now())
                              .toLocal()
                              .toString()
                              .split(' ')[0],
                        ),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  tooltip: l10n.nextDay,
                  onPressed:
                      _isToday(
                        dashboardState.selectedDisplayDate ?? DateTime.now(),
                      )
                      ? null
                      : () {
                          final newDate =
                              (dashboardState.selectedDisplayDate ??
                                      DateTime.now())
                                  .add(const Duration(days: 1));
                          dashboardNotifier.changeDate(newDate);
                        },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildNutrientInfoRow(
              l10n.calories,
              dashboardState.displayedConsumedCalories,
              dashboardState.userData!['targetCalories'],
              l10n.kcalUnit,
              l10n,
              context,
            ),
            _buildNutrientInfoRow(
              l10n.protein,
              dashboardState.displayedConsumedProtein.toStringAsFixed(1),
              dashboardState.userData!['targetProteinGrams'],
              l10n.gramsUnit,
              l10n,
              context,
            ),
            _buildNutrientInfoRow(
              l10n.carbs,
              dashboardState.displayedConsumedCarbs.toStringAsFixed(1),
              dashboardState.userData!['targetCarbsGrams'],
              l10n.gramsUnit,
              l10n,
              context,
            ),
            _buildNutrientInfoRow(
              l10n.fats,
              dashboardState.displayedConsumedFat.toStringAsFixed(1),
              dashboardState.userData!['targetFatGrams'],
              l10n.gramsUnit,
              l10n,
              context,
            ),
            const SizedBox(height: 32),
            Center(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  icon: const Icon(
                    Icons.camera_alt,
                    size: 28,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Log Meal with AI Camera',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AIPhotoMealPage(),
                      ),
                    );
                    if (result == true) {
                      dashboardNotifier.loadDashboardData();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit_outlined),
                label: Text(l10n.logNewMealButton),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EnhancedLogMealScreen(),
                    ),
                  );
                  if (result == true) {
                    dashboardNotifier.loadDashboardData();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  foregroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  textStyle: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Advanced Meal Management',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 2,
                    child: InkWell(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const NutritionAnalyticsScreen(),
                          ),
                        );
                        if (result == true) {
                          dashboardNotifier.loadDashboardData();
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.analytics,
                              size: 32,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Nutrition Analytics',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    elevation: 2,
                    child: InkWell(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const NutritionalGoalsScreen(),
                          ),
                        );
                        if (result == true) {
                          dashboardNotifier.loadDashboardData();
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.track_changes,
                              size: 32,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Goals & Tracking',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 2,
                    child: InkWell(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FavoriteMealsScreen(),
                          ),
                        );
                        if (result == true) {
                          dashboardNotifier.loadDashboardData();
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.favorite,
                              size: 32,
                              color: Colors.red[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Favorite Meals',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    elevation: 2,
                    child: InkWell(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const AdvancedMealManagementScreen(),
                          ),
                        );
                        if (result == true) {
                          dashboardNotifier.loadDashboardData();
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.manage_history,
                              size: 32,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Meal Management',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.history),
                    label: const Text('View Meal History'),
                    onPressed: () async {
                      final userId = dashboardState.user?.uid;
                      if (userId == null) return;

                      await ref
                          .read(mealHistoryProvider.notifier)
                          .setInitialFilterAndLoad(
                            userId,
                            MealHistoryFilter(
                              startDate:
                                  dashboardState.selectedDisplayDate ??
                                  DateTime.now(),
                              endDate:
                                  dashboardState.selectedDisplayDate ??
                                  DateTime.now(),
                            ),
                          );

                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const NewMealHistoryScreen.MealHistoryScreen(),
                        ),
                      );
                      if (result == true) {
                        dashboardNotifier.loadDashboardData();
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      textStyle: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.lightbulb_outline),
                    label: const Text('Meal Ideas'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MealSuggestionsScreen(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      textStyle: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.navigateToEditProfilePlaceholder),
                    ),
                  );
                },
                child: Text(l10n.editProfilePreferencesButton),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.lightbulb_outline),
                label: const Text('Meal Suggestions'),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MealSuggestionsScreen(),
                    ),
                  );
                  if (result == true) {
                    dashboardNotifier.loadDashboardData();
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
