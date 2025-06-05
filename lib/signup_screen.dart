import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // Removed
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Added
import 'package:nutrivision/core/providers/firebase_providers.dart'; // Added
import 'package:firebase_auth/firebase_auth.dart'; // Re-added for FirebaseAuthException
import 'package:nutrivision/signin_screen.dart'; // Import SignInScreen
import 'package:nutrivision/profile_setup_screen.dart'; // Import ProfileSetupScreen
import 'package:nutrivision/l10n/app_localizations.dart'; // Add this line

class SignUpScreen extends ConsumerStatefulWidget {
  // Changed to ConsumerStatefulWidget
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState(); // Changed to ConsumerState
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  // Changed to ConsumerState
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String _passwordStrength = ""; // For password strength feedback

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength(String value) {
    setState(() {
      final l10n = AppLocalizations.of(context)!;
      if (value.isEmpty) {
        _passwordStrength = "";
      } else if (value.length < 8) {
        _passwordStrength = l10n.passwordTooShort;
      } else if (!value.contains(RegExp(r'[A-Z]'))) {
        _passwordStrength = l10n.needsUppercaseLetter;
      } else if (!value.contains(RegExp(r'[a-z]'))) {
        _passwordStrength = l10n.needsLowercaseLetter;
      } else if (!value.contains(RegExp(r'[0-9]'))) {
        _passwordStrength = l10n.needsNumber;
      } else if (!value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
        _passwordStrength = l10n.needsSpecialCharacter;
      } else {
        _passwordStrength = l10n.strongPassword;
      }
    });
  }

  Future<void> _signUp() async {
    final l10n = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      if (_passwordStrength != l10n.strongPassword) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.chooseStrongerPassword)));
        return;
      }
      setState(() {
        _isLoading = true;
      });
      try {
        // UserCredential userCredential = // This variable is unused, so it's commented out.
        await ref
            .read(firebaseAuthProvider)
            .createUserWithEmailAndPassword(
              // Changed
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );
        // User created successfully
        // print('User created: ${userCredential.user?.uid}'); // Also commented out as userCredential is not used

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
          );
        }
      } on FirebaseAuthException catch (e) {
        String message;
        if (e.code == 'weak-password') {
          message = l10n.weakPassword;
        } else if (e.code == 'email-already-in-use') {
          message = l10n.emailAlreadyInUse;
        } else {
          message = l10n.errorOccurred;
        }
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
        // print('Firebase Auth Exception: ${e.message}'); // Consider logging this to a service
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.errorOccurred)));
        }
        // print('Error: $e'); // Consider logging this to a service
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.signUpTitle)),
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
                  l10n.welcomeToNutrivision, // Changed from appTitle
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.createAccountToStart, // Changed from hardcoded string
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: l10n.emailHint,
                    hintText:
                        l10n.emailExample, // Changed from hardcoded string
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n
                          .pleaseEnterEmail; // Changed from hardcoded string
                    }
                    if (!value.contains('@')) {
                      return l10n.invalidEmail;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: l10n.passwordHint,
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    helperText: _passwordStrength.isNotEmpty
                        ? _passwordStrength
                        : null,
                    helperStyle: TextStyle(
                      color: _passwordStrength == l10n.strongPassword
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  obscureText: true,
                  onChanged: _checkPasswordStrength,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n
                          .pleaseEnterPassword; // Changed from hardcoded string
                    }
                    if (value.length < 8) {
                      return l10n.passwordTooShort; // Changed from weakPassword
                    }
                    if (_passwordStrength != l10n.strongPassword &&
                        _passwordStrength.isNotEmpty) {
                      // return _passwordStrength; // This shows the specific criteria not met
                      return l10n.passwordCriteriaNotMet; // Generic message
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: l10n.confirmPasswordHint,
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n
                          .pleaseConfirmPassword; // Changed from hardcoded string
                    }
                    if (value != _passwordController.text) {
                      return l10n.passwordsDoNotMatch;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    textStyle: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  onPressed: _isLoading
                      ? null
                      : _signUp, // Disable button when loading
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n.signUpButton), // Localized
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          // Disable when loading
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignInScreen(),
                            ),
                          );
                        },
                  child: Text(l10n.alreadyHaveAccount), // Localized
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
