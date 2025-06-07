import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrivision/core/providers/firebase_providers.dart';
import 'package:nutrivision/signin_screen.dart';
import 'package:nutrivision/enhanced_log_meal_screen.dart'; // Import Enhanced LogMealScreen
// import 'package:nutrivision/meal_history_screen.dart'; // Comment out old Import MealHistoryScreen
import 'package:nutrivision/features/advanced_meal_mgmt/presentation/screens/meal_history_screen.dart'
    as NewMealHistoryScreen; // Import new MealHistoryScreen
import 'package:nutrivision/features/advanced_meal_mgmt/presentation/providers/meal_history_provider.dart'; // Import for filter
import 'package:nutrivision/core/models/meal_models.dart'; // Import for MealHistoryFilter
import 'package:nutrivision/features/smart_meal_planning/presentation/navigation/smart_meal_planning_navigation.dart';
import 'package:nutrivision/features/ai_meal_logging/presentation/pages/ai_photo_meal_page.dart';
import 'package:nutrivision/features/advanced_meal_mgmt/presentation/screens/advanced_meal_management_screen.dart';
import 'package:nutrivision/features/advanced_meal_mgmt/presentation/screens/nutrition_analytics_screen.dart';
import 'package:nutrivision/features/advanced_meal_mgmt/presentation/screens/nutritional_goals_screen.dart';
import 'package:nutrivision/features/advanced_meal_mgmt/presentation/screens/favorite_meals_screen.dart';
import 'package:nutrivision/features/smart_meal_planning/presentation/screens/meal_planning_screen.dart';
import 'package:nutrivision/features/smart_meal_planning/presentation/screens/grocery_list_screen.dart';
import 'package:nutrivision/l10n/app_localizations.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  DateTime _selectedDisplayDate =
      DateTime.now(); // Date for which summary is displayed

  // Consumed nutrients for the _selectedDisplayDate
  int _displayedConsumedCalories = 0;
  double _displayedConsumedProtein = 0.0;
  double _displayedConsumedCarbs = 0.0;
  double _displayedConsumedFat = 0.0;

  @override
  void initState() {
    super.initState();
    _user = ref.read(firebaseAuthProvider).currentUser;
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    if (_user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      DocumentSnapshot userDoc = await ref
          .read(firebaseFirestoreProvider)
          .collection('users')
          .doc(_user!.uid)
          .get();

      if (mounted && userDoc.exists) {
        setState(() {
          _userData = userDoc.data() as Map<String, dynamic>?;
        });
      } else if (mounted) {
        print("User data not found!");
        // Optionally navigate to profile setup if data is missing
      }

      await _calculateConsumptionForDate(_selectedDisplayDate);

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error loading your data: $e")));
      }
      print("Error loading dashboard data: $e");
    }
  }

  Future<void> _calculateConsumptionForDate(DateTime date) async {
    if (_user == null || !mounted) return;

    DateTime startOfDay = DateTime(date.year, date.month, date.day);
    DateTime endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    // Fetch regular logged meals
    QuerySnapshot mealSnapshot = await ref
        .read(firebaseFirestoreProvider)
        .collection('users')
        .doc(_user!.uid)
        .collection('loggedMeals')
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    // Fetch AI meal logs
    QuerySnapshot aiMealSnapshot = await ref
        .read(firebaseFirestoreProvider)
        .collection('users')
        .doc(_user!.uid)
        .collection('ai_meal_logs')
        .where(
          'loggedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('loggedAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    int calories = 0;
    double protein = 0.0;
    double carbs = 0.0;
    double fat = 0.0;

    // Process regular logged meals
    for (var doc in mealSnapshot.docs) {
      Map<String, dynamic> mealData = doc.data() as Map<String, dynamic>;
      calories += (mealData['calories'] as num?)?.toInt() ?? 0;
      protein += (mealData['proteinGrams'] as num?)?.toDouble() ?? 0.0;
      carbs += (mealData['carbsGrams'] as num?)?.toDouble() ?? 0.0;
      fat += (mealData['fatGrams'] as num?)?.toDouble() ?? 0.0;
    }

    // Process AI meal logs
    for (var doc in aiMealSnapshot.docs) {
      Map<String, dynamic> aiMealData = doc.data() as Map<String, dynamic>;

      // Extract nutrition data from totalNutrition field
      if (aiMealData['totalNutrition'] != null) {
        Map<String, dynamic> totalNutrition =
            aiMealData['totalNutrition'] as Map<String, dynamic>;
        calories += (totalNutrition['calories'] as num?)?.toInt() ?? 0;
        protein += (totalNutrition['protein'] as num?)?.toDouble() ?? 0.0;
        carbs += (totalNutrition['carbs'] as num?)?.toDouble() ?? 0.0;
        fat += (totalNutrition['fat'] as num?)?.toDouble() ?? 0.0;
      }
    }

    if (mounted) {
      setState(() {
        _displayedConsumedCalories = calories;
        _displayedConsumedProtein = protein;
        _displayedConsumedCarbs = carbs;
        _displayedConsumedFat = fat;
      });
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await ref.read(firebaseAuthProvider).signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SignInScreen()),
      (Route<dynamic> route) => false,
    );
  }

  Widget _buildNutrientInfoRow(
    String label,
    dynamic consumed,
    dynamic target,
    String unit,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            '$consumed / ${target ?? 'N/A'} $unit',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboardTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refreshData, // Added
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.signOut,
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null || _userData == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.couldNotLoadUserData), // Added
                  ElevatedButton(
                    onPressed: _loadDashboardData,
                    child: Text(l10n.retryButton), // Added
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.welcomeBackMessage(
                      _userData?['name'] ?? _user?.email ?? l10n.userGeneric,
                    ), // Updated
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new),
                        tooltip: l10n.previousDay,
                        onPressed: () {
                          if (!mounted) return;
                          setState(() {
                            _selectedDisplayDate = _selectedDisplayDate
                                .subtract(const Duration(days: 1));
                          });
                          _calculateConsumptionForDate(_selectedDisplayDate);
                        },
                      ),
                      Text(
                        _isToday(_selectedDisplayDate)
                            ? l10n
                                  .todaysSummary // Added
                            : l10n.summaryForDate(
                                _selectedDisplayDate.toLocal().toString().split(
                                  ' ',
                                )[0],
                              ), // Updated
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios),
                        tooltip: l10n.nextDay,
                        onPressed: _isToday(_selectedDisplayDate)
                            ? null
                            : () {
                                if (!mounted) return;
                                setState(() {
                                  _selectedDisplayDate = _selectedDisplayDate
                                      .add(const Duration(days: 1));
                                });
                                _calculateConsumptionForDate(
                                  _selectedDisplayDate,
                                );
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildNutrientInfoRow(
                    l10n.calories,
                    _displayedConsumedCalories,
                    _userData!['targetCalories'],
                    l10n.kcalUnit, // Added
                    l10n,
                  ),
                  _buildNutrientInfoRow(
                    l10n.protein,
                    _displayedConsumedProtein.toStringAsFixed(1),
                    _userData!['targetProteinGrams'],
                    l10n.gramsUnit, // Added
                    l10n,
                  ),
                  _buildNutrientInfoRow(
                    l10n.carbs,
                    _displayedConsumedCarbs.toStringAsFixed(1),
                    _userData!['targetCarbsGrams'],
                    l10n.gramsUnit, // Added
                    l10n,
                  ),
                  _buildNutrientInfoRow(
                    l10n.fats, // Corrected from l10n.fat to l10n.fats
                    _displayedConsumedFat.toStringAsFixed(1),
                    _userData!['targetFatGrams'],
                    l10n.gramsUnit, // Added
                    l10n,
                  ),
                  const SizedBox(height: 32),
                  // AI-Powered Meal Logging - Primary CTA
                  Center(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          Icons.camera_alt,
                          size: 28,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Log Meal with AI Camera',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AIPhotoMealPage(),
                            ),
                          );
                          if (result == true && mounted) {
                            _loadDashboardData();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(l10n.logNewMealButton), // Added
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EnhancedLogMealScreen(),
                          ),
                        );
                        if (result == true && mounted) {
                          _loadDashboardData();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[100],
                        foregroundColor: Colors.grey[700],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Advanced Meal Management Section
                  Text(
                    'Advanced Meal Management',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // First row of advanced features
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          elevation: 2,
                          child: InkWell(
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const NutritionAnalyticsScreen(),
                                ),
                              );
                              if (result == true && mounted) {
                                _loadDashboardData();
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.analytics,
                                    size: 32,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Nutrition Analytics',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Card(
                          elevation: 2,
                          child: InkWell(
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const NutritionalGoalsScreen(),
                                ),
                              );
                              if (result == true && mounted) {
                                _loadDashboardData();
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.track_changes,
                                    size: 32,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Goals & Tracking',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Second row of advanced features
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          elevation: 2,
                          child: InkWell(
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const FavoriteMealsScreen(),
                                ),
                              );
                              if (result == true && mounted) {
                                _loadDashboardData();
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.favorite,
                                    size: 32,
                                    color: Colors.red[400],
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Favorite Meals',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Card(
                          elevation: 2,
                          child: InkWell(
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AdvancedMealManagementScreen(),
                                ),
                              );
                              if (result == true && mounted) {
                                _loadDashboardData();
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.manage_history,
                                    size: 32,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Meal Management',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Quick Actions Section
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: Consumer(
                              // Wrap with Consumer to access ref
                              builder: (context, ref, child) {
                                return OutlinedButton.icon(
                                  icon: const Icon(Icons.history),
                                  label: const Text('Meal History'),
                                  onPressed: () async {
                                    final userId = ref
                                        .read(firebaseAuthProvider)
                                        .currentUser
                                        ?.uid;
                                    if (userId == null) {
                                      return; // Or handle error
                                    }

                                    // Set the initial filter using the provider
                                    await ref
                                        .read(mealHistoryProvider.notifier)
                                        .setInitialFilterAndLoad(
                                          userId,
                                          MealHistoryFilter(
                                            startDate: _selectedDisplayDate,
                                            endDate: _selectedDisplayDate,
                                            // Keep other filter options as default or null if not needed initially
                                          ),
                                        );

                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const NewMealHistoryScreen.MealHistoryScreen(),
                                      ),
                                    );
                                    if (result == true && mounted) {
                                      _loadDashboardData();
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 12,
                                    ),
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.lightbulb_outline),
                              label: const Text('Meal Ideas'),
                              onPressed: () {
                                SmartMealPlanningNavigation.navigateToMealSuggestionsScreen(
                                  context,
                                  'lunch',
                                  date: DateTime.now(),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 12,
                                ),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 160,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.calendar_today),
                              label: const Text('Meal Planning'),
                              onPressed: () {
                                final userId = _user?.uid;
                                if (userId != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          MealPlanningScreen(userId: userId),
                                    ),
                                  );
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 12,
                                ),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 160,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.shopping_cart),
                              label: const Text('Grocery Lists'),
                              onPressed: () {
                                final userId = _user?.uid;
                                if (userId != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          GroceryListScreen(userId: userId),
                                    ),
                                  );
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 12,
                                ),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        // TODO: Implement navigation to Edit Profile/Preferences screen
                        // For now, show a placeholder message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.navigateToEditProfilePlaceholder,
                            ), // Added
                          ),
                        );
                      },
                      child: Text(l10n.editProfilePreferencesButton), // Added
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.lightbulb_outline),
                      label: Text('Meal Suggestions'), // Added
                      onPressed: () async {
                        SmartMealPlanningNavigation.navigateToMealSuggestionsScreen(
                          context,
                          'dinner',
                          date: DateTime.now(),
                          onSuggestionSelected: (result) {
                            if (result == true && mounted) {
                              _loadDashboardData();
                            }
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
