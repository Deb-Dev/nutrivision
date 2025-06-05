import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrivision/features/home/presentation/screens/home_screen.dart';
import 'package:nutrivision/features/advanced_meal_mgmt/presentation/screens/nutritional_goals_screen.dart';
import 'package:nutrivision/features/advanced_meal_mgmt/presentation/screens/nutrition_analytics_screen.dart';
import 'package:nutrivision/l10n/app_localizations.dart';
import 'package:nutrivision/features/log_meal/presentation/screens/log_meal_hub_screen.dart';
import 'package:nutrivision/features/profile/presentation/screens/profile_screen.dart';
import 'package:nutrivision/core/navigation/tab_provider.dart';

/// Main tab navigator for the app
/// Provides bottom navigation between the main sections of the app
class MainTabNavigator extends ConsumerStatefulWidget {
  const MainTabNavigator({super.key});

  @override
  ConsumerState<MainTabNavigator> createState() => _MainTabNavigatorState();
}

class _MainTabNavigatorState extends ConsumerState<MainTabNavigator> {
  // List of the screens for each tab
  late final List<Widget> _pages;
  
  @override
  void initState() {
    super.initState();
    _pages = [
      const HomeScreen(),       // Home tab with modern card UI
      const LogMealHubScreen(), // Log tab
      const NutritionAnalyticsScreen(), // Stats tab
      const NutritionalGoalsScreen(), // Goals tab
      const ProfileScreen(), // Profile tab
    ];
  }
  
  void _onTabTapped(int index) {
    ref.read(activeTabProvider.notifier).state = index;
  }
  
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentIndex = ref.watch(activeTabProvider);
    
    return Scaffold(
      body: _pages[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: _onTabTapped,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        elevation: 0,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.homeTab ?? 'Home',
          ),
          NavigationDestination(
            icon: const Icon(Icons.add_box_outlined),
            selectedIcon: const Icon(Icons.add_box),
            label: l10n.logTab ?? 'Log',
          ),
          NavigationDestination(
            icon: const Icon(Icons.insert_chart_outlined),
            selectedIcon: const Icon(Icons.insert_chart),
            label: l10n.statsTab ?? 'Stats',
          ),
          NavigationDestination(
            icon: const Icon(Icons.track_changes_outlined),
            selectedIcon: const Icon(Icons.track_changes),
            label: l10n.goalsTab ?? 'Goals',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l10n.profileTab ?? 'Profile',
          ),
        ],
      ),
    );
  }
}
