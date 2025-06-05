import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrivision/core/providers/firebase_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutrivision/l10n/app_localizations.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/food_database_service.dart';
import 'features/ai_meal_logging/presentation/pages/ai_photo_meal_page.dart';

class EnhancedLogMealScreen extends ConsumerStatefulWidget {
  const EnhancedLogMealScreen({super.key});

  @override
  ConsumerState<EnhancedLogMealScreen> createState() =>
      _EnhancedLogMealScreenState();
}

class _EnhancedLogMealScreenState extends ConsumerState<EnhancedLogMealScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FoodDatabaseService _foodService = FoodDatabaseService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: Text(l10n.logMealTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: const Icon(Icons.search), text: 'Search Foods'),
            Tab(icon: const Icon(Icons.qr_code_scanner), text: 'Scan Barcode'),
            Tab(icon: const Icon(Icons.edit), text: 'Manual Entry'),
            Tab(icon: const Icon(Icons.camera_alt), text: 'AI Photo'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _FoodSearchTab(foodService: _foodService),
          _BarcodeScanTab(foodService: _foodService),
          _ManualEntryTab(),
          const AIPhotoMealPage(),
        ],
      ),
    );
  }
}

class _FoodSearchTab extends StatefulWidget {
  final FoodDatabaseService foodService;

  const _FoodSearchTab({required this.foodService});

  @override
  State<_FoodSearchTab> createState() => _FoodSearchTabState();
}

class _FoodSearchTabState extends State<_FoodSearchTab> {
  final TextEditingController _searchController = TextEditingController();
  List<FoodItem> _searchResults = [];
  bool _isSearching = false;
  String _searchError = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchFoods(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _searchError = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = '';
    });

    try {
      final results = await widget.foodService.searchFoods(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchError = e.toString();
        _isSearching = false;
        _searchResults = [];
      });
    }
  }

  void _selectFood(FoodItem food) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => _FoodDetailsScreen(food: food)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search for foods...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _searchFoods('');
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              // Debounce search
              Future.delayed(const Duration(milliseconds: 500), () {
                if (_searchController.text == value) {
                  _searchFoods(value);
                }
              });
            },
          ),
          const SizedBox(height: 16),
          if (_isSearching)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_searchError.isNotEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Search Error',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _searchError,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _searchFoods(_searchController.text),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
            const Expanded(
              child: Center(
                child: Text('No foods found. Try a different search term.'),
              ),
            )
          else if (_searchResults.isEmpty)
            const Expanded(
              child: Center(child: Text('Start typing to search for foods...')),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final food = _searchResults[index];
                  return Card(
                    child: ListTile(
                      title: Text(
                        food.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (food.brandName != null)
                            Text('Brand: ${food.brandName}'),
                          Text(
                            '${food.getCalories().toStringAsFixed(0)} cal/100g',
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => _selectFood(food),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _BarcodeScanTab extends StatefulWidget {
  final FoodDatabaseService foodService;

  const _BarcodeScanTab({required this.foodService});

  @override
  State<_BarcodeScanTab> createState() => _BarcodeScanTabState();
}

class _BarcodeScanTabState extends State<_BarcodeScanTab> {
  MobileScannerController? _scannerController;
  bool _isScanning = false;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      setState(() => _hasPermission = true);
    } else if (status.isDenied) {
      final result = await Permission.camera.request();
      setState(() => _hasPermission = result.isGranted);
    } else if (status.isPermanentlyDenied) {
      // Show dialog to open app settings
      if (mounted) {
        _showPermissionDeniedDialog();
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text(
          'Camera access has been permanently denied. Please enable it in Settings to use barcode scanning.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _onBarcodeDetected(BarcodeCapture barcodeCapture) async {
    if (_isScanning) return;

    final barcode = barcodeCapture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    setState(() => _isScanning = true);

    try {
      final food = await widget.foodService.getFoodByUpc(barcode!.rawValue!);
      if (food != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => _FoodDetailsScreen(food: food),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Food not found for this barcode. Try manual search.',
            ),
          ),
        );
        setState(() => _isScanning = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isScanning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 64),
            const SizedBox(height: 16),
            const Text('Camera permission required for barcode scanning'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _checkPermissions,
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: _onBarcodeDetected,
        ),
        Positioned(
          top: 50,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Point camera at barcode to scan',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        if (_isScanning)
          Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

class _ManualEntryTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ManualEntryTab> createState() => _ManualEntryTabState();
}

class _ManualEntryTabState extends ConsumerState<_ManualEntryTab> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  String _selectedMealType = 'Breakfast';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;

  final List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  @override
  void dispose() {
    _descriptionController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _logMeal() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      User? user = ref.read(firebaseAuthProvider).currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No user logged in')));
        setState(() => _isLoading = false);
        return;
      }

      final mealTimestamp = Timestamp.fromDate(
        DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        ),
      );

      final quantity = double.tryParse(_quantityController.text) ?? 1.0;

      Map<String, dynamic> mealData = {
        'userId': user.uid,
        'foodName': _descriptionController.text.trim(),
        'calories': ((int.tryParse(_caloriesController.text) ?? 0) * quantity)
            .round(),
        'proteinGrams':
            ((double.tryParse(_proteinController.text) ?? 0.0) * quantity),
        'carbsGrams':
            ((double.tryParse(_carbsController.text) ?? 0.0) * quantity),
        'fatGrams': ((double.tryParse(_fatController.text) ?? 0.0) * quantity),
        'quantity': quantity,
        'servingUnit': 'serving',
        'mealType': _selectedMealType,
        'timestamp': mealTimestamp,
        'source': 'manual',
        'createdAt': FieldValue.serverTimestamp(),
      };

      try {
        await ref
            .read(firebaseFirestoreProvider)
            .collection('users')
            .doc(user.uid)
            .collection('loggedMeals')
            .add(mealData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Meal logged successfully!')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to log meal: $e')));
        }
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Food Description',
                hintText: 'e.g., Chicken breast, cooked',
                prefixIcon: const Icon(Icons.restaurant_menu),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a food description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(value) == null ||
                          double.parse(value) <= 0) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedMealType,
                    decoration: InputDecoration(
                      labelText: 'Meal Type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    items: _mealTypes.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedMealType = newValue;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Nutritional Information (per serving)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _caloriesController,
                    decoration: InputDecoration(
                      labelText: 'Calories',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _proteinController,
                    decoration: InputDecoration(
                      labelText: 'Protein (g)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (double.tryParse(value) == null) {
                          return 'Invalid';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _carbsController,
                    decoration: InputDecoration(
                      labelText: 'Carbs (g)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (double.tryParse(value) == null) {
                          return 'Invalid';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _fatController,
                    decoration: InputDecoration(
                      labelText: 'Fat (g)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (double.tryParse(value) == null) {
                          return 'Invalid';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text(
                        _selectedDate.toLocal().toString().split(' ')[0],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Time',
                        prefixIcon: const Icon(Icons.access_time),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text(_selectedTime.format(context)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _logMeal,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : Text(
                      'Log Meal',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodDetailsScreen extends ConsumerStatefulWidget {
  final FoodItem food;

  const _FoodDetailsScreen({required this.food});

  @override
  ConsumerState<_FoodDetailsScreen> createState() => _FoodDetailsScreenState();
}

class _FoodDetailsScreenState extends ConsumerState<_FoodDetailsScreen> {
  final _quantityController = TextEditingController(text: '1');
  final FoodDatabaseService _foodService = FoodDatabaseService();

  String _selectedMealType = 'Breakfast';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  late ServingSize _selectedServing;
  late List<ServingSize> _servingSizes;
  bool _isLogging = false;

  final List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  @override
  void initState() {
    super.initState();
    // Initialize serving sizes and set default
    _servingSizes = _foodService.getCommonServingSizes();
    _selectedServing = _servingSizes.first;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  double get _totalCalories {
    final quantity = double.tryParse(_quantityController.text) ?? 1.0;
    final caloriesPer100g = widget.food.getCalories();
    return (caloriesPer100g * _selectedServing.gramWeight / 100.0 * quantity);
  }

  double get _totalProtein {
    final quantity = double.tryParse(_quantityController.text) ?? 1.0;
    final proteinPer100g = widget.food.getProtein();
    return (proteinPer100g * _selectedServing.gramWeight / 100.0 * quantity);
  }

  double get _totalCarbs {
    final quantity = double.tryParse(_quantityController.text) ?? 1.0;
    final carbsPer100g = widget.food.getCarbohydrates();
    return (carbsPer100g * _selectedServing.gramWeight / 100.0 * quantity);
  }

  double get _totalFat {
    final quantity = double.tryParse(_quantityController.text) ?? 1.0;
    final fatPer100g = widget.food.getFat();
    return (fatPer100g * _selectedServing.gramWeight / 100.0 * quantity);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _logFood() async {
    setState(() => _isLogging = true);

    User? user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No user logged in')));
      setState(() => _isLogging = false);
      return;
    }

    final mealTimestamp = Timestamp.fromDate(
      DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      ),
    );

    final quantity = double.tryParse(_quantityController.text) ?? 1.0;

    Map<String, dynamic> mealData = {
      'userId': user.uid,
      'foodName': widget.food.name,
      'externalFoodId': widget.food.id,
      'calories': _totalCalories.round(),
      'proteinGrams': _totalProtein,
      'carbsGrams': _totalCarbs,
      'fatGrams': _totalFat,
      'quantity': quantity,
      'servingUnit': _selectedServing.description,
      'servingGramWeight': _selectedServing.gramWeight,
      'mealType': _selectedMealType,
      'timestamp': mealTimestamp,
      'source': 'food_database',
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      await ref
          .read(firebaseFirestoreProvider)
          .collection('users')
          .doc(user.uid)
          .collection('loggedMeals')
          .add(mealData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Food logged successfully!')),
        );
        // Navigate back to dashboard
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to log food: $e')));
      }
    }
    setState(() => _isLogging = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Food Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView(
                children: [
                  Text(
                    widget.food.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (widget.food.brandName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Brand: ${widget.food.brandName}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _quantityController,
                          decoration: InputDecoration(
                            labelText: 'Quantity',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<ServingSize>(
                          value: _selectedServing,
                          decoration: InputDecoration(
                            labelText: 'Serving Size',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          items: _servingSizes.map((ServingSize serving) {
                            return DropdownMenuItem<ServingSize>(
                              value: serving,
                              child: Text(serving.description),
                            );
                          }).toList(),
                          onChanged: (ServingSize? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedServing = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedMealType,
                    decoration: InputDecoration(
                      labelText: 'Meal Type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    items: _mealTypes.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedMealType = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Date',
                              prefixIcon: const Icon(Icons.calendar_today),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: Text(
                              _selectedDate.toLocal().toString().split(' ')[0],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectTime(context),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Time',
                              prefixIcon: const Icon(Icons.access_time),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: Text(_selectedTime.format(context)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nutritional Information',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        _buildNutrientRow(
                          'Calories',
                          '${_totalCalories.toStringAsFixed(0)} kcal',
                        ),
                        _buildNutrientRow(
                          'Protein',
                          '${_totalProtein.toStringAsFixed(1)} g',
                        ),
                        _buildNutrientRow(
                          'Carbohydrates',
                          '${_totalCarbs.toStringAsFixed(1)} g',
                        ),
                        _buildNutrientRow(
                          'Fat',
                          '${_totalFat.toStringAsFixed(1)} g',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLogging ? null : _logFood,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLogging
                    ? const CircularProgressIndicator()
                    : Text(
                        'Log Food',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
