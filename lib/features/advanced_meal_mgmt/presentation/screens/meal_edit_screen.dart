import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/meal_history_provider.dart';
import '../../../../core/models/meal_models.dart';
import '../../../../core/providers/auth_providers.dart';

class MealEditScreen extends ConsumerStatefulWidget {
  final MealHistoryEntry meal;

  const MealEditScreen({super.key, required this.meal});

  @override
  ConsumerState<MealEditScreen> createState() => _MealEditScreenState();
}

class _MealEditScreenState extends ConsumerState<MealEditScreen> {
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;
  late String _selectedMealType;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  List<FoodItemEditingController> _foodItemControllers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _descriptionController = TextEditingController(
      text: widget.meal.description ?? '',
    );
    _notesController = TextEditingController(text: widget.meal.notes ?? '');
    _selectedMealType = widget.meal.mealType;
    _selectedDate = widget.meal.loggedAt;
    _selectedTime = TimeOfDay.fromDateTime(widget.meal.loggedAt);

    // Create controllers for each food item
    _foodItemControllers = widget.meal.foodItems.map((item) {
      return FoodItemEditingController(
        nameController: TextEditingController(text: item.name),
        quantityController: TextEditingController(
          text: item.quantity.toString(),
        ),
        unitController: TextEditingController(text: item.unit),
        caloriesController: TextEditingController(
          text: item.calories.toString(),
        ),
        proteinController: TextEditingController(text: item.protein.toString()),
        carbsController: TextEditingController(text: item.carbs.toString()),
        fatController: TextEditingController(text: item.fat.toString()),
        initialFoodItem: item,
      );
    }).toList();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _notesController.dispose();
    for (final controller in _foodItemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  void _addNewFoodItem() {
    setState(() {
      _foodItemControllers.add(
        FoodItemEditingController(
          nameController: TextEditingController(),
          quantityController: TextEditingController(text: '1.0'),
          unitController: TextEditingController(text: 'serving'),
          caloriesController: TextEditingController(text: '0'),
          proteinController: TextEditingController(text: '0.0'),
          carbsController: TextEditingController(text: '0.0'),
          fatController: TextEditingController(text: '0.0'),
        ),
      );
    });
  }

  void _removeFoodItem(int index) {
    setState(() {
      _foodItemControllers[index].dispose();
      _foodItemControllers.removeAt(index);
    });
  }

  Future<void> _saveMeal() async {
    if (_foodItemControllers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one food item'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Build food items from controllers
      final foodItems = _foodItemControllers.map((controller) {
        return FoodItem(
          name: controller.nameController.text.trim(),
          quantity: double.tryParse(controller.quantityController.text) ?? 1.0,
          unit: controller.unitController.text.trim(),
          calories: double.tryParse(controller.caloriesController.text) ?? 0,
          protein: double.tryParse(controller.proteinController.text) ?? 0.0,
          carbs: double.tryParse(controller.carbsController.text) ?? 0.0,
          fat: double.tryParse(controller.fatController.text) ?? 0.0,
          foodId: controller.initialFoodItem?.foodId,
          fiber: controller.initialFoodItem?.fiber,
          sugar: controller.initialFoodItem?.sugar,
          sodium: controller.initialFoodItem?.sodium,
        );
      }).toList();

      // Calculate nutritional summary
      final nutrition = NutritionalSummary(
        calories: foodItems.fold(0, (sum, item) => sum + item.calories.toInt()),
        protein: foodItems.fold(0.0, (sum, item) => sum + item.protein),
        carbs: foodItems.fold(0.0, (sum, item) => sum + item.carbs),
        fat: foodItems.fold(0.0, (sum, item) => sum + item.fat),
        fiber: widget.meal.nutrition.fiber,
        sugar: widget.meal.nutrition.sugar,
        sodium: widget.meal.nutrition.sodium,
      );

      // Create updated meal entry
      final updatedMeal = widget.meal.copyWith(
        loggedAt: _selectedDate,
        mealType: _selectedMealType,
        description: _descriptionController.text.trim(),
        notes: _notesController.text.trim(),
        foodItems: foodItems,
        nutrition: nutrition,
        editedAt: DateTime.now(),
        editCount: widget.meal.editCount + 1,
      );

      // Update meal in repository
      final userId = ref.read(currentUserIdProvider);
      final result = await ref
          .read(mealHistoryProvider.notifier)
          .updateMeal(userId, updatedMeal);

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
          (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Meal updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Meal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save changes',
            onPressed: _isLoading ? null : _saveMeal,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meal type selector
                  Text(
                    'Meal Type',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildMealTypeSelector(),
                  const SizedBox(height: 24),

                  // Date and time
                  Text(
                    'Date & Time',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDateTimePicker(),
                  const SizedBox(height: 24),

                  // Description
                  Text(
                    'Description (optional)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      hintText: 'e.g., Homemade breakfast',
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 100,
                  ),
                  const SizedBox(height: 24),

                  // Food items
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Food Items',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _addNewFoodItem,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Item'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildFoodItemsList(),
                  const SizedBox(height: 24),

                  // Notes
                  Text(
                    'Notes (optional)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      hintText: 'Any additional information about this meal',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    maxLength: 300,
                  ),
                  const SizedBox(height: 32),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveMeal,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'SAVE CHANGES',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMealTypeSelector() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'breakfast',
          label: Text('Breakfast'),
          icon: Icon(Icons.breakfast_dining),
        ),
        ButtonSegment(
          value: 'lunch',
          label: Text('Lunch'),
          icon: Icon(Icons.lunch_dining),
        ),
        ButtonSegment(
          value: 'dinner',
          label: Text('Dinner'),
          icon: Icon(Icons.dinner_dining),
        ),
        ButtonSegment(
          value: 'snack',
          label: Text('Snack'),
          icon: Icon(Icons.apple),
        ),
      ],
      selected: {_selectedMealType},
      onSelectionChanged: (selection) {
        setState(() {
          _selectedMealType = selection.first;
        });
      },
    );
  }

  Widget _buildDateTimePicker() {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: _selectDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(dateFormat.format(_selectedDate)),
                  const Icon(Icons.calendar_today, size: 18),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: _selectTime,
            child: InputDecorator(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(timeFormat.format(_selectedDate)),
                  const Icon(Icons.access_time, size: 18),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFoodItemsList() {
    if (_foodItemControllers.isEmpty) {
      return Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.no_food, size: 48, color: Colors.grey),
                const SizedBox(height: 8),
                const Text(
                  'No food items added',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _addNewFoodItem,
                  child: const Text('Add First Item'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _foodItemControllers.length,
      itemBuilder: (context, index) {
        return _buildFoodItemCard(index);
      },
    );
  }

  Widget _buildFoodItemCard(int index) {
    final controller = _foodItemControllers[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Food Item ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeFoodItem(index),
                  tooltip: 'Remove item',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Food name
            TextField(
              controller: controller.nameController,
              decoration: const InputDecoration(
                labelText: 'Food Name *',
                hintText: 'e.g., Grilled Chicken',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Quantity and unit
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: controller.quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity *',
                      hintText: 'e.g., 1.5',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: controller.unitController,
                    decoration: const InputDecoration(
                      labelText: 'Unit *',
                      hintText: 'e.g., cup, serving, oz',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Calories
            TextField(
              controller: controller.caloriesController,
              decoration: const InputDecoration(
                labelText: 'Calories *',
                hintText: 'e.g., 250',
                border: OutlineInputBorder(),
                suffixText: 'kcal',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Macros
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.proteinController,
                    decoration: const InputDecoration(
                      labelText: 'Protein *',
                      hintText: 'e.g., 20',
                      border: OutlineInputBorder(),
                      suffixText: 'g',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller.carbsController,
                    decoration: const InputDecoration(
                      labelText: 'Carbs *',
                      hintText: 'e.g., 30',
                      border: OutlineInputBorder(),
                      suffixText: 'g',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller.fatController,
                    decoration: const InputDecoration(
                      labelText: 'Fat *',
                      hintText: 'e.g., 10',
                      border: OutlineInputBorder(),
                      suffixText: 'g',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FoodItemEditingController {
  final TextEditingController nameController;
  final TextEditingController quantityController;
  final TextEditingController unitController;
  final TextEditingController caloriesController;
  final TextEditingController proteinController;
  final TextEditingController carbsController;
  final TextEditingController fatController;
  final FoodItem? initialFoodItem;

  FoodItemEditingController({
    required this.nameController,
    required this.quantityController,
    required this.unitController,
    required this.caloriesController,
    required this.proteinController,
    required this.carbsController,
    required this.fatController,
    this.initialFoodItem,
  });

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    unitController.dispose();
    caloriesController.dispose();
    proteinController.dispose();
    carbsController.dispose();
    fatController.dispose();
  }
}
