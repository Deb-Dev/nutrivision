import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/daily_nutrition.dart';

class WeeklyProgressChart extends StatefulWidget {
  final List<DailyNutrition> weekData;
  final Function(int) onDaySelected;
  final int selectedDayIndex;
  final String title;

  const WeeklyProgressChart({
    super.key,
    required this.weekData,
    required this.onDaySelected,
    required this.selectedDayIndex,
    required this.title,
  });

  @override
  State<WeeklyProgressChart> createState() => _WeeklyProgressChartState();
}

class _WeeklyProgressChartState extends State<WeeklyProgressChart> {
  final List<Color> gradientColors = [Colors.green, Colors.greenAccent];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(8.0), // Reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: theme.textTheme.titleSmall?.copyWith(
                // Smaller title
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8), // Reduced spacing

            SizedBox(
              height: 120, // Further reduced height
              child: LineChart(_mainData(theme)),
            ),

            const SizedBox(height: 4), // Reduced spacing
            // Day selection row with improved visibility
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: widget.weekData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final day = entry.value;
                  final isSelected = widget.selectedDayIndex == index;

                  return InkWell(
                    onTap: () => widget.onDaySelected(index),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4.0,
                        horizontal: 6.0,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                        border: !isSelected
                            ? Border.all(
                                color: theme.colorScheme.outline.withOpacity(
                                  0.3,
                                ),
                                width: 1,
                              )
                            : null,
                      ),
                      child: Text(
                        _getDayLabel(day.date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _mainData(ThemeData theme) {
    // Calculate max Y value from data but ensure a minimum value for better display
    double dataMaxY = widget.weekData.fold<double>(
      0,
      (max, data) => data.caloriesConsumed > max ? data.caloriesConsumed : max,
    );
    // Add some headroom and ensure minimum value for better visualization
    final double maxY = dataMaxY > 500 ? dataMaxY * 1.1 : 500.0;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY / 4, // Fewer horizontal lines
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: theme.dividerColor.withOpacity(0.1), // More subtle grid
            strokeWidth: 0.5,
            dashArray: [5, 5], // Dotted lines for grid
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 18, // Further reduced size
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= widget.weekData.length) {
                return const SizedBox.shrink();
              }
              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(
                  _getShortDayLabel(widget.weekData[index].date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 9, // Smaller font size
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: maxY / 3, // Show even fewer labels
            getTitlesWidget: (value, meta) {
              // Only show even numbers
              if (value % 200 != 0 && value != 0) {
                return const SizedBox.shrink();
              }
              return SideTitleWidget(
                axisSide: meta.axisSide,
                space: 5, // Further reduced padding
                child: Text(
                  value.toInt().toString(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 9, // Smaller font size
                  ),
                ),
              );
            },
            reservedSize: 25, // Further reduced space
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: widget.weekData.length - 1.0,
      minY: 0,
      maxY: maxY,
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: theme.colorScheme.primaryContainer.withOpacity(0.8),
          getTooltipItems: (spots) {
            return spots.map((spot) {
              final index = spot.x.toInt();
              if (index < 0 || index >= widget.weekData.length) {
                return null;
              }

              final day = widget.weekData[index];
              return LineTooltipItem(
                'Calories: ${day.caloriesConsumed.toInt()}\n'
                'Target: ${day.caloriesTarget.toInt()}',
                theme.textTheme.bodySmall!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              );
            }).toList();
          },
        ),
        touchCallback: (event, response) {
          if (response != null &&
              response.lineBarSpots != null &&
              response.lineBarSpots!.isNotEmpty &&
              event is FlTapUpEvent) {
            final spotIndex = response.lineBarSpots![0].x.toInt();
            widget.onDaySelected(spotIndex);
          }
        },
        handleBuiltInTouches: true,
      ),
      lineBarsData: [_buildCaloriesLine(), _buildTargetLine()],
    );
  }

  LineChartBarData _buildCaloriesLine() {
    return LineChartBarData(
      spots: widget.weekData.asMap().entries.map((entry) {
        return FlSpot(entry.key.toDouble(), entry.value.caloriesConsumed);
      }).toList(),
      isCurved: true,
      gradient: LinearGradient(colors: gradientColors),
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, bar, index) {
          final isSelected = index == widget.selectedDayIndex;
          return FlDotCirclePainter(
            radius: isSelected ? 6 : 3,
            color: isSelected ? Colors.white : gradientColors[0],
            strokeWidth: isSelected ? 2 : 0,
            strokeColor: gradientColors[0],
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: gradientColors
              .map((color) => color.withOpacity(0.2))
              .toList(),
        ),
      ),
    );
  }

  LineChartBarData _buildTargetLine() {
    return LineChartBarData(
      spots: widget.weekData.asMap().entries.map((entry) {
        return FlSpot(entry.key.toDouble(), entry.value.caloriesTarget);
      }).toList(),
      isCurved: false,
      color: Colors.grey.withOpacity(
        0.7,
      ), // Using a solid color instead of gradient
      barWidth: 1.5, // Thinner line
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      dashArray: [4, 4], // Adjusted dash pattern
    );
  }

  String _getDayLabel(DateTime date) {
    return DateFormat('EEE').format(date);
  }

  String _getShortDayLabel(DateTime date) {
    return DateFormat('E').format(date).substring(0, 1);
  }
}

// Removed DailyNutrition class - now using import from models
