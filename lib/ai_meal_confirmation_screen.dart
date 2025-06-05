import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrivision/core/providers/firebase_providers.dart';

import 'services/ai_food_recognition_service.dart';
import 'services/food_database_service.dart';

class AIMealConfirmationScreen extends ConsumerStatefulWidget {
  final File image;
  final FoodRecognitionResult aiResult;

  const AIMealConfirmationScreen({
    super.key,
    required this.image,
    required this.aiResult,
  });

  @override
  ConsumerState<AIMealConfirmationScreen> createState() =>
      _AIMealConfirmationScreenState();
}

class _AIMealConfirmationScreenState
    extends ConsumerState<AIMealConfirmationScreen> {
  late List<EditableFoodItem> _editableItems;
  String _selectedMealType = 'Lunch';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;
  final FoodDatabaseService _foodService = FoodDatabaseService();

  final List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  @override
  void initState() {
    super.initState();
    _initializeEditableItems();
  }

  void _initializeEditableItems() {
    _editableItems = widget.aiResult.recognizedItems.map((item) {
      return EditableFoodItem(
        name: item.name,
        originalConfidence: item.confidence,
        estimatedServing: item.estimatedServing,
        nutrition: item.nutritionalEstimate,
        quantity: 1.0,
        servingUnit: _parseServingUnit(item.estimatedServing),
        isConfirmed:
            item.confidence >= 0.7, // Auto-confirm high confidence items
        needsReview: item.confidence < 0.6,
      );
    }).toList();
  }

  String _parseServingUnit(String serving) {
    // Extract unit from serving description (e.g., "100g" -> "g", "1 cup" -> "cup")
    final regex = RegExp(r'(\d+(?:\.\d+)?)\s*([a-zA-Z]+)');
    final match = regex.firstMatch(serving);
    return match?.group(2) ?? 'serving';
  }

  double _parseQuantity(String serving) {
    final regex = RegExp(r'(\d+(?:\.\d+)?)');
    final match = regex.firstMatch(serving);
    return double.tryParse(match?.group(1) ?? '1') ?? 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm AI Meal'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _addNewFoodItem,
            icon: const Icon(Icons.add),
            tooltip: 'Add Food Item',
          ),
        ],
      ),
      body: Column(
        children: [
          // Image preview
          Container(
            height: 120,
            width: double.infinity,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(widget.image, fit: BoxFit.cover),
            ),
          ),

          // Meal details section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Meal type dropdown
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedMealType,
                    decoration: const InputDecoration(
                      labelText: 'Meal Type',
                      border: OutlineInputBorder(),
                    ),
                    items: _mealTypes.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedMealType = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // Date button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Time button
                OutlinedButton.icon(
                  onPressed: _selectTime,
                  icon: const Icon(Icons.access_time, size: 16),
                  label: Text(
                    _selectedTime.format(context),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Food items list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _editableItems.length,
              itemBuilder: (context, index) {
                return _buildEditableFoodItem(_editableItems[index], index);
              },
            ),
          ),

          // Nutrition summary
          _buildNutritionSummary(),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.edit),
                    label: const Text('Back to Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveMeal,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isLoading ? 'Saving...' : 'Log Meal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableFoodItem(EditableFoodItem item, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with name and confidence
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _editFoodItem(index),
                    child: Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getConfidenceColor(
                      item.originalConfidence,
                    ).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(item.originalConfidence * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getConfidenceColor(item.originalConfidence),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _removeFoodItem(index),
                  icon: const Icon(Icons.close, color: Colors.red, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Quantity and serving controls
            Row(
              children: [
                // Quantity input
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    initialValue: item.quantity.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Qty',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final quantity = double.tryParse(value);
                      if (quantity != null && quantity > 0) {
                        setState(() {
                          _editableItems[index] = item.copyWith(
                            quantity: quantity,
                          );
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // Serving unit
                Expanded(
                  child: TextFormField(
                    initialValue: item.servingUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _editableItems[index] = item.copyWith(
                          servingUnit: value,
                        );
                      });
                    },
                  ),
                ),

                const SizedBox(width: 8),

                // Confirm checkbox
                Column(
                  children: [
                    Checkbox(
                      value: item.isConfirmed,
                      onChanged: (value) {
                        setState(() {
                          _editableItems[index] = item.copyWith(
                            isConfirmed: value ?? false,
                            needsReview: false,
                          );
                        });
                      },
                    ),
                    const Text('OK', style: TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),

            // Nutrition preview
            if (item.isConfirmed) ...[
              const SizedBox(height: 8),
              const Divider(),
              _buildItemNutrition(item),
            ],

            // Warning for low confidence items
            if (item.needsReview) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: Colors.orange.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        'Low confidence - please review',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemNutrition(EditableFoodItem item) {
    final adjustedNutrition = item.getAdjustedNutrition();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildNutrientChip(
          'Cal',
          adjustedNutrition.calories.toStringAsFixed(0),
          Colors.orange,
        ),
        _buildNutrientChip(
          'P',
          '${adjustedNutrition.protein.toStringAsFixed(1)}g',
          Colors.red,
        ),
        _buildNutrientChip(
          'C',
          '${adjustedNutrition.carbs.toStringAsFixed(1)}g',
          Colors.blue,
        ),
        _buildNutrientChip(
          'F',
          '${adjustedNutrition.fat.toStringAsFixed(1)}g',
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildNutrientChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 8, color: color)),
        ],
      ),
    );
  }

  Widget _buildNutritionSummary() {
    final confirmedItems = _editableItems
        .where((item) => item.isConfirmed)
        .toList();

    if (confirmedItems.isEmpty) {
      return const SizedBox.shrink();
    }

    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (var item in confirmedItems) {
      final nutrition = item.getAdjustedNutrition();
      totalCalories += nutrition.calories;
      totalProtein += nutrition.protein;
      totalCarbs += nutrition.carbs;
      totalFat += nutrition.fat;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.restaurant, color: Colors.green.shade600),
              const SizedBox(width: 8),
              const Text(
                'Total Meal Nutrition',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${confirmedItems.length} item${confirmedItems.length != 1 ? 's' : ''}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTotalNutrient(
                'Calories',
                totalCalories.toStringAsFixed(0),
                'kcal',
                Colors.orange,
              ),
              _buildTotalNutrient(
                'Protein',
                totalProtein.toStringAsFixed(1),
                'g',
                Colors.red,
              ),
              _buildTotalNutrient(
                'Carbs',
                totalCarbs.toStringAsFixed(1),
                'g',
                Colors.blue,
              ),
              _buildTotalNutrient(
                'Fat',
                totalFat.toStringAsFixed(1),
                'g',
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalNutrient(
    String label,
    String value,
    String unit,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(unit, style: TextStyle(fontSize: 10, color: color)),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _editFoodItem(int index) async {
    // TODO: Implement food search/replacement functionality
    // This would open a food search dialog similar to manual logging
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Food search/replacement coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _removeFoodItem(int index) {
    setState(() {
      _editableItems.removeAt(index);
    });
  }

  Future<void> _addNewFoodItem() async {
    // TODO: Implement add new food item functionality
    // This would open the same food search as manual logging
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add new food item coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _saveMeal() async {
    final confirmedItems = _editableItems
        .where((item) => item.isConfirmed)
        .toList();

    if (confirmedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please confirm at least one food item'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Combine date and time
      final timestamp = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Save each confirmed item as a separate meal entry
      for (var item in confirmedItems) {
        final adjustedNutrition = item.getAdjustedNutrition();

        await ref.read(firebaseFirestoreProvider)
            .collection('users')
            .doc(user.uid)
            .collection('loggedMeals')
            .add({
              'foodName': item.name,
              'calories': adjustedNutrition.calories,
              'proteinGrams': adjustedNutrition.protein,
              'carbsGrams': adjustedNutrition.carbs,
              'fatGrams': adjustedNutrition.fat,
              'quantity': item.quantity,
              'servingUnit': item.servingUnit,
              'mealType': _selectedMealType,
              'timestamp': Timestamp.fromDate(timestamp),
              'source': 'ai_assisted',
              'aiConfidence': item.originalConfidence,
              'estimatedServing': item.estimatedServing,
            });
      }

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${confirmedItems.length} food item${confirmedItems.length != 1 ? 's' : ''} logged successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to dashboard/meal logging
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving meal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Data model for editable food items
class EditableFoodItem {
  final String name;
  final double originalConfidence;
  final String estimatedServing;
  final NutritionalEstimate nutrition;
  final double quantity;
  final String servingUnit;
  final bool isConfirmed;
  final bool needsReview;

  EditableFoodItem({
    required this.name,
    required this.originalConfidence,
    required this.estimatedServing,
    required this.nutrition,
    required this.quantity,
    required this.servingUnit,
    required this.isConfirmed,
    required this.needsReview,
  });

  EditableFoodItem copyWith({
    String? name,
    double? originalConfidence,
    String? estimatedServing,
    NutritionalEstimate? nutrition,
    double? quantity,
    String? servingUnit,
    bool? isConfirmed,
    bool? needsReview,
  }) {
    return EditableFoodItem(
      name: name ?? this.name,
      originalConfidence: originalConfidence ?? this.originalConfidence,
      estimatedServing: estimatedServing ?? this.estimatedServing,
      nutrition: nutrition ?? this.nutrition,
      quantity: quantity ?? this.quantity,
      servingUnit: servingUnit ?? this.servingUnit,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      needsReview: needsReview ?? this.needsReview,
    );
  }

  // Calculate nutrition adjusted for quantity
  NutritionalEstimate getAdjustedNutrition() {
    return NutritionalEstimate(
      calories: (nutrition.calories * quantity).round(),
      protein: nutrition.protein * quantity,
      carbs: nutrition.carbs * quantity,
      fat: nutrition.fat * quantity,
    );
  }
}
