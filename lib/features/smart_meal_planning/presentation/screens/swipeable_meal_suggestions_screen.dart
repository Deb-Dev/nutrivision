import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/single_meal_suggestion_provider.dart';
import '../../domain/entities/meal_suggestion.dart';
import '../widgets/swipeable_meal_card.dart';

/// Tinder-style swipeable meal suggestions screen
class SwipeableMealSuggestionsScreen extends ConsumerStatefulWidget {
  final String mealType;
  final DateTime? date;
  final Function(MealSuggestion)? onSuggestionAccepted;

  const SwipeableMealSuggestionsScreen({
    super.key,
    required this.mealType,
    this.date,
    this.onSuggestionAccepted,
  });

  @override
  ConsumerState<SwipeableMealSuggestionsScreen> createState() =>
      _SwipeableMealSuggestionsScreenState();
}

class _SwipeableMealSuggestionsScreenState
    extends ConsumerState<SwipeableMealSuggestionsScreen> {
  @override
  void initState() {
    super.initState();
    // Load the first suggestion when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNextSuggestion();
    });
  }

  void _loadNextSuggestion({String? rejectionReason}) {
    // Get the real user ID from authentication (using a placeholder for now)
    final userId = 'current_user';

    print('🍽️ Loading next ${widget.mealType} suggestion');

    ref
        .read(singleMealSuggestionProvider.notifier)
        .loadNextSuggestion(
          userId: userId,
          mealType: widget.mealType,
          date: widget.date ?? DateTime.now(),
          rejectionReason: rejectionReason,
        );
  }

  void _onAcceptSuggestion(MealSuggestion suggestion) async {
    print('✅ Accepted suggestion: ${suggestion.name}');

    final userId = 'current_user'; // TODO: Get from auth service
    final date = widget.date ?? DateTime.now();

    try {
      // Accept the suggestion through the provider (adds to meal plan)
      await ref
          .read(singleMealSuggestionProvider.notifier)
          .acceptSuggestion(
            userId: userId,
            suggestion: suggestion,
            mealType: widget.mealType,
            date: date,
          );

      // Call the callback if provided
      if (widget.onSuggestionAccepted != null) {
        widget.onSuggestionAccepted!(suggestion);
      }

      // Navigate back or show success message
      _showAcceptedMessage(suggestion);
    } catch (e) {
      print('❌ Error accepting suggestion: $e');
      _showErrorMessage('Failed to add meal to plan: $e');
    }
  }

  void _onRejectSuggestion(
    MealSuggestion suggestion, {
    String? reason,
    String? userNote,
  }) {
    print('❌ Rejected suggestion: ${suggestion.name}, reason: $reason');

    // Record the rejection for learning
    ref
        .read(singleMealSuggestionProvider.notifier)
        .recordRejection(
          userId: 'current_user',
          suggestionId: suggestion.id,
          mealType: widget.mealType,
          reason: reason,
          userNote: userNote,
        );

    // Load next suggestion with rejection context
    _loadNextSuggestion(rejectionReason: reason);
  }

  void _showAcceptedMessage(MealSuggestion suggestion) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${suggestion.name}" to your meal plan!'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'View Plan',
          textColor: Colors.white,
          onPressed: () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
    );

    // Wait a moment then go back
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _showRejectionDialog(MealSuggestion suggestion) {
    final reasonController = TextEditingController();
    String? selectedReason;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Why not this meal?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Help us improve future suggestions:'),
            const SizedBox(height: 16),
            // Quick rejection reasons
            Wrap(
              spacing: 8,
              children:
                  [
                        'Too complex',
                        'Don\'t like ingredients',
                        'Too many calories',
                        'Not enough protein',
                        'Already had recently',
                        'Other',
                      ]
                      .map(
                        (reason) => FilterChip(
                          label: Text(reason),
                          selected: selectedReason == reason,
                          onSelected: (selected) {
                            setState(() {
                              selectedReason = selected ? reason : null;
                            });
                          },
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 16),
            // Optional note
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Additional notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _onRejectSuggestion(
                suggestion,
                reason: selectedReason,
                userNote: reasonController.text.trim().isEmpty
                    ? null
                    : reasonController.text.trim(),
              );
            },
            child: const Text('Next Suggestion'),
          ),
        ],
      ),
    );
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(singleMealSuggestionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${_capitalizeFirst(widget.mealType)} Suggestions'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: SafeArea(
        child: state.isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Finding the perfect meal for you...'),
                  ],
                ),
              )
            : state.failure != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Unable to load suggestions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(state.failure.toString(), textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadNextSuggestion,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              )
            : state.currentSuggestion != null
            ? Column(
                children: [
                  // Suggestion counter/progress
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant_menu, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Suggestion ${state.rejectionCount + 1}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),

                  // Swipeable card
                  Expanded(
                    child: SwipeableMealCard(
                      suggestion: state.currentSuggestion!,
                      onAccept: _onAcceptSuggestion,
                      onReject: _showRejectionDialog,
                    ),
                  ),

                  // Action buttons (fallback for users who prefer tapping)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Reject button
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.red, width: 2),
                          ),
                          child: IconButton(
                            onPressed: () =>
                                _showRejectionDialog(state.currentSuggestion!),
                            icon: const Icon(Icons.close, color: Colors.red),
                            iconSize: 32,
                            padding: const EdgeInsets.all(16),
                          ),
                        ),

                        // Accept button
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green,
                          ),
                          child: IconButton(
                            onPressed: () =>
                                _onAcceptSuggestion(state.currentSuggestion!),
                            icon: const Icon(Icons.check, color: Colors.white),
                            iconSize: 32,
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Instructions
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Swipe right to add • Swipe left for next suggestion',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ),
                ],
              )
            : const Center(child: Text('No suggestions available')),
      ),
    );
  }

  String _capitalizeFirst(String str) {
    if (str.isEmpty) return str;
    return str[0].toUpperCase() + str.substring(1);
  }
}
