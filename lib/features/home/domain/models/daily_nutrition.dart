class DailyNutrition {
  final DateTime date;
  final double caloriesConsumed;
  final double proteinConsumed;
  final double carbsConsumed;
  final double fatConsumed;
  final double caloriesTarget;
  final double proteinTarget;
  final double carbsTarget;
  final double fatTarget;

  DailyNutrition({
    required this.date,
    required this.caloriesConsumed,
    required this.proteinConsumed,
    required this.carbsConsumed,
    required this.fatConsumed,
    required this.caloriesTarget,
    required this.proteinTarget,
    required this.carbsTarget,
    required this.fatTarget,
  });

  double get proteinPercentage => proteinTarget > 0
      ? (proteinConsumed / proteinTarget).clamp(0.0, 2.0)
      : 0.0;

  double get carbsPercentage =>
      carbsTarget > 0 ? (carbsConsumed / carbsTarget).clamp(0.0, 2.0) : 0.0;

  double get fatPercentage =>
      fatTarget > 0 ? (fatConsumed / fatTarget).clamp(0.0, 2.0) : 0.0;

  double get caloriesPercentage => caloriesTarget > 0
      ? (caloriesConsumed / caloriesTarget).clamp(0.0, 2.0)
      : 0.0;
}
