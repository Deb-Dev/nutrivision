import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/nutrition_goals_provider.dart';
import '../../domain/entities/nutrition_goals.dart';
import '../../../../core/providers/auth_providers.dart';
import 'package:uuid/uuid.dart';

class NutritionalGoalsScreen extends ConsumerStatefulWidget {
  const NutritionalGoalsScreen({super.key});

  @override
  ConsumerState<NutritionalGoalsScreen> createState() =>
      _NutritionalGoalsScreenState();
}

class _NutritionalGoalsScreenState
    extends ConsumerState<NutritionalGoalsScreen> {
  @override
  void initState() {
    super.initState();
    // Load nutritional goals when screen initializes
    Future.microtask(() {
      final userId = ref.read(currentUserIdProvider);
      ref.read(nutritionGoalsProvider.notifier).loadNutritionGoals(userId);
    });
  }

  void _showAddGoalDialog() {
    showDialog(
      context: context,
      builder: (context) => GoalEditDialog(
        onSave: (goal) {
          final userId = ref.read(currentUserIdProvider);
          ref.read(nutritionGoalsProvider.notifier).createGoal(userId, goal);
        },
      ),
    );
  }

  void _showEditGoalDialog(NutritionalGoal goal) {
    showDialog(
      context: context,
      builder: (context) => GoalEditDialog(
        goal: goal,
        onSave: (updatedGoal) {
          final userId = ref.read(currentUserIdProvider);
          ref
              .read(nutritionGoalsProvider.notifier)
              .updateGoal(userId, updatedGoal);
        },
      ),
    );
  }

  void _deleteGoal(NutritionalGoal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text(
          'Are you sure you want to delete the goal "${goal.name}"?',
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
                  .read(nutritionGoalsProvider.notifier)
                  .deleteGoal(userId, goal.id);
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
    final goalsState = ref.watch(nutritionGoalsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nutritional Goals')),
      body: _buildBody(goalsState),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGoalDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(NutritionGoalsState state) {
    switch (state.status) {
      case NutritionGoalsStatus.initial:
      case NutritionGoalsStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case NutritionGoalsStatus.error:
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
                      .read(nutritionGoalsProvider.notifier)
                      .loadNutritionGoals(userId);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );

      case NutritionGoalsStatus.updating:
        return Stack(
          children: [
            _buildGoalsList(state),
            Container(
              color: Colors.black.withValues(alpha: 0.1),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ],
        );

      case NutritionGoalsStatus.loaded:
      case NutritionGoalsStatus.updated:
        return _buildGoalsList(state);
    }
  }

  Widget _buildGoalsList(NutritionGoalsState state) {
    final goals = state.goals;
    final progress = state.currentProgress;

    if (goals == null || goals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.track_changes, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No nutritional goals set',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add your first goal',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddGoalDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Goal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (progress != null) _buildProgressSummary(progress),
        const SizedBox(height: 16),

        // Daily goals section
        Text(
          'Your Nutrition Goals',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // List of goals
        ...goals.map(
          (goal) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildGoalCard(goal, progress),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSummary(AverageNutrition progress) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Daily Average',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNutritionStat(
                  'Calories',
                  '${progress.calories.toInt()}',
                  'kcal',
                  Colors.red,
                ),
                _buildNutritionStat(
                  'Protein',
                  progress.protein.toStringAsFixed(1),
                  'g',
                  Colors.blue,
                ),
                _buildNutritionStat(
                  'Carbs',
                  progress.carbs.toStringAsFixed(1),
                  'g',
                  Colors.orange,
                ),
                _buildNutritionStat(
                  'Fat',
                  progress.fat.toStringAsFixed(1),
                  'g',
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionStat(
    String label,
    String value,
    String unit,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          '$label ($unit)',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalCard(NutritionalGoal goal, AverageNutrition? progress) {
    double? progressValue;

    // Calculate progress if we have current data
    if (progress != null) {
      switch (goal.type) {
        case GoalType.dailyCalories:
        case GoalType.weeklyCalories:
          progressValue = progress.calories / goal.targetValue;
          break;
        case GoalType.dailyProtein:
          progressValue = progress.protein / goal.targetValue;
          break;
        case GoalType.dailyCarbs:
          progressValue = progress.carbs / goal.targetValue;
          break;
        case GoalType.dailyFat:
          progressValue = progress.fat / goal.targetValue;
          break;
        case GoalType.waterIntake:
        case GoalType.custom:
          // For water intake and custom goals, use current progress if available
          progressValue = goal.currentProgress != null
              ? goal.currentProgress! / goal.targetValue
              : null;
          break;
      }

      // Clamp progress value to a reasonable range
      if (progressValue != null) {
        progressValue = progressValue.clamp(
          0.0,
          2.0,
        ); // Allow up to 200% for visual clarity
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    goal.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditGoalDialog(goal),
                      tooltip: 'Edit goal',
                      iconSize: 20,
                      splashRadius: 20,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteGoal(goal),
                      tooltip: 'Delete goal',
                      iconSize: 20,
                      splashRadius: 20,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_getGoalTypeDisplayText(goal.type)} '
              '${goal.targetValue} ${_getUnitForGoalType(goal.type)} '
              'daily',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            if (progressValue != null) ...[
              Row(
                children: [
                  Expanded(
                    child: ClipRounded(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progressValue.clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        color: _getProgressColor(progressValue),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${(progressValue * 100).toInt()}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getProgressColor(progressValue),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _getProgressMessage(goal, progressValue),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getProgressColor(double progressValue) {
    if (progressValue >= 0.9) {
      return Colors.green;
    } else if (progressValue >= 0.7) {
      return Colors.amber;
    } else {
      return Colors.red;
    }
  }

  String _getGoalTypeDisplayText(GoalType type) {
    switch (type) {
      case GoalType.dailyCalories:
        return 'Daily Calories Goal';
      case GoalType.dailyProtein:
        return 'Daily Protein Goal';
      case GoalType.dailyCarbs:
        return 'Daily Carbs Goal';
      case GoalType.dailyFat:
        return 'Daily Fat Goal';
      case GoalType.weeklyCalories:
        return 'Weekly Calories Goal';
      case GoalType.waterIntake:
        return 'Water Intake Goal';
      case GoalType.custom:
        return 'Custom Goal';
    }
  }

  String _getUnitForGoalType(GoalType type) {
    switch (type) {
      case GoalType.dailyCalories:
      case GoalType.weeklyCalories:
        return 'cal';
      case GoalType.dailyProtein:
      case GoalType.dailyCarbs:
      case GoalType.dailyFat:
        return 'g';
      case GoalType.waterIntake:
        return 'ml';
      case GoalType.custom:
        return '';
    }
  }

  String _getProgressMessage(NutritionalGoal goal, double progressValue) {
    // For simplicity, we'll assume all goals are "reach" type goals
    if (progressValue >= 0.9) {
      return 'Great job! You\'re meeting your goal.';
    } else if (progressValue >= 0.7) {
      return 'You\'re on track to reach your goal.';
    } else {
      return 'Keep working toward your goal.';
    }
  }
}

class GoalEditDialog extends StatefulWidget {
  final NutritionalGoal? goal;
  final Function(NutritionalGoal) onSave;

  const GoalEditDialog({super.key, this.goal, required this.onSave});

  @override
  State<GoalEditDialog> createState() => _GoalEditDialogState();
}

class _GoalEditDialogState extends State<GoalEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _targetController;
  late GoalType _selectedGoalType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.goal?.name ?? '');
    _targetController = TextEditingController(
      text: widget.goal?.targetValue.toString() ?? '',
    );
    _selectedGoalType = widget.goal?.type ?? GoalType.dailyCalories;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  void _saveGoal() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a goal name')));
      return;
    }

    final targetValue = double.tryParse(_targetController.text);
    if (targetValue == null || targetValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid target value')),
      );
      return;
    }

    final goal = NutritionalGoal(
      id: widget.goal?.id ?? const Uuid().v4(),
      userId: 'current_user_id', // TODO: Get from auth service
      name: name,
      type: _selectedGoalType,
      targetValue: targetValue,
      startDate: widget.goal?.startDate ?? DateTime.now(),
      lastUpdated: DateTime.now(),
    );

    widget.onSave(goal);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.goal == null ? 'Add Goal' : 'Edit Goal'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Goal Name',
                hintText: 'e.g., Daily Protein Target',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Goal type
            const Text(
              'Goal Type',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<GoalType>(
              value: _selectedGoalType,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: GoalType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getGoalTypeDisplayText(type)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedGoalType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            // Target value
            TextField(
              controller: _targetController,
              decoration: InputDecoration(
                labelText: 'Target Value',
                hintText: 'e.g., 2000',
                border: const OutlineInputBorder(),
                suffixText: _getUnitForGoalType(_selectedGoalType),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveGoal,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }

  String _getGoalTypeDisplayText(GoalType type) {
    switch (type) {
      case GoalType.dailyCalories:
        return 'Daily Calories Goal';
      case GoalType.dailyProtein:
        return 'Daily Protein Goal';
      case GoalType.dailyCarbs:
        return 'Daily Carbs Goal';
      case GoalType.dailyFat:
        return 'Daily Fat Goal';
      case GoalType.weeklyCalories:
        return 'Weekly Calories Goal';
      case GoalType.waterIntake:
        return 'Water Intake Goal';
      case GoalType.custom:
        return 'Custom Goal';
    }
  }

  String _getUnitForGoalType(GoalType type) {
    switch (type) {
      case GoalType.dailyCalories:
      case GoalType.weeklyCalories:
        return 'cal';
      case GoalType.dailyProtein:
      case GoalType.dailyCarbs:
      case GoalType.dailyFat:
        return 'g';
      case GoalType.waterIntake:
        return 'ml';
      case GoalType.custom:
        return '';
    }
  }
}

class ClipRounded extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;

  const ClipRounded({
    super.key,
    required this.child,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(borderRadius: borderRadius, child: child);
  }
}
