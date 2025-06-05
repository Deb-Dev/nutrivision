import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/favorite_meals_provider.dart';
import '../providers/meal_history_provider.dart';
import '../../domain/entities/nutrition_goals.dart';
import '../../../../core/providers/auth_providers.dart';
import '../widgets/add_favorite_meal_sheet.dart';
import '../screens/meal_history_screen.dart';

class FavoriteMealsScreen extends ConsumerStatefulWidget {
  const FavoriteMealsScreen({super.key});

  @override
  ConsumerState<FavoriteMealsScreen> createState() =>
      _FavoriteMealsScreenState();
}

class _FavoriteMealsScreenState extends ConsumerState<FavoriteMealsScreen> {
  @override
  void initState() {
    super.initState();
    // Load favorite meals when screen initializes
    Future.microtask(() {
      final userId = ref.read(currentUserIdProvider);
      ref.read(favoriteMealsProvider.notifier).loadFavoriteMeals(userId);
    });
  }

  void _showAddFavoriteDialog() {
    // Open form to create a new favorite meal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddFavoriteMealSheet(
        onMealAdded: () {
          final userId = ref.read(currentUserIdProvider);
          ref.read(favoriteMealsProvider.notifier).loadFavoriteMeals(userId);
        },
      ),
    );
  }

  void _logFavoriteMeal(String mealId) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Logging meal...'),
          ],
        ),
      ),
    );
    
    final userId = ref.read(currentUserIdProvider);
    final result = await ref
        .read(favoriteMealsProvider.notifier)
        .logFavoriteMeal(userId, mealId);

    // Dismiss loading dialog
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (mounted) {
      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: Colors.red,
            ),
          );
        },
        (loggedMealId) {
          // Always refresh meal history data
          ref.read(mealHistoryProvider.notifier).loadMealHistory(userId);
          
          // Show success message with action to view
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Meal logged successfully'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'VIEW IN HISTORY',
                textColor: Colors.white,
                onPressed: () {
                  // Navigate to meal history screen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const MealHistoryScreen(),
                    ),
                  );
                },
              ),
            ),
          );
          
          // Update the favorite meal's usage statistics in the UI
          ref.read(favoriteMealsProvider.notifier).loadFavoriteMeals(userId);
        },
      );
    }
  }

  void _deleteFavoriteMeal(String mealId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Favorite Meal'),
        content: const Text(
          'Are you sure you want to delete this favorite meal? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final userId = ref.read(currentUserIdProvider);
              ref
                  .read(favoriteMealsProvider.notifier)
                  .deleteFavoriteMeal(userId, mealId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favoritesState = ref.watch(favoriteMealsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorite Meals')),
      body: _buildBody(favoritesState),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFavoriteDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(FavoriteMealsState state) {
    switch (state.status) {
      case FavoriteMealsStatus.initial:
      case FavoriteMealsStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case FavoriteMealsStatus.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                state.errorMessage ?? 'An error occurred',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final userId = ref.read(currentUserIdProvider);
                  ref
                      .read(favoriteMealsProvider.notifier)
                      .loadFavoriteMeals(userId);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );

      case FavoriteMealsStatus.updating:
        return Stack(
          children: [
            _buildFavoritesList(state),
            Container(
              color: Colors.black.withValues(alpha: 0.1),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ],
        );

      case FavoriteMealsStatus.loaded:
      case FavoriteMealsStatus.updated:
        return _buildFavoritesList(state);
    }
  }

  Widget _buildFavoritesList(FavoriteMealsState state) {
    final favorites = state.meals;

    if (favorites == null || favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No favorite meals yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your frequently eaten meals for quick logging',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddFavoriteDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Favorite Meal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final meal = favorites[index];
        return _buildFavoriteMealCard(meal);
      },
    );
  }

  Widget _buildFavoriteMealCard(FavoriteMeal meal) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final lastUsedText = meal.lastUsed != null
        ? 'Last used: ${dateFormat.format(meal.lastUsed!)}'
        : 'Never used';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getMealTypeColor(meal.mealType),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _capitalizeFirst(meal.mealType),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteFavoriteMeal(meal.id),
                  iconSize: 20,
                  splashRadius: 20,
                  tooltip: 'Delete favorite',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              meal.name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              lastUsedText,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            if (meal.notes != null && meal.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                meal.notes!,
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                  color: Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            _buildNutritionRow(meal.nutrition),
            const SizedBox(height: 12),
            if (meal.foodItems.isNotEmpty) ...[
              Text(
                'Includes: ${_formatFoodItems(meal.foodItems)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _logFavoriteMeal(meal.id),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('LOG THIS MEAL'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionRow(NutritionalSummary nutrition) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildNutritionItem(
          'Calories',
          '${nutrition.calories}',
          'kcal',
          Colors.red,
        ),
        _buildNutritionItem(
          'Protein',
          nutrition.protein.toStringAsFixed(1),
          'g',
          Colors.blue,
        ),
        _buildNutritionItem(
          'Carbs',
          nutrition.carbs.toStringAsFixed(1),
          'g',
          Colors.orange,
        ),
        _buildNutritionItem(
          'Fat',
          nutrition.fat.toStringAsFixed(1),
          'g',
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildNutritionItem(
    String label,
    String value,
    String unit,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          '$label ($unit)',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  String _formatFoodItems(List<FavoriteFoodItem> items) {
    if (items.isEmpty) return '';

    final maxItems = 3;
    final itemNames = items
        .take(maxItems)
        .map((item) => _capitalizeFirst(item.name))
        .toList();

    if (items.length > maxItems) {
      return '${itemNames.join(', ')} and ${items.length - maxItems} more';
    }

    return itemNames.join(', ');
  }

  Color _getMealTypeColor(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Colors.amber;
      case 'lunch':
        return Colors.green;
      case 'dinner':
        return Colors.indigo;
      case 'snack':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
