import 'package:flutter/material.dart';
import 'package:nutrivision/l10n/app_localizations.dart';
import '../services/meal_suggestions_service.dart';

class MealSuggestionsScreen extends StatefulWidget {
  const MealSuggestionsScreen({super.key});

  @override
  State<MealSuggestionsScreen> createState() => _MealSuggestionsScreenState();
}

class _MealSuggestionsScreenState extends State<MealSuggestionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MealSuggestionsService _suggestionsService = MealSuggestionsService();

  final List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _mealTypes.length + 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Suggestions'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            const Tab(text: 'Personalized'),
            ...(_mealTypes.map((type) => Tab(text: type))),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PersonalizedSuggestionsTab(suggestionsService: _suggestionsService),
          ...(_mealTypes.map((type) => _MealTypeSuggestionsTab(
                mealType: type,
                suggestionsService: _suggestionsService,
              ))),
        ],
      ),
    );
  }
}

class _PersonalizedSuggestionsTab extends StatefulWidget {
  final MealSuggestionsService suggestionsService;

  const _PersonalizedSuggestionsTab({required this.suggestionsService});

  @override
  State<_PersonalizedSuggestionsTab> createState() => _PersonalizedSuggestionsTabState();
}

class _PersonalizedSuggestionsTabState extends State<_PersonalizedSuggestionsTab> {
  List<MealSuggestion> _suggestions = [];
  bool _isLoading = false;
  String? _selectedFocus;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    setState(() => _isLoading = true);
    
    try {
      final suggestions = await widget.suggestionsService.getPersonalizedSuggestions(
        focus: _selectedFocus,
        count: 8,
      );
      
      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading suggestions: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meal Ideas Based on Your Preferences',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedFocus,
                  decoration: InputDecoration(
                    labelText: 'Focus (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All recommendations'),
                    ),
                    ...MealSuggestionsService.getAvailableFocusOptions().map((focus) {
                      return DropdownMenuItem<String>(
                        value: focus,
                        child: Text(MealSuggestionsService.getFocusDisplayName(focus)),
                      );
                    }),
                  ],
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedFocus = newValue;
                    });
                    _loadSuggestions();
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadSuggestions,
                tooltip: 'Refresh suggestions',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _suggestions.isEmpty
                    ? const Center(
                        child: Text('No suggestions available. Try adjusting your focus.'),
                      )
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: _suggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = _suggestions[index];
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showSuggestionDetails(suggestion),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getMealTypeColor(suggestion.mealType).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      suggestion.mealType,
                      style: TextStyle(
                        color: _getMealTypeColor(suggestion.mealType),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${suggestion.estimatedCalories} cal',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                suggestion.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  suggestion.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: suggestion.tags.take(3).map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getMealTypeColor(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.green;
      case 'dinner':
        return Colors.blue;
      case 'snack':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _showSuggestionDetails(MealSuggestion suggestion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(suggestion.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              suggestion.description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Meal Type: ${suggestion.mealType}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Est. ${suggestion.estimatedCalories} calories',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (suggestion.tags.isNotEmpty) ...[
              const Text(
                'Tags:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: suggestion.tags.map((tag) {
                  return Chip(
                    label: Text(
                      tag,
                      style: const TextStyle(fontSize: 12),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _MealTypeSuggestionsTab extends StatefulWidget {
  final String mealType;
  final MealSuggestionsService suggestionsService;

  const _MealTypeSuggestionsTab({
    required this.mealType,
    required this.suggestionsService,
  });

  @override
  State<_MealTypeSuggestionsTab> createState() => _MealTypeSuggestionsTabState();
}

class _MealTypeSuggestionsTabState extends State<_MealTypeSuggestionsTab> {
  List<MealSuggestion> _suggestions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    setState(() => _isLoading = true);
    
    try {
      final suggestions = await widget.suggestionsService.getMealSuggestions(
        mealType: widget.mealType,
        count: 6,
      );
      
      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading suggestions: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.mealType} Ideas',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadSuggestions,
                tooltip: 'Get new suggestions',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _suggestions.isEmpty
                    ? const Center(
                        child: Text('No suggestions available for this meal type.'),
                      )
                    : ListView.builder(
                        itemCount: _suggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = _suggestions[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(
                                suggestion.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(suggestion.description),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${suggestion.estimatedCalories} cal',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Wrap(
                                          spacing: 4,
                                          children: suggestion.tags.take(3).map((tag) {
                                            return Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                tag,
                                                style: const TextStyle(fontSize: 10),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              onTap: () => _showSuggestionDetails(suggestion),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showSuggestionDetails(MealSuggestion suggestion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(suggestion.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              suggestion.description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              'Estimated: ${suggestion.estimatedCalories} calories',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (suggestion.tags.isNotEmpty) ...[
              const Text(
                'Tags:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: suggestion.tags.map((tag) {
                  return Chip(
                    label: Text(
                      tag,
                      style: const TextStyle(fontSize: 12),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
