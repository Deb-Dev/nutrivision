import 'package:flutter/material.dart';
import 'package:nutrivision/signin_screen.dart';

/// Modern sign-in page that wraps the existing screen
class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    // For now, use the existing signin screen
    // This will be refactored to use Riverpod in the next phase
    return const SignInScreen();
  }
}
