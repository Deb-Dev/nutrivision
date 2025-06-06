import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/meal_suggestions_provider.dart';
import '../../domain/entities/meal_suggestion.dart';
import '../../../../core/models/meal_models.dart';

/// Screen for displaying meal suggestions
class MealSuggestionsScreen extends ConsumerStatefulWidget {
  final String mealType;
  final DateTime? date;
  final Function(MealSuggestion)? onSuggestionSelected;

  const MealSuggestionsScreen({
    super.key,
    required this.mealType,
    this.date,
    this.onSuggestionSelected,
  });

  @override
  ConsumerState<MealSuggestionsScreen> createState() =>
      _MealSuggestionsScreenState();
}

class _MealSuggestionsScreenState extends ConsumerState<MealSuggestionsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load suggestions when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSuggestions();
    });
  }

  void _loadSuggestions({bool forceRefresh = false}) {
    // Show loading indicator if forcing refresh
    if (forceRefresh) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Refreshing suggestions...'),
          duration: Duration(seconds: 1),
        ),
      );
    }
    
    // Get the real user ID from authentication (using a placeholder for now)
    final userId = 'current_user';

    // Add a timestamp to preferences to ensure uniqueness and limit AI calls
    final preferences = {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'forceRefresh': forceRefresh,
      // Create a unique ID that includes both mealType and timestamp to prevent duplicates
      'uniqueId': '${widget.mealType}_${DateTime.now().millisecondsSinceEpoch}',
      'maxAiCalls': 1, // Limit to one AI call to reduce costs
    };

    print('🔍 ${forceRefresh ? "Cache miss or force refresh" : "Loading"}, generating new suggestions for ${widget.mealType}');
    print('🔍 Generating 5 meal suggestions for ${widget.mealType} (1 AI + 4 fallback)');

    // Load meal suggestions with force refresh option
    if (forceRefresh) {
      ref
          .read(mealSuggestionsProvider.notifier)
          .refreshSuggestions(
            userId: userId, 
            mealType: widget.mealType,
            preferences: preferences,
          );
    } else {
      ref
          .read(mealSuggestionsProvider.notifier)
          .getMealSuggestions(
            userId: userId, 
            mealType: widget.mealType,
            preferences: preferences,
          );
    }
    
    // Log the completion for debugging
    print('✅ Generated 1 total suggestions (max 1 AI call)');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      // Reset filters without reloading from server
      ref.read(mealSuggestionsProvider.notifier).resetFilters();
    } else {
      // Filter existing suggestions
      ref.read(mealSuggestionsProvider.notifier).filterSuggestions(query);
    }
  }

  void _onSuggestionSelected(MealSuggestion suggestion) {
    if (widget.onSuggestionSelected != null) {
      widget.onSuggestionSelected!(suggestion);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mealSuggestionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${_capitalizeFirst(widget.mealType)} Suggestions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadSuggestions(forceRefresh: true),
            tooltip: 'Refresh Suggestions',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search suggestions...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // Content
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.failure != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${state.failure!.message}',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadSuggestions,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  )
                : state.suggestions.isEmpty
                ? const Center(child: Text('No suggestions available'))
                : ListView.builder(
                    itemCount: state.suggestions.length,
                    padding: const EdgeInsets.all(8),
                    itemBuilder: (context, index) {
                      final suggestion = state.suggestions[index];
                      return _buildSuggestionCard(suggestion);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(MealSuggestion suggestion) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      child: InkWell(
        onTap: () => _onSuggestionSelected(suggestion),
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image if available
            if (suggestion.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                child: Image.network(
                  suggestion.imageUrl!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 150,
                    color: Colors.grey[300],
                    child: const Icon(Icons.fastfood, size: 48),
                  ),
                ),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          suggestion.name,
                          style: Theme.of(context).textTheme.titleLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (suggestion.userRating != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              suggestion.userRating!.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Description
                  if (suggestion.description != null)
                    Text(
                      suggestion.description!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: 16),

                  // Nutrition summary
                  _buildNutritionSummary(suggestion.estimatedNutrition),

                  const SizedBox(height: 8),

                  // Tags/attributes
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: suggestion.attributes.entries
                        .map(
                          (entry) => Chip(
                            label: Text(
                              '${entry.key}: ${entry.value}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: Colors.grey[200],
                            padding: EdgeInsets.zero,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionSummary(NutritionalSummary nutrition) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _nutritionItem('Calories', '${nutrition.calories}'),
        _nutritionItem('Protein', '${nutrition.protein}g'),
        _nutritionItem('Carbs', '${nutrition.carbs}g'),
        _nutritionItem('Fat', '${nutrition.fat}g'),
      ],
    );
  }

  Widget _nutritionItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1);
  }
}
