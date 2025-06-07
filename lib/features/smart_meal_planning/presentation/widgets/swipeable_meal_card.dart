import 'package:flutter/material.dart';
import '../../domain/entities/meal_suggestion.dart';

/// Swipeable card widget for meal suggestions
class SwipeableMealCard extends StatefulWidget {
  final MealSuggestion suggestion;
  final Function(MealSuggestion) onAccept;
  final Function(MealSuggestion) onReject;

  const SwipeableMealCard({
    super.key,
    required this.suggestion,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<SwipeableMealCard> createState() => _SwipeableMealCardState();
}

class _SwipeableMealCardState extends State<SwipeableMealCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  double _dragOffset = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(2.0, 0.0)).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dx;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });

    const double threshold = 100.0;

    if (_dragOffset > threshold) {
      // Swiped right - accept
      _animateAndAccept();
    } else if (_dragOffset < -threshold) {
      // Swiped left - reject
      _animateAndReject();
    } else {
      // Snap back to center
      _resetPosition();
    }
  }

  void _animateAndAccept() {
    _animationController.forward().then((_) {
      widget.onAccept(widget.suggestion);
      _resetPosition();
    });
  }

  void _animateAndReject() {
    _animationController.forward().then((_) {
      widget.onReject(widget.suggestion);
      _resetPosition();
    });
  }

  void _resetPosition() {
    setState(() {
      _dragOffset = 0.0;
    });
    _animationController.reset();
  }

  Color _getCardColor() {
    if (_dragOffset > 50) {
      return Colors.green.withOpacity(0.1);
    } else if (_dragOffset < -50) {
      return Colors.red.withOpacity(0.1);
    }
    return Colors.white;
  }

  Widget _buildOverlay() {
    if (_dragOffset > 50) {
      return Positioned(
        top: 50,
        right: 20,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'ADD TO PLAN',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (_dragOffset < -50) {
      return Positioned(
        top: 50,
        left: 20,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.close, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'PASS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              _isDragging ? _dragOffset : _slideAnimation.value.dx * 100,
              0,
            ),
            child: Transform.rotate(
              angle: (_isDragging
                  ? _dragOffset / 1000
                  : _rotationAnimation.value),
              child: Transform.scale(
                scale: _isDragging ? 1.0 : _scaleAnimation.value,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  child: Stack(
                    children: [
                      // Main card
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: _getCardColor(),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Image placeholder or meal image
                            Container(
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.3),
                                    Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.1),
                                  ],
                                ),
                              ),
                              child: widget.suggestion.imageUrl != null
                                  ? ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                      child: Image.network(
                                        widget.suggestion.imageUrl!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Center(
                                      child: Icon(
                                        Icons.restaurant_menu,
                                        size: 64,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),

                            // Meal details
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Meal name
                                    Text(
                                      widget.suggestion.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),

                                    const SizedBox(height: 8),

                                    // Description
                                    if (widget.suggestion.description !=
                                        null) ...[
                                      Text(
                                        widget.suggestion.description!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(color: Colors.grey[600]),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 16),
                                    ],

                                    // Nutrition info
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          _buildNutritionItem(
                                            'Calories',
                                            '${widget.suggestion.estimatedNutrition.calories}',
                                            Icons.local_fire_department,
                                            Colors.orange,
                                          ),
                                          _buildNutritionItem(
                                            'Protein',
                                            '${widget.suggestion.estimatedNutrition.protein.toInt()}g',
                                            Icons.fitness_center,
                                            Colors.blue,
                                          ),
                                          _buildNutritionItem(
                                            'Carbs',
                                            '${widget.suggestion.estimatedNutrition.carbs.toInt()}g',
                                            Icons.grain,
                                            Colors.green,
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    // Preparation time
                                    if (widget
                                            .suggestion
                                            .preparationTimeMinutes !=
                                        null) ...[
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${widget.suggestion.preparationTimeMinutes!.toInt()} minutes',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Colors.grey[600],
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],

                                    const Spacer(),

                                    // Ingredients preview
                                    if (widget.suggestion.items.isNotEmpty) ...[
                                      Text(
                                        'Ingredients:',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        widget.suggestion.items
                                                .take(3)
                                                .map((item) => item.name)
                                                .join(', ') +
                                            (widget.suggestion.items.length > 3
                                                ? '...'
                                                : ''),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Swipe overlay
                      _buildOverlay(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNutritionItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
