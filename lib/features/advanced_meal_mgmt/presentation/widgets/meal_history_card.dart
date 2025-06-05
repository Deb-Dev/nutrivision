import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/meal_models.dart';
import '../../utils/meal_name_generator.dart';

class MealHistoryCard extends StatelessWidget {
  final MealHistoryEntry meal;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const MealHistoryCard({
    super.key,
    required this.meal,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
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
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    timeFormat.format(meal.loggedAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: onDelete,
                    iconSize: 20,
                    splashRadius: 20,
                    tooltip: 'Delete meal',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _generateMealTitle(meal),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    meal.source == MealSource.aiAssisted
                        ? Icons.camera_alt
                        : Icons.edit_note,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    meal.source == MealSource.aiAssisted
                        ? 'AI Assisted'
                        : 'Manual Entry',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (meal.editCount > 0) ...[
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Edited ${meal.editCount} ${meal.editCount == 1 ? 'time' : 'times'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              _buildNutritionRow(meal.nutrition, theme),
              const SizedBox(height: 12),
              if (meal.foodItems.isNotEmpty) ...[
                Text(
                  'Includes: ${_formatFoodItems(meal.foodItems)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionRow(NutritionalSummary nutrition, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildNutritionItem(
          'Calories',
          '${nutrition.calories}',
          'kcal',
          Colors.red,
          theme,
        ),
        _buildNutritionItem(
          'Protein',
          nutrition.protein.toStringAsFixed(1),
          'g',
          Colors.blue,
          theme,
        ),
        _buildNutritionItem(
          'Carbs',
          nutrition.carbs.toStringAsFixed(1),
          'g',
          Colors.orange,
          theme,
        ),
        _buildNutritionItem(
          'Fat',
          nutrition.fat.toStringAsFixed(1),
          'g',
          Colors.green,
          theme,
        ),
      ],
    );
  }

  Widget _buildNutritionItem(
    String label,
    String value,
    String unit,
    Color color,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          '$label ($unit)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _formatFoodItems(List<FoodItem> items) {
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

  /// Generate meal title using the centralized MealNameGenerator
  String _generateMealTitle(MealHistoryEntry meal) {
    print('🔍 [MEAL HISTORY CARD] Generating title for meal: ${meal.id}');
    print('🔍 [MEAL HISTORY CARD] Meal source: ${meal.source}');
    print('🔍 [MEAL HISTORY CARD] Food items count: ${meal.foodItems.length}');

    // Use the centralized MealNameGenerator - same logic as home screen
    return MealNameGenerator.generateFromMealHistoryEntry(meal);
  }
}
