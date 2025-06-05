import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrivision/core/providers/firebase_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutrivision/l10n/app_localizations.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _feedbackMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.forgotPasswordTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                AppLocalizations.of(context)!.forgotPasswordPrompt,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.emailHint,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.pleaseEnterEmail;
                  }
                  if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                    return AppLocalizations.of(context)!.invalidEmail;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _sendResetEmail,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                      ),
                      child: Text(AppLocalizations.of(context)!.sendResetLinkButton, style: const TextStyle(fontSize: 18)),
                    ),
              if (_feedbackMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Text(
                    _feedbackMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _feedbackMessage!.startsWith(AppLocalizations.of(context)!.passwordResetEmailSentFeedback)
                           ? Colors.green
                           : Theme.of(context).colorScheme.error,
                      fontSize: 15,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
                TextButton(
                    onPressed: () {
                        Navigator.pop(context); // Go back to Sign In screen
                    },
                    child: Text(AppLocalizations.of(context)!.backToSignIn),
                )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendResetEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _feedbackMessage = null;
      });
      try {
        await ref.read(firebaseAuthProvider).sendPasswordResetEmail(email: _emailController.text.trim());
        setState(() {
          _feedbackMessage = AppLocalizations.of(context)!.passwordResetEmailSentFeedback;
          _isLoading = false;
        });
      } on FirebaseAuthException catch (e) {
        String errorMessage = AppLocalizations.of(context)!.errorOccurred;
        if (e.code == 'user-not-found') {
          errorMessage = AppLocalizations.of(context)!.userNotFound;
        } else if (e.code == 'invalid-email') {
          errorMessage = AppLocalizations.of(context)!.invalidEmail;
        }
        print('Forgot Password Error: ${e.toString()}');
        setState(() {
          _feedbackMessage = errorMessage;
          _isLoading = false;
        });
      } catch (e) {
        print('Forgot Password Error: ${e.toString()}');
        setState(() {
          _feedbackMessage = AppLocalizations.of(context)!.errorOccurred;
          _isLoading = false;
        });
      }
    }
  }
}
