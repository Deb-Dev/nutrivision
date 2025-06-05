import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/meal_history_provider.dart';
import '../../../../core/models/meal_models.dart'; // Core models with MealHistoryFilter
import '../widgets/meal_history_filter_dialog.dart';
import '../widgets/meal_history_card.dart';
import 'meal_detail_screen.dart';
import '../../../../core/providers/auth_providers.dart';

class MealHistoryScreen extends ConsumerStatefulWidget {
  const MealHistoryScreen({super.key});

  @override
  ConsumerState<MealHistoryScreen> createState() => _MealHistoryScreenState();
}

class _MealHistoryScreenState extends ConsumerState<MealHistoryScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load meal history when screen initializes
    Future.microtask(() {
      final userId = ref.read(currentUserIdProvider);
      // Reset filters to ensure we have proper date range
      ref.read(mealHistoryProvider.notifier).resetFilters(userId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterDialog() async {
    final currentFilter = ref.read(mealHistoryProvider).filter;

    final result = await showDialog<MealHistoryFilter>(
      context: context,
      builder: (context) =>
          MealHistoryFilterDialog(initialFilter: currentFilter), // Removed cast
    );

    if (result != null) {
      final userId = ref.read(currentUserIdProvider);
      ref.read(mealHistoryProvider.notifier).applyFilter(userId, result);
    }
  }

  void _resetFilters() {
    final userId = ref.read(currentUserIdProvider);
    ref.read(mealHistoryProvider.notifier).resetFilters(userId);
  }

  void _navigateToMealDetail(String mealId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MealDetailScreen(mealId: mealId)),
    );
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _applySearchFilter('');
      }
    });
  }

  void _applySearchFilter(String query) {
    final userId = ref.read(currentUserIdProvider);
    final currentFilter = ref.read(mealHistoryProvider).filter;
    final newFilter = currentFilter.copyWith(
      searchQuery: query.isEmpty ? null : query,
    );

    ref.read(mealHistoryProvider.notifier).applyFilter(userId, newFilter);
  }

  @override
  Widget build(BuildContext context) {
    final mealHistoryState = ref.watch(mealHistoryProvider);
    final isFiltering = mealHistoryState.isFiltering;
    final hasActiveFilters =
        mealHistoryState.filter.startDate != null ||
        mealHistoryState.filter.endDate != null ||
        mealHistoryState.filter.mealTypes != null ||
        mealHistoryState.filter.sources != null ||
        mealHistoryState.filter.searchQuery != null;

    return Scaffold(
      appBar: _isSearching
          ? AppBar(
              title: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search meals...',
                  border: InputBorder.none,
                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                autofocus: true,
                onChanged: _applySearchFilter,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _toggleSearch,
                ),
              ],
            )
          : AppBar(
              title: const Text('Meal History'),
              actions: [
                if (hasActiveFilters)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Clear filters',
                    onPressed: _resetFilters,
                  ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  tooltip: 'Filter meals',
                  onPressed: _showFilterDialog,
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'Search meals',
                  onPressed: _toggleSearch,
                ),
              ],
            ),
      body: _buildBody(mealHistoryState, isFiltering),
      floatingActionButton: _isSearching
          ? FloatingActionButton(
              onPressed: () {
                _toggleSearch();
              },
              child: const Icon(Icons.close),
            )
          : null,
    );
  }

  Widget _buildBody(MealHistoryState state, bool isFiltering) {
    switch (state.status) {
      case MealHistoryStatus.initial:
      case MealHistoryStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case MealHistoryStatus.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                state.errorMessage ?? 'An error occurred',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final userId = ref.read(currentUserIdProvider);
                  ref
                      .read(mealHistoryProvider.notifier)
                      .loadMealHistory(userId);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );

      case MealHistoryStatus.loaded:
        if (isFiltering) {
          return Stack(
            children: [
              _buildMealList(state),
              Container(
                color: Colors.black.withValues(alpha: 0.1),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ],
          );
        }

        final groupedMeals = state.groupedMeals;
        if (groupedMeals == null || groupedMeals.totalMeals == 0) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.no_meals, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No meals found',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 8),
                Text(
                  'Try adjusting your filters or log a new meal',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return _buildMealList(state);
    }
  }

  Widget _buildMealList(MealHistoryState state) {
    final groupedMeals = state.groupedMeals;
    if (groupedMeals == null) return const SizedBox.shrink();

    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final dates = groupedMeals.groupedMeals.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Sort by date (newest first)

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final date = dates[index];
        final meals = groupedMeals.groupedMeals[date] ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                dateFormat.format(date),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ...meals.map(
              (meal) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: MealHistoryCard(
                  meal: meal,
                  onTap: () => _navigateToMealDetail(meal.id),
                  onDelete: () {
                    // Show confirmation dialog before deleting
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Meal'),
                        content: const Text(
                          'Are you sure you want to delete this meal? '
                          'This action cannot be undone.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              final userId = ref.read(currentUserIdProvider);
                              ref
                                  .read(mealHistoryProvider.notifier)
                                  .deleteMeal(userId, meal.id);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            if (index < dates.length - 1) const Divider(),
          ],
        );
      },
    );
  }
}
