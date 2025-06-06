import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/grocery_list_provider.dart';
import '../../domain/entities/grocery_list.dart';
import '../../domain/entities/meal_plan.dart';

/// Screen for viewing and managing grocery lists
class GroceryListScreen extends ConsumerStatefulWidget {
  final String userId;
  final MealPlan?
  mealPlan; // Optional - if provided, shows grocery list for this plan

  const GroceryListScreen({super.key, required this.userId, this.mealPlan});

  @override
  ConsumerState<GroceryListScreen> createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends ConsumerState<GroceryListScreen> {
  GroceryList? _selectedList;
  final TextEditingController _newItemController = TextEditingController();
  final TextEditingController _newItemQuantityController =
      TextEditingController();
  final TextEditingController _newItemUnitController = TextEditingController();
  String _selectedCategory = '';

  @override
  void initState() {
    super.initState();

    // Load grocery lists when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGroceryLists();
    });
  }

  void _loadGroceryLists() {
    // This would be implemented to load grocery lists from the provider
    // For now, it's just a placeholder
  }

  /// Generate a grocery list from a meal plan
  void _generateGroceryList() {
    if (widget.mealPlan == null) {
      // Show a dialog to select a meal plan first
      _showMealPlanSelectionDialog();
    } else {
      // Show a dialog to enter a name for the grocery list
      _showGroceryListNameDialog(widget.mealPlan!);
    }
  }

  void _showMealPlanSelectionDialog() {
    // This would be implemented to show a dialog for selecting a meal plan
    // For now, it's just a placeholder
  }

  void _showGroceryListNameDialog(MealPlan mealPlan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Grocery List'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'List Name',
                hintText: 'e.g., Weekly Groceries',
              ),
              autofocus: true,
              onSubmitted: (value) {
                Navigator.of(context).pop(value);
              },
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
              // Generate a grocery list from the meal plan
              final name =
                  'Grocery List for ${mealPlan.name}'; // This would come from the text field

              // Generate the grocery list
              ref
                  .read(groceryListProvider.notifier)
                  .generateGroceryList(
                    userId: widget.userId,
                    mealPlanIds: [mealPlan.id],
                    name: name,
                  );

              Navigator.of(context).pop();
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  void _addNewItem() {
    if (_selectedList == null || _selectedCategory.isEmpty) return;

    final name = _newItemController.text.trim();
    final quantityText = _newItemQuantityController.text.trim();
    final unit = _newItemUnitController.text.trim();

    if (name.isEmpty || quantityText.isEmpty || unit.isEmpty) return;

    final quantity = double.tryParse(quantityText) ?? 1.0;

    // Create a new grocery item
    final newItem = GroceryItem(
      id: 'item_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      quantity: quantity,
      unit: unit,
      isChecked: false,
    );

    // Add the item to the selected category
    ref
        .read(groceryListProvider.notifier)
        .addItem(
          groceryList: _selectedList!,
          categoryId: _selectedCategory,
          item: newItem,
        );

    // Clear the input fields
    _newItemController.clear();
    _newItemQuantityController.clear();
    _newItemUnitController.clear();
  }

  void _toggleItemCheck(
    GroceryList list,
    String categoryId,
    String itemId,
    bool isChecked,
  ) {
    ref
        .read(groceryListProvider.notifier)
        .toggleItemCheck(
          groceryList: list,
          categoryId: categoryId,
          itemId: itemId,
          isChecked: isChecked,
        );
  }

  @override
  void dispose() {
    _newItemController.dispose();
    _newItemQuantityController.dispose();
    _newItemUnitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groceryListProvider);
    final groceryLists = state.groceryLists;

    // If a meal plan was provided and there's no selected list,
    // try to find a grocery list for that meal plan
    if (_selectedList == null && widget.mealPlan != null) {
      for (final list in groceryLists) {
        if (list.mealPlanIds.contains(widget.mealPlan!.id)) {
          _selectedList = list;
          break;
        }
      }
    }

    // If there's still no selected list but there are lists available, select the first one
    if (_selectedList == null && groceryLists.isNotEmpty) {
      _selectedList = groceryLists.first;
    }

    // If there's a selected list, select the first category by default
    if (_selectedList != null &&
        _selectedCategory.isEmpty &&
        _selectedList!.categories.isNotEmpty) {
      _selectedCategory = _selectedList!.categories.first.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedList?.name ?? 'Grocery Lists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _generateGroceryList,
            tooltip: 'Generate New List',
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.failure != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${state.failure!.message}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadGroceryLists,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            )
          : groceryLists.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No grocery lists yet',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Generate Grocery List'),
                    onPressed: _generateGroceryList,
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // List selector
                if (groceryLists.length > 1)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: DropdownButtonFormField<GroceryList>(
                      value: _selectedList,
                      decoration: const InputDecoration(
                        labelText: 'Select Grocery List',
                        border: OutlineInputBorder(),
                      ),
                      items: groceryLists
                          .map(
                            (list) => DropdownMenuItem(
                              value: list,
                              child: Text(list.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedList = value;
                            _selectedCategory = value.categories.isNotEmpty
                                ? value.categories.first.id
                                : '';
                          });
                        }
                      },
                    ),
                  ),

                // If there's a selected list, show the categories and items
                if (_selectedList != null) ...[
                  // Category tabs
                  if (_selectedList!.categories.length > 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: SizedBox(
                        height: 48,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedList!.categories.length,
                          itemBuilder: (context, index) {
                            final category = _selectedList!.categories[index];
                            final isSelected = category.id == _selectedCategory;

                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(category.name),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedCategory = category.id;
                                    });
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  // Add new item form
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // Item name
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _newItemController,
                            decoration: const InputDecoration(
                              labelText: 'Item',
                              hintText: 'e.g., Apples',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Quantity
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: _newItemQuantityController,
                            decoration: const InputDecoration(
                              labelText: 'Qty',
                              hintText: '1',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Unit
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: _newItemUnitController,
                            decoration: const InputDecoration(
                              labelText: 'Unit',
                              hintText: 'lb',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Add button
                        IconButton(
                          icon: const Icon(Icons.add_circle),
                          onPressed: _addNewItem,
                          color: Theme.of(context).primaryColor,
                        ),
                      ],
                    ),
                  ),

                  // Items list
                  Expanded(
                    child: _selectedCategory.isNotEmpty
                        ? _buildItemsList()
                        : const Center(child: Text('No category selected')),
                  ),

                  // Progress and action buttons
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // Progress indicator
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Progress: ${_selectedList!.completedItemsCount} / ${_getTotalItemsCount(_selectedList!)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: _getTotalItemsCount(_selectedList!) > 0
                                    ? _selectedList!.completedItemsCount /
                                          _getTotalItemsCount(_selectedList!)
                                    : 0,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Share button
                        OutlinedButton.icon(
                          icon: const Icon(Icons.share),
                          label: const Text('Share'),
                          onPressed: () {
                            // Share the grocery list
                          },
                        ),
                        const SizedBox(width: 8),
                        // Complete button
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check),
                          label: const Text('Complete'),
                          onPressed: _selectedList!.isCompleted
                              ? null
                              : () {
                                  // Mark the grocery list as completed
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedList!.isCompleted
                                ? Colors.grey
                                : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildItemsList() {
    // Find the selected category
    final categoryIndex = _selectedList!.categories.indexWhere(
      (category) => category.id == _selectedCategory,
    );

    if (categoryIndex == -1) {
      return const Center(child: Text('Category not found'));
    }

    final category = _selectedList!.categories[categoryIndex];
    final items = category.items;

    if (items.isEmpty) {
      return const Center(child: Text('No items in this category'));
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        return CheckboxListTile(
          title: Text(
            item.name,
            style: TextStyle(
              decoration: item.isChecked ? TextDecoration.lineThrough : null,
              color: item.isChecked ? Colors.grey : null,
            ),
          ),
          subtitle: Text('${item.quantity} ${item.unit}'),
          value: item.isChecked,
          onChanged: (value) {
            if (value != null) {
              _toggleItemCheck(
                _selectedList!,
                _selectedCategory,
                item.id,
                value,
              );
            }
          },
          secondary: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              // Remove the item
            },
          ),
        );
      },
    );
  }

  int _getTotalItemsCount(GroceryList list) {
    int count = 0;
    for (final category in list.categories) {
      count += category.items.length;
    }
    return count;
  }
}
