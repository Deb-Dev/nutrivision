# Tab Bar Navigation Enhancement Plan

## Overview
This document outlines the implementation plan for transforming NutriVision's current navigation structure into a modern tab-based navigation system, which is part of Epic 4.5 (UI/UX Refinement).

## Current State
- Dashboard is the primary landing screen
- Navigation to other features is through cards, buttons, and menu items
- Advanced Meal Management has its own internal tab navigation
- No consistent global navigation pattern

## Target State
A modern, intuitive tab bar navigation system with 5 main tabs:

### 1. Home Tab
- Enhanced dashboard with daily summary
- Quick actions for most common tasks
- Personalized insights and recommendations
- Daily progress visualization

### 2. Log Tab
- Quick access to all logging methods
- AI photo meal logging (primary CTA)
- Manual meal logging
- Recent meals for quick re-logging
- Barcode scanner

### 3. Stats Tab 
- Nutrition analytics and trends
- Weekly and monthly reports
- Interactive charts and graphs
- Progress tracking against goals

### 4. Goals Tab
- Nutritional goal setting and tracking
- Daily/weekly target visualization
- Goal history and adjustments
- Achievement celebrations

### 5. Profile Tab
- User profile management
- Settings and preferences
- App configuration
- Integration with health apps
- Help and support

## Design Guidelines
- Use Material Design 3 components
- Implement consistent visual language
- Ensure accessibility standards are met
- Support dark/light mode
- Smooth animations for transitions

## Implementation Approach
1. Create a new root widget (MainTabNavigator)
2. Move existing screens into appropriate tabs
3. Implement shared state management across tabs
4. Add visual indicators for active tab
5. Support gesture navigation
6. Add tab-specific app bars

## Technical Implementation Details

### Tab Controller
```dart
class MainTabNavigator extends ConsumerStatefulWidget {
  @override
  ConsumerState<MainTabNavigator> createState() => _MainTabNavigatorState();
}

class _MainTabNavigatorState extends ConsumerState<MainTabNavigator> {
  int _currentIndex = 0;
  
  final List<Widget> _pages = [
    DashboardScreen(),
    LogMealHubScreen(),
    NutritionAnalyticsScreen(), 
    NutritionalGoalsScreen(),
    ProfileScreen(),
  ];
  
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabTapped,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_box_outlined),
            selectedIcon: Icon(Icons.add_box),
            label: 'Log',
          ),
          NavigationDestination(
            icon: Icon(Icons.insert_chart_outlined),
            selectedIcon: Icon(Icons.insert_chart),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.track_changes_outlined),
            selectedIcon: Icon(Icons.track_changes),
            label: 'Goals',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
```

## UI Design Reference
Modern fitness and nutrition apps use the following tab bar patterns:

### Tab Layout
```
┌─────────────────────────────────────────────────────────────┐
│                      App Content Area                        │
│                                                             │
│                                                             │
│                                                             │
│                                                             │
│                                                             │
│                                                             │
│                                                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
┌─────────┬─────────┬─────────┬─────────┬─────────┐
│         │         │         │         │         │
│  Home   │   Log   │  Stats  │  Goals  │ Profile │
│    •    │         │         │         │         │
└─────────┴─────────┴─────────┴─────────┴─────────┘
```

## Implementation Timeline
- Week 1: Create tab navigation infrastructure and move existing screens
- Week 2: Redesign dashboard/home tab for better UX
- Week 3: Polish transitions and implement visual consistency
- Week 4: Testing and refinement

## Success Criteria
- Intuitive user navigation with reduced learning curve
- Decreased number of taps to access key features
- Consistent visual language across all screens
- Improved user satisfaction and engagement metrics
- Support for future feature expansion
