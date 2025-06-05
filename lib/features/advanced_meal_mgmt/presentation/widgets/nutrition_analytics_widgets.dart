import 'package:flutter/material.dart';
import '../../domain/entities/nutrition_goals.dart';

class PeriodSelector extends StatelessWidget {
  final AnalyticsPeriod currentPeriod;
  final Function(AnalyticsPeriod) onPeriodChanged;

  const PeriodSelector({
    super.key,
    required this.currentPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: AnalyticsPeriod.values.map((period) {
          final isSelected = period == currentPeriod;
          return GestureDetector(
            onTap: () => onPeriodChanged(period),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.green : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                period.name.replaceFirst(
                  period.name[0],
                  period.name[0].toUpperCase(),
                ),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final String value;

  const LegendItem({
    super.key,
    required this.label,
    required this.color,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class WrappedLegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final String value;

  const WrappedLegendItem({
    super.key,
    required this.label,
    required this.color,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(width: 8),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// Utility functions
class NutritionAnalyticsUtils {
  static Color getMealTypeColor(String mealType) {
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

  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
