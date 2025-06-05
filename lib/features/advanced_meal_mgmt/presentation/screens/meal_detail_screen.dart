import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/meal_history_provider.dart';
import '../providers/favorite_meals_provider.dart';
import '../../../../core/models/meal_models.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../domain/entities/nutrition_goals.dart' as goals;
import 'meal_edit_screen.dart';
import '../../utils/meal_name_generator.dart';

class MealDetailScreen extends ConsumerWidget {
  final String mealId;

  const MealDetailScreen({super.key, required this.mealId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealDetailAsync = ref.watch(mealDetailProvider(mealId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Details'),
        actions: [
          mealDetailAsync.when(
            data: (result) => result.fold(
              (failure) => const SizedBox.shrink(),
              (meal) => Row(
                children: [
                  // Generate the meal name to check if it's already a favorite
                  Builder(builder: (context) {
                    final mealName = MealNameGenerator.generateFromMealHistoryEntry(meal);
                    final isFavoriteAsync = ref.watch(isMealFavoriteProvider(mealName));
                    
                    return isFavoriteAsync.when(
                      data: (isFavorite) => IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : null,
                        ),
                        tooltip: isFavorite ? 'Already a favorite' : 'Add to favorites',
                        onPressed: isFavorite 
                          ? () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Meal is already a favorite'))
                            )
                          : () => _addToFavorites(context, ref, meal),
                      ),
                      loading: () => IconButton(
                        icon: const Icon(Icons.favorite_border),
                        tooltip: 'Checking favorites...',
                        onPressed: () => _addToFavorites(context, ref, meal),
                      ),
                      error: (_, __) => IconButton(
                        icon: const Icon(Icons.favorite_border),
                        tooltip: 'Add to favorites',
                        onPressed: () => _addToFavorites(context, ref, meal),
                      ),
                    );
                  }),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit meal',
                    onPressed: () => _navigateToEdit(context, ref, meal),
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: mealDetailAsync.when(
        data: (result) => result.fold(
          (failure) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(failure.message, textAlign: TextAlign.center),
              ],
            ),
          ),
          (meal) => _buildMealDetails(context, meal),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToEdit(
    BuildContext context,
    WidgetRef ref,
    MealHistoryEntry meal,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MealEditScreen(meal: meal)),
    ).then((_) {
      // Refresh meal details when returning from edit screen
      ref.invalidate(mealDetailProvider(mealId));
    });
  }

  Widget _buildMealDetails(BuildContext context, MealHistoryEntry meal) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy • h:mm a');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meal header
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        meal.source == MealSource.aiAssisted
                            ? Icons.camera_alt
                            : Icons.edit_note,
                        size: 20,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        meal.source == MealSource.aiAssisted
                            ? 'AI Assisted'
                            : 'Manually Logged',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    MealNameGenerator.generateFromMealHistoryEntry(meal),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dateFormat.format(meal.loggedAt),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  if (meal.editCount > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Edited ${meal.editCount} ${meal.editCount == 1 ? 'time' : 'times'} • Last edit: ${meal.editedAt != null ? DateFormat('MMM d, yyyy').format(meal.editedAt!) : 'Unknown'}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                  if (meal.notes != null && meal.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Notes:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meal.notes!,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Nutrition summary
          Text(
            'Nutrition Summary',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildNutritionSummary(meal.nutrition),

          const SizedBox(height: 24),

          // Food items
          Text(
            'Food Items',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildFoodItems(meal.foodItems),

          const SizedBox(height: 24),

          // Image if available
          if (meal.imageId != null && meal.source == MealSource.aiAssisted) ...[
            Text(
              'Meal Image',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildMealImage(meal.imageId!),
          ],
        ],
      ),
    );
  }

  Widget _buildNutritionSummary(NutritionalSummary nutrition) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            ),
            if (nutrition.fiber != null ||
                nutrition.sugar != null ||
                nutrition.sodium != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (nutrition.fiber != null)
                    _buildSecondaryNutrition(
                      'Fiber',
                      '${nutrition.fiber!.toStringAsFixed(1)}g',
                    ),
                  if (nutrition.sugar != null)
                    _buildSecondaryNutrition(
                      'Sugar',
                      '${nutrition.sugar!.toStringAsFixed(1)}g',
                    ),
                  if (nutrition.sodium != null)
                    _buildSecondaryNutrition(
                      'Sodium',
                      '${nutrition.sodium!.toStringAsFixed(1)}mg',
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
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
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color,
                  ),
                ),
                Text(unit, style: TextStyle(fontSize: 12, color: color)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildSecondaryNutrition(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildFoodItems(List<FoodItem> foodItems) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: foodItems.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = foodItems[index];
          return ListTile(
            title: Text(
              _capitalizeFirst(item.name),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              '${item.quantity} ${item.unit} • ${item.calories} kcal',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'P: ${item.protein.toStringAsFixed(1)}g',
                  style: const TextStyle(fontSize: 12, color: Colors.blue),
                ),
                Text(
                  'C: ${item.carbs.toStringAsFixed(1)}g',
                  style: const TextStyle(fontSize: 12, color: Colors.orange),
                ),
                Text(
                  'F: ${item.fat.toStringAsFixed(1)}g',
                  style: const TextStyle(fontSize: 12, color: Colors.green),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMealImage(String imageId) {
    // This should be connected to your image storage service
    // For now, showing a placeholder
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: FutureBuilder<String>(
            // Replace this with actual image fetching logic
            future: Future.delayed(
              const Duration(milliseconds: 500),
              () =>
                  'https://via.placeholder.com/400x300/FFAA00/FFFFFF?text=Meal+Image',
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.broken_image,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Could not load image',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return Image.network(snapshot.data!, fit: BoxFit.cover);
            },
          ),
        ),
      ),
    );
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

  void _addToFavorites(
    BuildContext context,
    WidgetRef ref,
    MealHistoryEntry meal,
  ) async {
    // Get the user ID
    final userId = ref.read(currentUserIdProvider);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Adding to favorites...'),
            ],
          ),
        );
      },
    );

    try {
      // Convert food items to favorite food items
      final favoriteItems = meal.foodItems
          .map(
            (item) => goals.FavoriteFoodItem(
              name: item.name,
              quantity: item.quantity,
              unit: item.unit,
              calories: item.calories.toDouble(),
              protein: item.protein,
              carbs: item.carbs,
              fat: item.fat,
            ),
          )
          .toList();

      // Create nutritional summary
      final nutrition = goals.NutritionalSummary(
        calories: meal.nutrition.calories,
        protein: meal.nutrition.protein,
        carbs: meal.nutrition.carbs,
        fat: meal.nutrition.fat,
      );

      // Generate a good name for the favorite meal
      final mealName = MealNameGenerator.generateFromMealHistoryEntry(meal);

      // Create the favorite meal object
      final favoriteMeal = goals.FavoriteMeal(
        id: '', // Will be set by the repository
        userId: userId,
        name: mealName,
        foodItems: favoriteItems,
        nutrition: nutrition,
        mealType: meal.mealType,
        imageUrl: meal.imageId,
        notes: meal.notes,
        createdAt: DateTime.now(),
        useCount: 0,
      );

      // Save as favorite meal
      await ref
          .read(favoriteMealsProvider.notifier)
          .createFavoriteMeal(userId, favoriteMeal);

      // Close the loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$mealName added to favorites'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close the loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add meal to favorites: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
