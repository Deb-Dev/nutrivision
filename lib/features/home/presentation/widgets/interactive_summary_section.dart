import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrivision/core/providers/auth_providers.dart';
import 'package:nutrivision/features/home/presentation/widgets/charts/nutrient_detail_chart.dart';
import 'package:nutrivision/features/home/presentation/widgets/charts/weekly_progress_chart.dart';
import 'package:nutrivision/features/home/presentation/widgets/charts/interactive_nutrient_indicator.dart';
import 'package:nutrivision/features/home/data/services/nutrition_history_service.dart';

class InteractiveSummarySection extends ConsumerStatefulWidget {
  final double consumedProtein;
  final double consumedCarbs;
  final double consumedFat;
  final double targetProtein;
  final double targetCarbs;
  final double targetFat;

  const InteractiveSummarySection({
    super.key,
    required this.consumedProtein,
    required this.consumedCarbs,
    required this.consumedFat,
    required this.targetProtein,
    required this.targetCarbs,
    required this.targetFat,
  });

  @override
  ConsumerState<InteractiveSummarySection> createState() =>
      _InteractiveSummarySectionState();
}

class _InteractiveSummarySectionState
    extends ConsumerState<InteractiveSummarySection> {
  bool _showWeeklyChart = false;
  bool _showDetailedChart = false;
  int _selectedNutrientIndex = 0; // 0: protein, 1: carbs, 2: fat

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userId = ref.watch(currentUserIdProvider);
    // Watch the selected day index from the provider
    ref.watch(selectedDayIndexProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Daily Nutrients Title with Toggle - More Compact Design
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Title
                Text(
                  'Nutrition Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // View Mode Toggle - Now a single toggle group that controls both modes
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showDetailedChart = false;
                          _showWeeklyChart = false;
                        });
                      },
                      icon: Icon(Icons.donut_large, size: 18),
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        backgroundColor:
                            (!_showWeeklyChart && !_showDetailedChart)
                            ? theme.colorScheme.primaryContainer.withOpacity(
                                0.3,
                              )
                            : Colors.transparent,
                      ),
                      tooltip: 'Daily View',
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showDetailedChart = true;
                          _showWeeklyChart = false;
                        });
                      },
                      icon: Icon(Icons.pie_chart, size: 18),
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        backgroundColor: _showDetailedChart
                            ? theme.colorScheme.primaryContainer.withOpacity(
                                0.3,
                              )
                            : Colors.transparent,
                      ),
                      tooltip: 'Detailed View',
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showWeeklyChart = true;
                          _showDetailedChart = false;
                        });
                      },
                      icon: Icon(Icons.calendar_view_week, size: 18),
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        backgroundColor: _showWeeklyChart
                            ? theme.colorScheme.primaryContainer.withOpacity(
                                0.3,
                              )
                            : Colors.transparent,
                      ),
                      tooltip: 'Weekly View',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Conditional rendering based on view mode
        if (_showWeeklyChart)
          _buildWeeklyChart(userId)
        else if (_showDetailedChart)
          NutrientDetailChart(
            protein: widget.consumedProtein,
            carbs: widget.consumedCarbs,
            fat: widget.consumedFat,
            targetProtein: widget.targetProtein,
            targetCarbs: widget.targetCarbs,
            targetFat: widget.targetFat,
            onNutrientSelected: (index) {
              setState(() {
                _selectedNutrientIndex = index;
              });
            },
            selectedNutrientIndex: _selectedNutrientIndex,
          )
        else
          _buildInteractiveIndicators(),
      ],
    );
  }

  Widget _buildInteractiveIndicators() {
    return SizedBox(
      height: 120, // Fixed height to prevent expansion
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Protein
          Expanded(
            child: InteractiveNutrientIndicator(
              label: 'Protein',
              consumed: widget.consumedProtein,
              target: widget.targetProtein,
              color: Colors.blue,
              onTap: () => _onNutrientTap(0),
            ),
          ),

          // Carbs
          Expanded(
            child: InteractiveNutrientIndicator(
              label: 'Carbs',
              consumed: widget.consumedCarbs,
              target: widget.targetCarbs,
              color: Colors.green,
              onTap: () => _onNutrientTap(1),
            ),
          ),

          // Fat
          Expanded(
            child: InteractiveNutrientIndicator(
              label: 'Fat',
              consumed: widget.consumedFat,
              target: widget.targetFat,
              color: Colors.orange,
              onTap: () => _onNutrientTap(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(String? userId) {
    if (userId == null) {
      return const Center(child: Text('Sign in to view weekly data'));
    }

    final selectedDayIndex = ref.watch(selectedDayIndexProvider);

    return ref
        .watch(weeklyNutritionProvider(userId))
        .when(
          data: (weekData) {
            return WeeklyProgressChart(
              weekData: weekData,
              selectedDayIndex: selectedDayIndex,
              onDaySelected: (dayIndex) {
                ref.read(selectedDayIndexProvider.notifier).state = dayIndex;
              },
              title: 'Weekly Calorie Tracking',
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) =>
              Center(child: Text('Error loading weekly data: $error')),
        );
  }

  void _onNutrientTap(int index) {
    setState(() {
      _selectedNutrientIndex = index;
      _showDetailedChart = true;
      _showWeeklyChart = false;
    });
  }
}
