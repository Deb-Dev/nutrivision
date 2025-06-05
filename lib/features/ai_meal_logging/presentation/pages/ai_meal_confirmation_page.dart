import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/ai_meal_recognition.dart';
import '../providers/ai_meal_logging_providers.dart';

/// Modern AI meal confirmation page with Riverpod state management
class AIMealConfirmationPage extends ConsumerStatefulWidget {
  final AIMealRecognitionResult analysisResult;
  final File imageFile;

  const AIMealConfirmationPage({
    super.key,
    required this.analysisResult,
    required this.imageFile,
  });

  @override
  ConsumerState<AIMealConfirmationPage> createState() =>
      _AIMealConfirmationPageState();
}

class _AIMealConfirmationPageState
    extends ConsumerState<AIMealConfirmationPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedMealType = 'lunch';
  List<ConfirmedMealItem> _confirmedItems = [];

  @override
  void initState() {
    super.initState();
    _initializeConfirmedItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initializeConfirmedItems() {
    // Convert AI recognized items to confirmed items
    _confirmedItems = widget.analysisResult.recognizedItems.map((item) {
      return ConfirmedMealItem(
        name: item.name,
        foodId: item.foodId ?? 'unknown',
        quantity: 1.0,
        servingUnit: item.estimatedServing,
        nutrition: item.nutritionalEstimate,
        wasAIRecognized: true,
        originalConfidence: item.confidence,
      );
    }).toList();
  }

  NutritionalEstimate _calculateTotalNutrition() {
    if (_confirmedItems.isEmpty) {
      return const NutritionalEstimate(
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
      );
    }

    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalFiber = 0;
    double totalSugar = 0;
    double totalSodium = 0;

    for (final item in _confirmedItems) {
      final nutrition = item.nutrition;
      totalCalories += nutrition.calories;
      totalProtein += nutrition.protein;
      totalCarbs += nutrition.carbs;
      totalFat += nutrition.fat;
      totalFiber += nutrition.fiber ?? 0;
      totalSugar += nutrition.sugar ?? 0;
      totalSodium += nutrition.sodium ?? 0;
    }

    return NutritionalEstimate(
      calories: totalCalories.round(),
      protein: totalProtein,
      carbs: totalCarbs,
      fat: totalFat,
      fiber: totalFiber,
      sugar: totalSugar,
      sodium: totalSodium,
    );
  }

  Future<void> _logMeal() async {
    if (_confirmedItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No items to log')));
      return;
    }

    // Generate image ID (in real app, this would be uploaded to storage)
    final imageId = 'meal_${DateTime.now().millisecondsSinceEpoch}';

    final result = await ref.read(
      logAIMealProvider(
        confirmedItems: _confirmedItems,
        imageId: imageId,
        originalAnalysis: widget.analysisResult,
        mealType: _selectedMealType,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      ).future,
    );

    if (mounted) {
      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to log meal: ${failure.message}'),
              backgroundColor: Colors.red,
            ),
          );
        },
        (mealLog) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Meal logged successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      );
    }
  }

  void _removeItem(int index) {
    setState(() {
      _confirmedItems.removeAt(index);
    });
  }

  void _updateItemQuantity(int index, double newQuantity) {
    setState(() {
      final item = _confirmedItems[index];
      final originalNutrition = item.nutrition;

      // Scale nutrition based on quantity change
      final scaledNutrition = NutritionalEstimate(
        calories: (originalNutrition.calories * newQuantity).round(),
        protein: originalNutrition.protein * newQuantity,
        carbs: originalNutrition.carbs * newQuantity,
        fat: originalNutrition.fat * newQuantity,
        fiber: (originalNutrition.fiber ?? 0) * newQuantity,
        sugar: (originalNutrition.sugar ?? 0) * newQuantity,
        sodium: (originalNutrition.sodium ?? 0) * newQuantity,
      );

      _confirmedItems[index] = item.copyWith(
        quantity: newQuantity,
        nutrition: scaledNutrition,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalNutrition = _calculateTotalNutrition();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Your Meal'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _confirmedItems.isNotEmpty ? _logMeal : null,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: Column(
        children: [
          // Image and meal type section
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Image thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    widget.imageFile,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),

                // Meal type selector
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Meal Type',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButton<String>(
                        value: _selectedMealType,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                            value: 'breakfast',
                            child: Text('Breakfast'),
                          ),
                          DropdownMenuItem(
                            value: 'lunch',
                            child: Text('Lunch'),
                          ),
                          DropdownMenuItem(
                            value: 'dinner',
                            child: Text('Dinner'),
                          ),
                          DropdownMenuItem(
                            value: 'snack',
                            child: Text('Snack'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedMealType = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Nutrition summary
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Nutrition',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNutritionItem(
                      'Calories',
                      '${totalNutrition.calories}',
                      'kcal',
                      Colors.red,
                    ),
                    _buildNutritionItem(
                      'Protein',
                      totalNutrition.protein.toStringAsFixed(1),
                      'g',
                      Colors.blue,
                    ),
                    _buildNutritionItem(
                      'Carbs',
                      totalNutrition.carbs.toStringAsFixed(1),
                      'g',
                      Colors.orange,
                    ),
                    _buildNutritionItem(
                      'Fat',
                      totalNutrition.fat.toStringAsFixed(1),
                      'g',
                      Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Food items list
          Expanded(
            child: _confirmedItems.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _confirmedItems.length,
                    itemBuilder: (context, index) {
                      return _buildFoodItemCard(_confirmedItems[index], index);
                    },
                  ),
          ),

          // Notes section
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Add any notes about this meal...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ),

          // Log meal button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _confirmedItems.isNotEmpty ? _logMeal : null,
              icon: const Icon(Icons.restaurant),
              label: const Text('Log Meal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
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
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          unit,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildFoodItemCard(ConfirmedMealItem item, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (item.wasAIRecognized &&
                          item.originalConfidence != null)
                        Text(
                          'AI Confidence: ${(item.originalConfidence! * 100).toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _removeItem(index),
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red[600],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Quantity adjustment
            Row(
              children: [
                const Text('Quantity: '),
                IconButton(
                  onPressed: item.quantity > 0.5
                      ? () => _updateItemQuantity(index, item.quantity - 0.5)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '${item.quantity.toStringAsFixed(1)} ${item.servingUnit}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                IconButton(
                  onPressed: () =>
                      _updateItemQuantity(index, item.quantity + 0.5),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Nutrition info
            Text(
              '${item.nutrition.calories} kcal • ${item.nutrition.protein.toStringAsFixed(1)}g protein • ${item.nutrition.carbs.toStringAsFixed(1)}g carbs • ${item.nutrition.fat.toStringAsFixed(1)}g fat',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'No Food Items',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'No food items were recognized in the image. You can manually add items using the search function.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
