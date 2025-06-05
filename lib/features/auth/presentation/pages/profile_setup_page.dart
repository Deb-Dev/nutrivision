import 'package:flutter/material.dart';
import 'package:nutrivision/profile_setup_screen.dart';

/// Modern profile setup page that wraps the existing screen
class ProfileSetupPage extends StatelessWidget {
  const ProfileSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    // For now, use the existing profile setup screen
    // This will be refactored to use Riverpod in the next phase
    return const ProfileSetupScreen();
  }
}
