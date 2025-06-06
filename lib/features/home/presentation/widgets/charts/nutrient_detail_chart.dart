import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class NutrientDetailChart extends StatefulWidget {
  final double protein;
  final double carbs;
  final double fat;
  final double targetProtein;
  final double targetCarbs;
  final double targetFat;
  final Function(int) onNutrientSelected;
  final int selectedNutrientIndex;

  const NutrientDetailChart({
    super.key,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.targetProtein,
    required this.targetCarbs,
    required this.targetFat,
    required this.onNutrientSelected,
    required this.selectedNutrientIndex,
  });

  @override
  State<NutrientDetailChart> createState() => _NutrientDetailChartState();
}

class _NutrientDetailChartState extends State<NutrientDetailChart> {
  late int touchedIndex;

  @override
  void initState() {
    super.initState();
    touchedIndex = widget.selectedNutrientIndex;
  }

  @override
  void didUpdateWidget(NutrientDetailChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedNutrientIndex != widget.selectedNutrientIndex) {
      touchedIndex = widget.selectedNutrientIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final totalCalories =
        (widget.protein * 4) + (widget.carbs * 4) + (widget.fat * 9);

    final proteinPercentage = totalCalories > 0
        ? ((widget.protein * 4) / totalCalories * 100).round()
        : 0;

    final carbsPercentage = totalCalories > 0
        ? ((widget.carbs * 4) / totalCalories * 100).round()
        : 0;

    final fatPercentage = totalCalories > 0
        ? ((widget.fat * 9) / totalCalories * 100).round()
        : 0;

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
              'Nutrition Breakdown',
              style: theme.textTheme.titleSmall?.copyWith(
                // Smaller title
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8), // Reduced spacing

            Row(
              children: [
                // Pie chart - More compact
                Expanded(
                  flex: 2, // Adjusted flex
                  child: SizedBox(
                    height: 140, // Reduced height
                    child: PieChart(
                      PieChartData(
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 2,
                        centerSpaceRadius: 0,
                        sections: _showingSections(),
                        pieTouchData: PieTouchData(
                          touchCallback:
                              (FlTouchEvent event, pieTouchResponse) {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  return;
                                }
                                setState(() {
                                  touchedIndex = pieTouchResponse
                                      .touchedSection!
                                      .touchedSectionIndex;
                                  widget.onNutrientSelected(touchedIndex);
                                });
                              },
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8), // Reduced spacing
                // Legend and details - More compact
                Expanded(
                  flex: 3, // Adjusted flex
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem(
                        'Protein',
                        '${widget.protein.toInt()}g ($proteinPercentage%)',
                        Colors.blue,
                        touchedIndex == 0,
                        () => _selectNutrient(0),
                        '${widget.targetProtein.toInt()}g goal',
                        widget.protein / widget.targetProtein,
                      ),

                      const SizedBox(height: 4), // Reduced spacing

                      _buildLegendItem(
                        'Carbs',
                        '${widget.carbs.toInt()}g ($carbsPercentage%)',
                        Colors.green,
                        touchedIndex == 1,
                        () => _selectNutrient(1),
                        '${widget.targetCarbs.toInt()}g goal',
                        widget.carbs / widget.targetCarbs,
                      ),

                      const SizedBox(height: 4), // Reduced spacing

                      _buildLegendItem(
                        'Fat',
                        '${widget.fat.toInt()}g ($fatPercentage%)',
                        Colors.orange,
                        touchedIndex == 2,
                        () => _selectNutrient(2),
                        '${widget.targetFat.toInt()}g goal',
                        widget.fat / widget.targetFat,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8), // Reduced spacing
            // Total calories - More compact
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8), // Reduced padding
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8), // Smaller radius
              ),
              child: Column(
                children: [
                  Text(
                    'Total Calories',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      // Smaller text
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2), // Reduced spacing
                  Text(
                    '${totalCalories.toInt()} calories',
                    style: theme.textTheme.titleSmall?.copyWith(
                      // Smaller text
                      color: theme.colorScheme.primary,
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

  void _selectNutrient(int index) {
    setState(() {
      touchedIndex = index;
      widget.onNutrientSelected(index);
    });
  }

  Widget _buildLegendItem(
    String title,
    String value,
    Color color,
    bool isSelected,
    VoidCallback onTap,
    String goalText,
    double percentage,
  ) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6), // Smaller radius
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 6, // Reduced padding
          vertical: 4, // Reduced padding
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(6), // Smaller radius
          border: isSelected ? Border.all(color: color, width: 1) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10, // Smaller circle
                  height: 10, // Smaller circle
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6), // Reduced spacing
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    // Smaller text
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2), // Reduced spacing
            Padding(
              padding: const EdgeInsets.only(left: 16), // Reduced padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.bodySmall, // Smaller text
                  ),
                  const SizedBox(height: 2), // Reduced spacing
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            2,
                          ), // Smaller radius
                          child: LinearProgressIndicator(
                            value: percentage.clamp(0.0, 1.0),
                            backgroundColor: color.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: 4, // Smaller height
                          ),
                        ),
                      ),
                      const SizedBox(width: 4), // Reduced spacing
                      Text(
                        goalText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10, // Smaller text
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _showingSections() {
    return List.generate(3, (i) {
      final isTouched = i == touchedIndex;
      final radius = isTouched ? 65.0 : 60.0; // Reduced radius
      final fontSize = isTouched ? 16.0 : 14.0; // Reduced font size

      switch (i) {
        case 0: // Protein
          return PieChartSectionData(
            color: Colors.blue,
            value: widget.protein,
            title: '', // No title, we have a legend
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );

        case 1: // Carbs
          return PieChartSectionData(
            color: Colors.green,
            value: widget.carbs,
            title: '', // No title, we have a legend
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );

        case 2: // Fat
          return PieChartSectionData(
            color: Colors.orange,
            value: widget.fat,
            title: '', // No title, we have a legend
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );

        default:
          return PieChartSectionData(
            color: Colors.grey,
            value: 0,
            title: '',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
      }
    });
  }
}
