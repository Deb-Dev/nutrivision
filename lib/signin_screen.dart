import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // Removed
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Added
import 'package:nutrivision/core/providers/firebase_providers.dart'; // Added
import 'package:firebase_auth/firebase_auth.dart'; // Re-added for FirebaseAuthException and UserCredential
import 'package:nutrivision/signup_screen.dart'; // For navigation
import 'package:nutrivision/core/navigation/main_tab_navigator.dart'; // Updated to use tab navigator
import 'package:nutrivision/forgot_password_screen.dart'; // Import ForgotPasswordScreen
import 'package:nutrivision/l10n/app_localizations.dart'; // Add this line

// Placeholder for ProfileSetupScreen - replace with actual import later
// import 'package:nutrivision/profile_setup_screen.dart';

class SignInScreen extends ConsumerStatefulWidget {
  // Changed to ConsumerStatefulWidget
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState(); // Changed to ConsumerState
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  // Changed to ConsumerState
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true; // To toggle password visibility

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final l10n = AppLocalizations.of(context)!; // Get l10n instance
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        UserCredential userCredential = await ref
            .read(firebaseAuthProvider) // Changed
            .signInWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );
        // User signed in successfully
        print('User signed in: ${userCredential.user?.uid}');

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainTabNavigator()),
            (Route<dynamic> route) => false,
          );
        }
      } on FirebaseAuthException catch (e) {
        String message;
        if (e.code == 'user-not-found' || e.code == 'invalid-email') {
          message = l10n.userNotFound; // Localized
        } else if (e.code == 'wrong-password' ||
            e.code == 'invalid-credential' ||
            e.code == 'INVALID_LOGIN_CREDENTIALS') {
          message = l10n.wrongPassword; // Localized
        } else {
          message = l10n.errorOccurred; // Localized generic error
        }
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
        print('Firebase Auth Exception: ${e.message} (Code: ${e.code})');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.errorOccurred), // Localized generic error
            ),
          );
        }
        print('Error: $e');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Get l10n instance

    return Scaffold(
      appBar: AppBar(title: Text(l10n.signInTitle)), // Localized
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  l10n.welcomeMessage(''),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.createAccountToStart, // Assuming this is generic enough, or add a new key for sign in context
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: l10n.emailHint, // Localized
                    hintText: l10n.emailExample, // Localized
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.pleaseEnterEmail; // Localized
                    }
                    if (!value.contains('@')) {
                      return l10n.invalidEmail; // Localized
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: l10n.passwordHint, // Localized
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.pleaseEnterPassword; // Localized
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ForgotPasswordScreen(),
                              ),
                            );
                          },
                    child: Text(l10n.forgotPasswordButton), // Localized
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    textStyle: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  onPressed: _isLoading ? null : _signIn,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n.signInButton), // Localized
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignUpScreen(),
                            ),
                          );
                        },
                  child: Text(l10n.dontHaveAccount), // Localized
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
