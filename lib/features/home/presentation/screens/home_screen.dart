import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrivision/core/providers/firebase_providers.dart';
import 'package:nutrivision/features/ai_meal_logging/presentation/pages/ai_photo_meal_page.dart';
import 'package:nutrivision/enhanced_log_meal_screen.dart';
import 'package:nutrivision/features/advanced_meal_mgmt/presentation/screens/meal_history_screen.dart';
import 'package:nutrivision/features/advanced_meal_mgmt/presentation/screens/favorite_meals_screen.dart';
import 'package:nutrivision/features/advanced_meal_mgmt/presentation/providers/meal_history_provider.dart';
import 'package:nutrivision/core/models/meal_models.dart';
import 'package:nutrivision/features/smart_meal_planning/presentation/screens/meal_planning_screen.dart';
import 'package:nutrivision/l10n/app_localizations.dart';
import 'package:nutrivision/features/advanced_meal_mgmt/utils/meal_name_generator.dart';
import 'package:nutrivision/features/home/presentation/widgets/interactive_summary_section.dart';
import 'package:intl/intl.dart';

/// Modern Home Dashboard Screen with card-based UI
/// Follows Material 3 design principles
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  List<Map<String, dynamic>> _recentMeals = [];

  // Consumed nutrients for the current day
  int _consumedCalories = 0;
  double _consumedProtein = 0.0;
  double _consumedCarbs = 0.0;
  double _consumedFat = 0.0;

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
      // Load user profile data
      DocumentSnapshot userDoc = await ref
          .read(firebaseFirestoreProvider)
          .collection('users')
          .doc(_user!.uid)
          .get();

      if (mounted && userDoc.exists) {
        setState(() {
          _userData = userDoc.data() as Map<String, dynamic>?;
        });
      }

      // Calculate today's nutrition
      await _calculateTodaysNutrition();

      // Load recent meals
      await _loadRecentMeals();

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
      debugPrint("Error loading dashboard data: $e");
    }
  }

  Future<void> _calculateTodaysNutrition() async {
    if (_user == null || !mounted) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    // Fetch regular logged meals
    QuerySnapshot mealSnapshot = await ref
        .read(firebaseFirestoreProvider)
        .collection('users')
        .doc(_user!.uid)
        .collection('loggedMeals')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
        .where('timestamp', isLessThan: Timestamp.fromDate(tomorrow))
        .get();

    // Fetch AI meal logs
    QuerySnapshot aiMealSnapshot = await ref
        .read(firebaseFirestoreProvider)
        .collection('users')
        .doc(_user!.uid)
        .collection('ai_meal_logs')
        .where('loggedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
        .where('loggedAt', isLessThan: Timestamp.fromDate(tomorrow))
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
        _consumedCalories = calories;
        _consumedProtein = protein;
        _consumedCarbs = carbs;
        _consumedFat = fat;
      });
    }
  }

  Future<void> _loadRecentMeals() async {
    if (_user == null || !mounted) return;

    final now = DateTime.now();
    final threeDaysAgo = now.subtract(const Duration(days: 3));

    try {
      // Get recent regular meals
      QuerySnapshot mealSnapshot = await ref
          .read(firebaseFirestoreProvider)
          .collection('users')
          .doc(_user!.uid)
          .collection('loggedMeals')
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(threeDaysAgo),
          )
          .orderBy('timestamp', descending: true)
          .limit(3)
          .get();

      // Get recent AI meals
      QuerySnapshot aiMealSnapshot = await ref
          .read(firebaseFirestoreProvider)
          .collection('users')
          .doc(_user!.uid)
          .collection('ai_meal_logs')
          .where(
            'loggedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(threeDaysAgo),
          )
          .orderBy('loggedAt', descending: true)
          .limit(3)
          .get();

      List<Map<String, dynamic>> recentMeals = [];

      // Process regular meals
      for (var doc in mealSnapshot.docs) {
        Map<String, dynamic> mealData = doc.data() as Map<String, dynamic>;

        // Generate meaningful meal name from food items
        String mealName = MealNameGenerator.generateFromRegularMealData(
          mealData,
        );

        recentMeals.add({
          'id': doc.id,
          'name': mealName,
          'timestamp': (mealData['timestamp'] as Timestamp).toDate(),
          'mealType': mealData['mealType'] ?? 'Meal',
          'calories': mealData['calories'] ?? 0,
          'isAIMeal': false,
          'foodCount': mealData['foods']?.length ?? 0,
        });
      }

      // Process AI meals
      for (var doc in aiMealSnapshot.docs) {
        Map<String, dynamic> aiMealData = doc.data() as Map<String, dynamic>;

        // Generate meaningful meal name from confirmed items
        String mealName = MealNameGenerator.generateFromAIMealData(aiMealData);

        recentMeals.add({
          'id': doc.id,
          'name': mealName,
          'timestamp': (aiMealData['loggedAt'] as Timestamp).toDate(),
          'mealType': aiMealData['mealType'] ?? 'Meal',
          'calories': aiMealData['totalNutrition']?['calories'] ?? 0,
          'isAIMeal': true,
          'foodCount': aiMealData['confirmedItems']?.length ?? 0,
        });
      }

      // Sort combined list by timestamp
      recentMeals.sort(
        (a, b) =>
            (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime),
      );

      // Take only the most recent 3
      if (recentMeals.length > 3) {
        recentMeals = recentMeals.sublist(0, 3);
      }

      if (mounted) {
        setState(() {
          _recentMeals = recentMeals;
        });
      }
    } catch (e) {
      debugPrint("Error loading recent meals: $e");
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    final l10n = AppLocalizations.of(context)!;

    if (hour < 12) {
      return l10n.goodMorning;
    } else if (hour < 17) {
      return l10n.goodAfternoon;
    } else {
      return l10n.goodEvening;
    }
  }

  String _formatMealTime(DateTime timestamp) {
    return DateFormat.jm().format(timestamp);
  }

  Color _getMealTypeColor(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.green;
      case 'dinner':
        return Colors.deepPurple;
      case 'snack':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final userName =
        _userData?['name'] ??
        _user?.displayName ??
        _user?.email?.split('@').first ??
        l10n.userGeneric;
    'User';

    final targetCalories =
        (_userData?['targetCalories'] as num?)?.toInt() ?? 2000;
    final targetProtein =
        (_userData?['targetProteinGrams'] as num?)?.toDouble() ?? 50.0;
    final targetCarbs =
        (_userData?['targetCarbsGrams'] as num?)?.toDouble() ?? 250.0;
    final targetFat =
        (_userData?['targetFatGrams'] as num?)?.toDouble() ?? 70.0;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              title: Text(l10n.homeTab),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: l10n.refreshData,
                  onPressed: _loadDashboardData,
                ),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Greeting Card
                  Card(
                    elevation: 0,
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_getGreeting()},',
                                style: theme.textTheme.titleMedium,
                              ),
                              Text(
                                userName,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          CircleAvatar(
                            backgroundColor: theme.colorScheme.primary
                                .withOpacity(0.1),
                            child: Icon(
                              Icons.person,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Today's Progress
                  Text(
                    l10n.todaysSummary,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Calories Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.calories,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '$_consumedCalories / $targetCalories ${l10n.kcalUnit}',
                                style: theme.textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: targetCalories > 0
                                ? (_consumedCalories / targetCalories).clamp(
                                    0.0,
                                    1.0,
                                  )
                                : 0.0,
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(5),
                            backgroundColor: theme.colorScheme.primary
                                .withOpacity(0.2),
                          ),
                          const SizedBox(height: 16),

                          // Interactive Nutrition Summary
                          InteractiveSummarySection(
                            consumedProtein: _consumedProtein,
                            consumedCarbs: _consumedCarbs,
                            consumedFat: _consumedFat,
                            targetProtein: targetProtein,
                            targetCarbs: targetCarbs,
                            targetFat: targetFat,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Secondary Actions
                  Text(
                    l10n.moreActions,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Secondary Actions Row (smaller, less prominent)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildQuickActionCard(
                          context,
                          icon: Icons.search,
                          title: l10n.searchFoods,
                          color: theme.colorScheme.secondary,
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const EnhancedLogMealScreen(),
                              ),
                            );
                            if (result == true && mounted) {
                              _loadDashboardData();
                            }
                          },
                        ),
                        _buildQuickActionCard(
                          context,
                          icon: Icons.favorite,
                          title: l10n.favorites,
                          color: theme.colorScheme.tertiary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const FavoriteMealsScreen(),
                              ),
                            );
                          },
                        ),
                        _buildQuickActionCard(
                          context,
                          icon: Icons.calendar_today,
                          title: 'Meal Planning',
                          color: theme.colorScheme.primary,
                          onTap: () {
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
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Recent Meals
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Meals',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // View All Button
                      TextButton.icon(
                        icon: const Icon(Icons.history, size: 16),
                        label: Text('View All'),
                        onPressed: () {
                          _navigateToMealHistory(context);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Recent Meals List
                  _recentMeals.isEmpty
                      ? Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                l10n.noRecentMeals,
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: _recentMeals.map((meal) {
                            return Card(
                              elevation: 1,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: theme.colorScheme.outline.withOpacity(
                                    0.1,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  _navigateToMealHistory(context);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Header row with meal name and time
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              meal['name'],
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface,
                                                    height: 1.2,
                                                  ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            _formatMealTime(meal['timestamp']),
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.6),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 12),

                                      // Chips row
                                      Row(
                                        children: [
                                          // Meal type chip
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getMealTypeColor(
                                                meal['mealType'],
                                              ).withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  meal['isAIMeal']
                                                      ? Icons.camera_alt
                                                      : Icons.restaurant,
                                                  size: 14,
                                                  color: _getMealTypeColor(
                                                    meal['mealType'],
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  meal['mealType'],
                                                  style: theme
                                                      .textTheme
                                                      .labelSmall
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            _getMealTypeColor(
                                                              meal['mealType'],
                                                            ),
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          const SizedBox(width: 8),

                                          // Calories chip
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.local_fire_department,
                                                  size: 14,
                                                  color: Colors.orange,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${meal['calories']} kcal',
                                                  style: theme
                                                      .textTheme
                                                      .labelSmall
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.orange,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          if (meal['foodCount'] > 0) ...[
                                            const SizedBox(width: 8),
                                            // Food count chip
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: theme
                                                    .colorScheme
                                                    .secondary
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.restaurant_menu,
                                                    size: 14,
                                                    color: theme
                                                        .colorScheme
                                                        .secondary,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${meal['foodCount']} ${meal['foodCount'] == 1 ? 'item' : 'items'}',
                                                    style: theme
                                                        .textTheme
                                                        .labelSmall
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: theme
                                                              .colorScheme
                                                              .secondary,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],

                                          const Spacer(),

                                          Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16,
                                            color: theme.colorScheme.onSurface
                                                .withOpacity(0.4),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                  // Add bottom padding to prevent overlap with FAB
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AIPhotoMealPage()),
          );
          if (result == true && mounted) {
            _loadDashboardData();
          }
        },
        icon: const Icon(Icons.camera_alt),
        label: Text(l10n.aiPhotoLog),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 8,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    // Use SizedBox to enforce consistent width for all cards
    return SizedBox(
      width: 105, // Fixed width to ensure three cards fit side by side
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 8.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToMealHistory(BuildContext context) async {
    final userId = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (userId == null) return;

    // Set initial filter to today
    await ref
        .read(mealHistoryProvider.notifier)
        .setInitialFilterAndLoad(
          userId,
          MealHistoryFilter(startDate: DateTime.now(), endDate: DateTime.now()),
        );

    if (mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MealHistoryScreen()),
      );
      if (result == true && mounted) {
        _loadDashboardData();
      }
    }
  }
}
