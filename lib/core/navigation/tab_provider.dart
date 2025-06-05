import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the currently active tab index
final activeTabProvider = StateProvider<int>((ref) => 0);

/// Enum for the main app tabs
enum MainTab {
  home,
  log,
  stats,
  goals,
  profile,
}

/// Extension to get the index from the MainTab enum
extension MainTabExtension on MainTab {
  int get index {
    switch (this) {
      case MainTab.home:
        return 0;
      case MainTab.log:
        return 1;
      case MainTab.stats:
        return 2;
      case MainTab.goals:
        return 3;
      case MainTab.profile:
        return 4;
    }
  }
}

/// Methods to navigate to specific tabs
void navigateToTab(WidgetRef ref, MainTab tab) {
  ref.read(activeTabProvider.notifier).state = tab.index;
}
