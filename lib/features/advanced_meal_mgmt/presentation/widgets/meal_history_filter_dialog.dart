import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/meal_models.dart';

class MealHistoryFilterDialog extends StatefulWidget {
  final MealHistoryFilter initialFilter;

  const MealHistoryFilterDialog({super.key, required this.initialFilter});

  @override
  State<MealHistoryFilterDialog> createState() =>
      _MealHistoryFilterDialogState();
}

class _MealHistoryFilterDialogState extends State<MealHistoryFilterDialog> {
  late DateTime? _startDate;
  late DateTime? _endDate;
  late List<String> _selectedMealTypes;
  late List<MealSource> _selectedSources;
  late TextEditingController _searchController;

  final Map<String, String> _mealTypeLabels = {
    'breakfast': 'Breakfast',
    'lunch': 'Lunch',
    'dinner': 'Dinner',
    'snack': 'Snack',
  };

  final Map<MealSource, String> _sourceLabels = {
    MealSource.manual: 'Manual Entries',
    MealSource.aiAssisted: 'AI-Assisted Entries',
  };

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialFilter.startDate;
    _endDate = widget.initialFilter.endDate;
    _selectedMealTypes = widget.initialFilter.mealTypes ?? [];
    _selectedSources = widget.initialFilter.sources ?? [];
    _searchController = TextEditingController(
      text: widget.initialFilter.searchQuery ?? '',
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (pickedDate != null) {
      setState(() {
        _startDate = pickedDate;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (pickedDate != null) {
      setState(() {
        _endDate = pickedDate;
      });
    }
  }

  void _toggleMealType(String mealType) {
    setState(() {
      if (_selectedMealTypes.contains(mealType)) {
        _selectedMealTypes.remove(mealType);
      } else {
        _selectedMealTypes.add(mealType);
      }
    });
  }

  void _toggleSource(MealSource source) {
    setState(() {
      if (_selectedSources.contains(source)) {
        _selectedSources.remove(source);
      } else {
        _selectedSources.add(source);
      }
    });
  }

  void _applyFilters() {
    final filter = MealHistoryFilter(
      startDate: _startDate,
      endDate: _endDate,
      mealTypes: _selectedMealTypes.isEmpty ? null : _selectedMealTypes,
      sources: _selectedSources.isEmpty ? [] : _selectedSources,
      searchQuery: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
    );

    Navigator.pop(context, filter);
  }

  void _resetFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedMealTypes = [];
      _selectedSources = [];
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return AlertDialog(
      title: const Text('Filter Meal History'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search query
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search meals',
                hintText: 'Enter food name or description',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Date range
            const Text(
              'Date Range',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectStartDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'From',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _startDate == null
                                ? 'Select'
                                : dateFormat.format(_startDate!),
                            style: TextStyle(
                              color: _startDate == null ? Colors.grey : null,
                            ),
                          ),
                          const Icon(Icons.calendar_today, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _selectEndDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'To',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _endDate == null
                                ? 'Select'
                                : dateFormat.format(_endDate!),
                            style: TextStyle(
                              color: _endDate == null ? Colors.grey : null,
                            ),
                          ),
                          const Icon(Icons.calendar_today, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Meal types
            const Text(
              'Meal Types',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _mealTypeLabels.entries.map((entry) {
                final isSelected = _selectedMealTypes.contains(entry.key);
                return FilterChip(
                  label: Text(entry.value),
                  selected: isSelected,
                  onSelected: (_) => _toggleMealType(entry.key),
                  backgroundColor: Colors.grey[200],
                  selectedColor: Theme.of(
                    context,
                  ).primaryColor.withValues(alpha: 0.2),
                  checkmarkColor: Theme.of(context).primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.black,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Source types
            const Text(
              'Entry Source',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _sourceLabels.entries.map((entry) {
                final isSelected = _selectedSources.contains(entry.key);
                return FilterChip(
                  label: Text(entry.value),
                  selected: isSelected,
                  onSelected: (_) => _toggleSource(entry.key),
                  backgroundColor: Colors.grey[200],
                  selectedColor: Theme.of(
                    context,
                  ).primaryColor.withValues(alpha: 0.2),
                  checkmarkColor: Theme.of(context).primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.black,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _resetFilters, child: const Text('Reset')),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _applyFilters,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Apply Filters'),
        ),
      ],
    );
  }
}
