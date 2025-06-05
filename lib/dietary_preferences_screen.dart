import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrivision/core/providers/firebase_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:nutrivision/core/navigation/main_tab_navigator.dart'; // Updated to use tab navigator
import 'package:nutrivision/l10n/app_localizations.dart';

class DietaryPreferencesScreen extends ConsumerStatefulWidget {
  const DietaryPreferencesScreen({super.key});

  @override
  ConsumerState<DietaryPreferencesScreen> createState() =>
      _DietaryPreferencesScreenState();
}

class _DietaryPreferencesScreenState
    extends ConsumerState<DietaryPreferencesScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true; // Start true to load config
  bool _isSaving = false; // For save operation

  // Selected preferences - using a Map to store boolean states for checkboxes
  Map<String, bool> _dietaryPreferences = {};
  List<String> _dietaryPreferencesOptions = [];

  Map<String, bool> _allergies = {};
  List<String> _allergiesOptions = [];

  final _otherRestrictionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRemoteConfigData();
  }

  Future<void> _loadRemoteConfigData() async {
    setState(() => _isLoading = true);
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      // Ensure defaults are set if not already (e.g. in main.dart)
      // await remoteConfig.ensureInitialized(); // Not strictly needed if done in main
      // await remoteConfig.fetchAndActivate(); // Fetch if not done recently

      String dietaryPrefsString = remoteConfig.getString('dietary_preferences');
      _dietaryPreferencesOptions = dietaryPrefsString.isNotEmpty
          ? dietaryPrefsString.split(',').map((e) => e.trim()).toList()
          : [];
      _dietaryPreferences = {
        for (var item in _dietaryPreferencesOptions) item: false,
      };

      String allergiesString = remoteConfig.getString('allergies');
      _allergiesOptions = allergiesString.isNotEmpty
          ? allergiesString.split(',').map((e) => e.trim()).toList()
          : [];
      _allergies = {for (var item in _allergiesOptions) item: false};

      // Load existing user preferences if any
      await _loadUserPreferences();
    } catch (e) {
      print("Error loading remote config for dietary screen: $e");
      // Fallback to hardcoded defaults if Remote Config fails
      _dietaryPreferencesOptions = [
        'Vegan',
        'Vegetarian',
        'Pescetarian',
        'Paleo',
        'Keto',
        'None',
      ];
      _dietaryPreferences = {
        for (var item in _dietaryPreferencesOptions) item: false,
      };
      _allergiesOptions = [
        'Gluten',
        'Dairy',
        'Peanuts',
        'Tree Nuts',
        'Soy',
        'Shellfish',
        'Eggs',
        'Fish',
        'None',
      ];
      _allergies = {for (var item in _allergiesOptions) item: false};
      await _loadUserPreferences(); // Still try to load user data
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadUserPreferences() async {
    User? user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot userDoc = await ref
          .read(firebaseFirestoreProvider)
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data() as Map<String, dynamic>;
        if (data.containsKey('dietary_info')) {
          final dietaryInfo = data['dietary_info'] as Map<String, dynamic>;
          if (dietaryInfo.containsKey('dietaryPreferences')) {
            List<String> savedPrefs = List<String>.from(
              dietaryInfo['dietaryPreferences'],
            );
            for (var pref in savedPrefs) {
              if (_dietaryPreferences.containsKey(pref)) {
                _dietaryPreferences[pref] = true;
              }
            }
          }
          if (dietaryInfo.containsKey('selectedAllergies')) {
            List<String> savedAllergies = List<String>.from(
              dietaryInfo['selectedAllergies'],
            );
            for (var allergy in savedAllergies) {
              if (_allergies.containsKey(allergy)) {
                _allergies[allergy] = true;
              }
            }
          }
          if (dietaryInfo.containsKey('otherRestrictions')) {
            _otherRestrictionsController.text =
                dietaryInfo['otherRestrictions'];
          }
        }
      }
    } catch (e) {
      print("Error loading user dietary preferences: $e");
      // Handle error appropriately
    }
  }

  @override
  void dispose() {
    _otherRestrictionsController.dispose();
    super.dispose();
  }

  Future<void> _savePreferences() async {
    _formKey.currentState!.save();
    setState(() => _isSaving = true); // Start saving
    final l10n = AppLocalizations.of(context)!;

    User? user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorNoUserLoggedIn)), // Updated
        );
        setState(() => _isSaving = false);
      }
      return;
    }
    String uid = user.uid;

    List<String> selectedPreferences = [];
    _dietaryPreferences.forEach((key, value) {
      if (value) {
        selectedPreferences.add(key);
      }
    });

    List<String> selectedAllergies = [];
    _allergies.forEach((key, value) {
      if (value) {
        selectedAllergies.add(key);
      }
    });

    Map<String, dynamic> preferencesData = {
      'dietaryPreferences': selectedPreferences,
      'selectedAllergies':
          selectedAllergies, // Changed from _allergiesController.text
      'otherRestrictions': _otherRestrictionsController.text.trim(),
      'preferencesLastUpdated': FieldValue.serverTimestamp(),
    };

    try {
      // First update the dietary info
      await ref
          .read(firebaseFirestoreProvider)
          .collection('users')
          .doc(uid)
          .set({'dietary_info': preferencesData}, SetOptions(merge: true));

      // Also ensure the profileCompleted flag is set to true
      await ref
          .read(firebaseFirestoreProvider)
          .collection('users')
          .doc(uid)
          .set({
            'profileCompleted': true,
            'profileSetupCompleted': true, // For backward compatibility
            'dietaryPreferencesCompleted':
                true, // New flag to track this step specifically
          }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.dietaryPreferencesSaved)), // Updated
        );
        // Use pushAndRemoveUntil to clear the navigation stack
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainTabNavigator()),
          (route) => false, // This removes all previous routes
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.failedToSavePreferences(e.toString())),
          ), // Updated
        );
      }
      print('Error saving dietary preferences: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false); // Stop saving
      }
    }
  }

  Widget _buildCheckboxGroup(
    String title,
    Map<String, bool> items,
    List<String> itemOrder,
    AppLocalizations l10n,
  ) {
    if (itemOrder.isEmpty) {
      return const SizedBox.shrink(); // Don't show if no options
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: itemOrder.map((String key) {
                return CheckboxListTile(
                  title: Text(
                    l10n.stringFor(key) ?? key,
                  ), // Use l10n.stringFor(key) or fallback to key
                  value: items[key],
                  activeColor: Theme.of(context).colorScheme.primary,
                  onChanged: (bool? value) {
                    setState(() {
                      items[key] = value!;
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dietaryPreferencesTitle), // Updated
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: <Widget>[
                    Text(
                      l10n.dietaryPreferencesHeadline, // Updated
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.dietaryPreferencesSubheadline, // Updated
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 24),
                    _buildCheckboxGroup(
                      l10n.commonDietaryPreferencesTitle, // Updated
                      _dietaryPreferences,
                      _dietaryPreferencesOptions,
                      l10n,
                    ),
                    _buildCheckboxGroup(
                      l10n.commonAllergiesTitle, // Updated
                      _allergies,
                      _allergiesOptions,
                      l10n,
                    ),
                    Text(
                      l10n.otherRestrictionsTitle, // Updated
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _otherRestrictionsController,
                      decoration: InputDecoration(
                        labelText: l10n.otherRestrictionsLabel, // Updated
                        hintText: l10n.otherRestrictionsHint, // Updated
                        prefixIcon: const Icon(
                          Icons.edit_note_outlined,
                        ), // Example Icon
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onPressed: _isSaving ? null : _savePreferences,
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                          : Text(l10n.savePreferencesButton), // Updated
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}

// Helper extension for AppLocalizations
extension AppLocalizationsHelper on AppLocalizations {
  String? stringFor(String key) {
    switch (key) {
      // Dietary Preferences (from Remote Config, ensure these match your Remote Config keys)
      case 'Vegan':
        return vegan;
      case 'Vegetarian':
        return vegetarian;
      case 'Pescetarian':
        return pescatarian;
      case 'Paleo':
        return paleo;
      case 'Keto':
        return keto;
      // Allergies (from Remote Config, ensure these match your Remote Config keys)
      case 'Gluten':
        return glutenFree; // Assuming glutenFree is the key for "Gluten"
      case 'Dairy':
        return dairyFree; // Assuming dairyFree is the key for "Dairy"
      case 'Peanuts':
        return nuts; // Assuming nuts covers peanuts, adjust if specific key exists
      case 'Tree Nuts':
        return nuts; // Assuming nuts covers tree nuts, adjust if specific key exists
      case 'Soy':
        return soy;
      case 'Shellfish':
        return shellfish;
      case 'Eggs':
        return eggs;
      case 'Fish':
        return fish;
      case 'None': // For "None" option if present in Remote Config for either list
        return none; // Add a "none" key to your ARB files
      default:
        return null; // Fallback if no match
    }
  }
}
