import 'package:flutter/material.dart';
import 'package:nutrivision/dashboard_screen.dart';

/// Modern dashboard page that wraps the existing screen
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // For now, use the existing dashboard screen
    // This will be refactored to use Riverpod in the next phase
    return const DashboardScreen();
  }
}
