import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/nutrition_analytics_provider.dart';
import '../../domain/entities/nutrition_goals.dart';

class TrendsTab extends StatelessWidget {
  final NutritionAnalyticsState state;

  const TrendsTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final dailyData = state.report?.dailyNutrition ?? [];

    if (dailyData.isEmpty) {
      return const Center(
        child: Text('No trend data available for this period'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Calorie Trend',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: _buildCalorieChart(dailyData),
              ),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Macronutrient Trends',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: _buildMacroChart(dailyData),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieChart(List<DailyNutrition> dailyData) {
    // Sort data by date and limit to prevent overcrowding
    final sortedData = List<DailyNutrition>.from(dailyData)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Create line chart data
    final spots = <FlSpot>[];
    for (int i = 0; i < sortedData.length; i++) {
      spots.add(FlSpot(i.toDouble(), sortedData[i].calories.toDouble()));
    }

    final dateFormat = DateFormat('MM/dd');

    return LayoutBuilder(
      builder: (context, constraints) {
        return LineChart(
          LineChartData(
            gridData: const FlGridData(show: true),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  interval: null,
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 35,
                  interval: sortedData.length > 7 ? 2.0 : 1.0,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < sortedData.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          dateFormat.format(sortedData[index].date),
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: true),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Colors.red,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.red.withValues(alpha: 0.2),
                ),
              ),
            ],
            minX: 0,
            maxX: (sortedData.length - 1).toDouble(),
          ),
        );
      },
    );
  }

  Widget _buildMacroChart(List<DailyNutrition> dailyData) {
    // Sort data by date
    final sortedData = List<DailyNutrition>.from(dailyData)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Create line chart data for macros
    final proteinSpots = <FlSpot>[];
    final carbsSpots = <FlSpot>[];
    final fatSpots = <FlSpot>[];

    for (int i = 0; i < sortedData.length; i++) {
      proteinSpots.add(FlSpot(i.toDouble(), sortedData[i].protein));
      carbsSpots.add(FlSpot(i.toDouble(), sortedData[i].carbs));
      fatSpots.add(FlSpot(i.toDouble(), sortedData[i].fat));
    }

    final dateFormat = DateFormat('MM/dd');

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < sortedData.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      dateFormat.format(sortedData[index].date),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: proteinSpots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
          ),
          LineChartBarData(
            spots: carbsSpots,
            isCurved: true,
            color: Colors.orange,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
          ),
          LineChartBarData(
            spots: fatSpots,
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.black.withValues(alpha: 0.8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                String label;
                Color color;

                switch (spot.barIndex) {
                  case 0:
                    label = 'Protein: ${spot.y.toStringAsFixed(1)}g';
                    color = Colors.blue;
                    break;
                  case 1:
                    label = 'Carbs: ${spot.y.toStringAsFixed(1)}g';
                    color = Colors.orange;
                    break;
                  case 2:
                    label = 'Fat: ${spot.y.toStringAsFixed(1)}g';
                    color = Colors.green;
                    break;
                  default:
                    label = '';
                    color = Colors.black;
                }

                return LineTooltipItem(
                  label,
                  TextStyle(color: color, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
