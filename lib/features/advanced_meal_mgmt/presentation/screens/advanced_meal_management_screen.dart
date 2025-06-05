import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'meal_history_screen.dart';
import 'nutritional_goals_screen.dart';
import 'nutrition_analytics_screen.dart';
import 'favorite_meals_screen.dart';

class AdvancedMealManagementScreen extends ConsumerStatefulWidget {
  const AdvancedMealManagementScreen({super.key});

  @override
  ConsumerState<AdvancedMealManagementScreen> createState() =>
      _AdvancedMealManagementScreenState();
}

class _AdvancedMealManagementScreenState
    extends ConsumerState<AdvancedMealManagementScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const MealHistoryScreen(),
    const NutritionalGoalsScreen(),
    const NutritionAnalyticsScreen(),
    const FavoriteMealsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes),
            label: 'Goals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
        ],
      ),
    );
  }
}
