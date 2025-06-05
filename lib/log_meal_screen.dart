import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrivision/core/providers/firebase_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutrivision/l10n/app_localizations.dart';

class LogMealScreen extends ConsumerStatefulWidget {
  const LogMealScreen({super.key});

  @override
  ConsumerState<LogMealScreen> createState() => _LogMealScreenState();
}

class _LogMealScreenState extends ConsumerState<LogMealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  bool _isLoading = false; // For loading state

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    _descriptionController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
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
      _formKey.currentState!.save();
      setState(() => _isLoading = true); // Start loading
      final l10n = AppLocalizations.of(context)!;

      User? user = ref.read(firebaseAuthProvider).currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.errorNoUserLoggedIn)), // Updated
          );
        }
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

      Map<String, dynamic> mealData = {
        'userId': user.uid,
        'description': _descriptionController.text.trim(),
        'calories': int.tryParse(_caloriesController.text) ?? 0,
        'proteinGrams': double.tryParse(_proteinController.text) ?? 0.0,
        'carbsGrams': double.tryParse(_carbsController.text) ?? 0.0,
        'fatGrams': double.tryParse(_fatController.text) ?? 0.0,
        'timestamp': mealTimestamp,
        'createdAt': FieldValue.serverTimestamp(), // For ordering/auditing
      };

      try {
        await ref.read(firebaseFirestoreProvider)
            .collection('users')
            .doc(user.uid)
            .collection('loggedMeals')
            .add(mealData);

        // Optionally, update daily summary in the user's main document for quick dashboard reads.
        // This would involve reading the current daily summary, adding to it, and writing back.
        // For now, we'll keep it simple and calculate totals on the dashboard by querying loggedMeals.

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.mealLoggedSuccessfully)), // Updated
          );
          Navigator.pop(context); // Go back to the dashboard
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.failedToLogMeal(e.toString())))); // Updated
        }
        print('Error logging meal: $e');
      }
      setState(() => _isLoading = false); // Stop loading
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.logMealTitle), // Updated
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              Text(
                l10n.logMealHeadline, // Updated
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: l10n.mealDescriptionLabel, // Updated
                  hintText: l10n.mealDescriptionHint, // Updated
                  prefixIcon: const Icon(Icons.restaurant_menu_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.pleaseEnterMealDescription; // Updated
                  }
                  if (value.trim().length < 3) {
                    return l10n.descriptionTooShort; // Updated
                  }
                  if (value.length > 150) {
                    return l10n.descriptionTooLong('150'); // Updated
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Date and Time Pickers - styled for consistency
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: l10n.dateLabel, // Updated
                          prefixIcon: const Icon(Icons.calendar_today_outlined),
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
                          labelText: l10n.timeLabel, // Updated
                          prefixIcon: const Icon(Icons.access_time_outlined),
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
              const SizedBox(height: 20),
              TextFormField(
                controller: _caloriesController,
                decoration: InputDecoration(
                  labelText: l10n.caloriesLabelKcal, // Updated
                  hintText: l10n.caloriesHint, // Updated
                  prefixIcon: const Icon(Icons.local_fire_department_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.pleaseEnterCalories; // Updated
                  }
                  final calories = int.tryParse(value);
                  if (calories == null || calories < 0) {
                    return l10n.pleaseEnterValidPositiveNumber; // Updated
                  }
                  if (calories > 5000) {
                    return l10n.caloriesTooHighSingleMeal; // Updated
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Macronutrients in a Row for better layout
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _proteinController,
                      decoration: InputDecoration(
                        labelText: l10n.proteinLabelG, // Updated
                        hintText: l10n.proteinHint, // Updated
                        prefixIcon: const Icon(
                          Icons.fitness_center,
                        ), // Placeholder, consider specific icon
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.enterProteinOrZero; // Updated
                        }
                        final protein = double.tryParse(value);
                        if (protein == null || protein < 0) {
                          return l10n.invalidAmount; // Updated
                        }
                        if (protein > 200) {
                          return l10n.proteinTooHigh; // Updated
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _carbsController,
                      decoration: InputDecoration(
                        labelText: l10n.carbsLabelG, // Updated
                        hintText: l10n.carbsHint, // Updated
                        prefixIcon: const Icon(
                          Icons.bakery_dining_outlined,
                        ), // Placeholder
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.enterCarbsOrZero; // Updated
                        }
                        final carbs = double.tryParse(value);
                        if (carbs == null || carbs < 0) return l10n.invalidAmount; // Updated
                        if (carbs > 300) {
                          return l10n.carbsTooHigh; // Updated
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
                        labelText: l10n.fatLabelG, // Updated
                        hintText: l10n.fatHint, // Updated
                        prefixIcon: const Icon(
                          Icons.oil_barrel_outlined,
                        ), // Placeholder
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.enterFatOrZero; // Updated
                        }
                        final fat = double.tryParse(value);
                        if (fat == null || fat < 0) return l10n.invalidAmount; // Updated
                        if (fat > 200) {
                          return l10n.fatTooHigh; // Updated
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onPressed: _isLoading ? null : _logMeal,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      )
                    : Text(l10n.logMealButton), // Updated
              ),
              const SizedBox(height: 24), // Spacing at the bottom
            ],
          ),
        ),
      ),
    );
  }
}
