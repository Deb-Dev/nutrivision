import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/nutrition_analytics_provider.dart';
import 'nutrition_analytics_widgets.dart';

class DistributionTab extends StatelessWidget {
  final NutritionAnalyticsState state;

  const DistributionTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final report = state.report;
    if (report == null) {
      return const Center(child: Text('No distribution data available'));
    }

    final mealDistribution = report.mealTypeDistribution;
    if (mealDistribution.isEmpty) {
      return const Center(
        child: Text('No meal distribution data available for this period'),
      );
    }

    // Calculate macronutrient distribution (% of total calories)
    final avg = report.averageNutrition;
    final proteinCalories = avg.protein * 4; // 4 calories per gram
    final carbsCalories = avg.carbs * 4; // 4 calories per gram
    final fatCalories = avg.fat * 9; // 9 calories per gram
    final totalCalories = avg.calories;

    final proteinPct = totalCalories > 0
        ? (proteinCalories / totalCalories).toDouble()
        : 0.0;
    final carbsPct = totalCalories > 0
        ? (carbsCalories / totalCalories).toDouble()
        : 0.0;
    final fatPct = totalCalories > 0
        ? (fatCalories / totalCalories).toDouble()
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Meal Type Distribution',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 250,
                width: double.infinity,
                child: _buildMealDistributionChart(mealDistribution),
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Macronutrient Distribution',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 250,
                width: double.infinity,
                child: _buildMacroDistributionChart(
                  proteinPct,
                  carbsPct,
                  fatPct,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealDistributionChart(Map<String, int> mealDistribution) {
    // Prepare data for pie chart
    final pieData = <PieChartSectionData>[];
    final totalMeals = mealDistribution.values.fold(
      0,
      (sum, count) => sum + count,
    );

    mealDistribution.forEach((mealType, count) {
      final percentage = totalMeals > 0 ? count / totalMeals : 0;

      pieData.add(
        PieChartSectionData(
          color: NutritionAnalyticsUtils.getMealTypeColor(mealType),
          value: percentage * 100,
          title: '${(percentage * 100).toInt()}%',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use more flexible layout for smaller screens
        if (constraints.maxWidth < 400) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              children: [
                SizedBox(
                  height: 160,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 24.0, 8.0, 16.0),
                    child: PieChart(
                      PieChartData(
                        sections: pieData,
                        centerSpaceRadius: 30,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 8.0,
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16,
                      runSpacing: 8,
                      children: mealDistribution.entries.map((entry) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: NutritionAnalyticsUtils.getMealTypeColor(
                                  entry.key,
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              NutritionAnalyticsUtils.capitalizeFirst(
                                entry.key,
                              ),
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${entry.value} meals',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // For larger screens, use row layout
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 200,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 24.0, 8.0, 16.0),
                    child: PieChart(
                      PieChartData(
                        sections: pieData,
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: mealDistribution.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: NutritionAnalyticsUtils.getMealTypeColor(
                                  entry.key,
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                NutritionAnalyticsUtils.capitalizeFirst(
                                  entry.key,
                                ),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Text(
                              '${entry.value} meals',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMacroDistributionChart(
    double proteinPct,
    double carbsPct,
    double fatPct,
  ) {
    // Prepare data for pie chart
    final pieData = <PieChartSectionData>[
      PieChartSectionData(
        color: Colors.blue,
        value: proteinPct * 100,
        title: '${(proteinPct * 100).toInt()}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: Colors.orange,
        value: carbsPct * 100,
        title: '${(carbsPct * 100).toInt()}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: Colors.green,
        value: fatPct * 100,
        title: '${(fatPct * 100).toInt()}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use more flexible layout for smaller screens
        if (constraints.maxWidth < 400) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              children: [
                SizedBox(
                  height: 160,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 24.0, 8.0, 16.0),
                    child: PieChart(
                      PieChartData(
                        sections: pieData,
                        centerSpaceRadius: 30,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 8.0,
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        WrappedLegendItem(
                          label: 'Protein',
                          color: Colors.blue,
                          value: '${(proteinPct * 100).toInt()}%',
                        ),
                        WrappedLegendItem(
                          label: 'Carbs',
                          color: Colors.orange,
                          value: '${(carbsPct * 100).toInt()}%',
                        ),
                        WrappedLegendItem(
                          label: 'Fat',
                          color: Colors.green,
                          value: '${(fatPct * 100).toInt()}%',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // For larger screens, use row layout
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 200,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 24.0, 8.0, 16.0),
                    child: PieChart(
                      PieChartData(
                        sections: pieData,
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LegendItem(
                        label: 'Protein',
                        color: Colors.blue,
                        value: '${(proteinPct * 100).toInt()}%',
                      ),
                      const SizedBox(height: 8),
                      LegendItem(
                        label: 'Carbs',
                        color: Colors.orange,
                        value: '${(carbsPct * 100).toInt()}%',
                      ),
                      const SizedBox(height: 8),
                      LegendItem(
                        label: 'Fat',
                        color: Colors.green,
                        value: '${(fatPct * 100).toInt()}%',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
