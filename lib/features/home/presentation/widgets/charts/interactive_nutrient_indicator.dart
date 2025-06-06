import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class InteractiveNutrientIndicator extends StatefulWidget {
  final String label;
  final double consumed;
  final double target;
  final Color color;
  final VoidCallback onTap;

  const InteractiveNutrientIndicator({
    super.key,
    required this.label,
    required this.consumed,
    required this.target,
    required this.color,
    required this.onTap,
  });

  @override
  State<InteractiveNutrientIndicator> createState() =>
      _InteractiveNutrientIndicatorState();
}

class _InteractiveNutrientIndicatorState
    extends State<InteractiveNutrientIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = widget.target > 0
        ? (widget.consumed / widget.target).clamp(0.0, 1.0)
        : 0.0;
    final percentage = (progress * 100).toInt();

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) {
        setState(() => _isHovering = true);
        _animationController.forward();
      },
      onTapUp: (_) {
        setState(() => _isHovering = false);
        _animationController.reverse();
      },
      onTapCancel: () {
        setState(() => _isHovering = false);
        _animationController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 60, // Reduced height
                    width: 60, // Reduced width
                    child: PieChart(
                      PieChartData(
                        startDegreeOffset: 270,
                        centerSpaceRadius: 25, // Reduced center space
                        sectionsSpace: 0,
                        sections: [
                          PieChartSectionData(
                            value: widget.consumed,
                            color: widget.color,
                            radius: 12, // Reduced radius
                            title: '',
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: widget.target > widget.consumed
                                ? widget.target - widget.consumed
                                : 0,
                            color: widget.color.withOpacity(0.2),
                            radius: 12, // Reduced radius
                            title: '',
                            showTitle: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.consumed.toInt()}g',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 13, // Reduced font size
                        ),
                      ),
                      Text(
                        '$percentage%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 10, // Reduced font size
                          color: _getPercentageColor(percentage, theme),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4), // Reduced spacing
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ), // Reduced padding
                decoration: BoxDecoration(
                  color: _isHovering
                      ? widget.color.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 11, // Reduced font size
                      ),
                    ),
                    Text(
                      '${widget.target.toInt()}g goal',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 9, // Reduced font size
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPercentageColor(int percentage, ThemeData theme) {
    if (percentage < 70) {
      return Colors.orange;
    } else if (percentage < 100) {
      return Colors.green;
    } else if (percentage <= 120) {
      return Colors.blue;
    } else {
      return Colors.red; // Over 120% of target
    }
  }
}
