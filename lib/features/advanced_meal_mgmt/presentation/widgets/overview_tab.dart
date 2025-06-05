import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../providers/nutrition_analytics_provider.dart';
import '../../domain/entities/nutrition_goals.dart';

class OverviewTab extends StatelessWidget {
  final NutritionAnalyticsState state;

  const OverviewTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final report = state.report!;
    final dateFormat = DateFormat('MMM d');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Report period
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Report Period',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${dateFormat.format(report.startDate)} - ${dateFormat.format(report.endDate)}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Based on ${report.dailyNutrition.length} days of data',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Average nutrition
          Text(
            'Average Daily Nutrition',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildAverageNutritionCard(report.averageNutrition),
          const SizedBox(height: 20),

          // Top foods
          const Text(
            'Your Top Foods',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildTopFoodsCard(report.topFoods),
        ],
      ),
    );
  }

  Widget _buildAverageNutritionCard(AverageNutrition average) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNutritionStat(
                  'Calories',
                  '${average.calories.toInt()}',
                  'kcal',
                  Colors.red,
                ),
                _buildNutritionStat(
                  'Protein',
                  average.protein.toStringAsFixed(1),
                  'g',
                  Colors.blue,
                ),
                _buildNutritionStat(
                  'Carbs',
                  average.carbs.toStringAsFixed(1),
                  'g',
                  Colors.orange,
                ),
                _buildNutritionStat(
                  'Fat',
                  average.fat.toStringAsFixed(1),
                  'g',
                  Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Progress bars for goals
            if (average.calorieGoalProgress != null)
              _buildGoalProgress(
                'Calories',
                average.calorieGoalProgress!,
                Colors.red,
              ),
            if (average.proteinGoalProgress != null)
              _buildGoalProgress(
                'Protein',
                average.proteinGoalProgress!,
                Colors.blue,
              ),
            if (average.carbsGoalProgress != null)
              _buildGoalProgress(
                'Carbs',
                average.carbsGoalProgress!,
                Colors.orange,
              ),
            if (average.fatGoalProgress != null)
              _buildGoalProgress('Fat', average.fatGoalProgress!, Colors.green),
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
          ),
        ),
        Text(
          '$label ($unit)',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildGoalProgress(String label, double progress, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$label Goal',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getProgressColor(progress),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              color: _getProgressColor(progress),
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.9) {
      return Colors.green;
    } else if (progress >= 0.7) {
      return Colors.amber;
    } else {
      return Colors.red;
    }
  }

  Widget _buildTopFoodsCard(List<String> topFoods) {
    if (topFoods.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No food data available for this period',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (int i = 0; i < topFoods.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _getTopFoodColor(i),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        topFoods[i],
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getTopFoodColor(int index) {
    switch (index) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
