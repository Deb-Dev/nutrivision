import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/meal_plan_provider.dart';
import '../navigation/smart_meal_planning_navigation.dart';
import 'grocery_list_screen.dart';
import '../../domain/entities/meal_suggestion.dart';
import '../../domain/entities/meal_plan.dart';

/// Screen for planning meals in a calendar view
class MealPlanningScreen extends ConsumerStatefulWidget {
  final String userId;

  const MealPlanningScreen({super.key, required this.userId});

  @override
  ConsumerState<MealPlanningScreen> createState() => _MealPlanningScreenState();
}

class _MealPlanningScreenState extends ConsumerState<MealPlanningScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.week;
  final List<String> _mealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();

    // Load active meal plan when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadActiveMealPlan();
    });
  }

  void _loadActiveMealPlan() {
    // Load the active meal plan from the provider
    ref.read(mealPlanProvider.notifier).loadActiveMealPlan(widget.userId);

    // Also load all meal plans
    ref.read(mealPlanProvider.notifier).loadUserMealPlans(widget.userId);
  }

  /// Create a new meal plan
  void _createNewMealPlan() {
    final TextEditingController nameController = TextEditingController(
      text: 'Weekly Plan',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Meal Plan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Plan Name',
                hintText: 'e.g., Weekly Plan',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Get the entered plan name
              final name = nameController.text.isEmpty
                  ? 'Weekly Plan'
                  : nameController.text;

              // Create a new meal plan using the provider with minimal preferences
              await ref
                  .read(mealPlanProvider.notifier)
                  .createMealPlan(
                    userId: widget.userId,
                    name: name,
                    startDate: _selectedDay,
                    endDate: _selectedDay.add(const Duration(days: 7)),
                    preferences: {
                      'planName': name,
                      'skipAiSuggestions': true, // Flag to skip AI suggestions
                    },
                    makeActive: true,
                  );

              Navigator.of(context).pop();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  void _addMealForDay(String mealType) {
    final state = ref.read(mealPlanProvider);
    final activePlan = state.activeMealPlan;

    if (activePlan == null) {
      // Auto-create a meal plan if none exists
      _createDefaultMealPlan(mealType);
      return;
    }

    // Navigate to meal suggestions screen
    SmartMealPlanningNavigation.navigateToMealSuggestionsScreen(
      context,
      mealType,
      date: _selectedDay,
      onSuggestionSelected: (suggestion) {
        // Convert MealSuggestion to PlannedMeal
        final plannedMeal = _convertSuggestionToPlannedMeal(
          suggestion,
          mealType,
        );

        // Add the meal to the active plan
        ref
            .read(mealPlanProvider.notifier)
            .addMealToPlan(activePlan, _selectedDay, mealType, plannedMeal);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added ${suggestion.name} to ${_formatDate(_selectedDay)} $mealType',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Go back to meal planning screen
        Navigator.of(context).pop();
      },
    );
  }

  void _createDefaultMealPlan(String mealType) async {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Creating meal plan...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      // Create a default meal plan
      await ref
          .read(mealPlanProvider.notifier)
          .createMealPlan(
            userId: widget.userId,
            name: 'My Meal Plan - ${_formatDate(_selectedDay)}',
            startDate: _selectedDay,
            endDate: _selectedDay.add(const Duration(days: 7)), // Week plan
            preferences: {},
            makeActive: true,
          );

      // Wait for the state to update before proceeding
      await Future.delayed(const Duration(milliseconds: 500));

      // Navigate to meal suggestions screen
      if (mounted) {
        SmartMealPlanningNavigation.navigateToMealSuggestionsScreen(
          context,
          mealType,
          date: _selectedDay,
          onSuggestionSelected: (suggestion) {
            // Convert MealSuggestion to PlannedMeal
            final plannedMeal = _convertSuggestionToPlannedMeal(
              suggestion,
              mealType,
            );

            // Get the current active plan
            final activePlan = ref.read(mealPlanProvider).activeMealPlan;
            if (activePlan != null) {
              // Add the meal to the active plan
              ref
                  .read(mealPlanProvider.notifier)
                  .addMealToPlan(
                    activePlan,
                    _selectedDay,
                    mealType,
                    plannedMeal,
                  );

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Added ${suggestion.name} to ${_formatDate(_selectedDay)} $mealType',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }

            // Go back to meal planning screen
            Navigator.of(context).pop();
          },
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create meal plan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Convert a MealSuggestion to a PlannedMeal
  PlannedMeal _convertSuggestionToPlannedMeal(
    MealSuggestion suggestion,
    String mealType,
  ) {
    final id = 'pm_${DateTime.now().millisecondsSinceEpoch}_${suggestion.id}';

    return PlannedMeal(
      id: id,
      mealType: mealType,
      items: suggestion.items
          .map(
            (item) => PlannedFoodItem(
              id: 'pfi_${item.id}',
              name: item.name,
              quantity: item.quantity,
              unit: item.unit,
              nutritionalValues: item.nutritionalValues,
              imageUrl: item.imageUrl,
              notes: item.notes,
            ),
          )
          .toList(),
      estimatedNutrition: suggestion.estimatedNutrition,
      source: PlannedMealSource.suggested,
      notes: suggestion.description,
    );
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mealPlanProvider);
    final activePlan = state.activeMealPlan;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Planning'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewMealPlan,
            tooltip: 'Create New Plan',
          ),
        ],
      ),
      body: Column(
        children: [
          // Active plan indicator
          if (activePlan != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.restaurant_menu, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Active Plan',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              activePlan.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.shopping_cart_outlined),
                        label: const Text('Grocery List'),
                        onPressed: () {
                          // Navigate to grocery list screen with the active meal plan
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => GroceryListScreen(
                                userId: widget.userId,
                                mealPlan: activePlan,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Calendar
          TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: _onDaySelected,
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
            ),
          ),

          const Divider(),

          // Meals for selected day
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Meals for ${_selectedDay.month}/${_selectedDay.day}/${_selectedDay.year}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _mealTypes.length,
                      itemBuilder: (context, index) {
                        final mealType = _mealTypes[index];
                        final plannedMeal = activePlan
                            ?.plannedMeals[_selectedDay]
                            ?.meals[mealType];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: Icon(
                              _getMealTypeIcon(mealType),
                              color: _getMealTypeColor(mealType),
                            ),
                            title: Text(_capitalizeFirst(mealType)),
                            subtitle: plannedMeal != null
                                ? Text(
                                    plannedMeal.items.isNotEmpty
                                        ? plannedMeal.items
                                              .map((item) => item.name)
                                              .join(', ')
                                        : 'No items',
                                  )
                                : const Text('Not planned'),
                            trailing: IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => _addMealForDay(mealType),
                            ),
                            onTap: () {
                              if (plannedMeal != null) {
                                // Show meal details
                              } else {
                                // Add meal
                                _addMealForDay(mealType);
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMealTypeIcon(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snack':
        return Icons.bakery_dining;
      default:
        return Icons.restaurant;
    }
  }

  Color _getMealTypeColor(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.green;
      case 'dinner':
        return Colors.indigo;
      case 'snack':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Check if two dates represent the same day
  bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) {
      return false;
    }
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
