import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // Removed
// import 'package:cloud_firestore/cloud_firestore.dart'; // Removed
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Added
import 'package:nutrivision/core/providers/firebase_providers.dart'; // Added
import 'package:firebase_auth/firebase_auth.dart'; // Re-added for User type
import 'package:cloud_firestore/cloud_firestore.dart'; // Re-added for DocumentSnapshot
import 'package:firebase_remote_config/firebase_remote_config.dart'; // Added
import 'package:nutrivision/dietary_preferences_screen.dart'; // Import DietaryPreferencesScreen
import 'package:nutrivision/l10n/app_localizations.dart'; // Add this line

class ProfileSetupScreen extends ConsumerStatefulWidget { // Changed to ConsumerStatefulWidget
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState(); // Changed to ConsumerState
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> { // Changed to ConsumerState
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  bool _isLoading = true; // Start true to load config and user data
  bool _isSaving = false; // For save operation

  // Selected values for dropdowns/radio buttons
  String? _selectedWeightUnit;
  String? _selectedHeightUnit;
  String? _selectedBiologicalSex;
  String? _selectedActivityLevel;
  String? _selectedDietaryGoal;

  // Options for dropdowns
  List<String> _weightUnits = [];
  List<String> _heightUnits = [];
  List<String> _biologicalSexes = [];

  List<String> _activityLevelOptions = [];
  List<String> _dietaryGoalOptions = [];

  @override
  void initState() {
    super.initState();
    // Initialize units after l10n is available, if they need localization
    // For now, assuming 'kg', 'lbs', 'cm', 'ft-in' are universal or handled by ARB keys if displayed differently
    // However, _biologicalSexes, _activityLevelOptions (fallbacks), _dietaryGoalOptions (fallbacks) will be localized.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _weightUnits = [l10n.kg, l10n.lbs];
        _heightUnits = [l10n.cm, "ft-in"]; // TODO: Add l10n key for "ft-in" if needed for display
        _biologicalSexes = [l10n.male, l10n.female, l10n.other]; // 'Other' needs to be added to ARB
        
        // Set default selected units using localized values if they were initialized here
        // Or ensure that comparison in _loadUserProfile uses the same source (l10n or raw string)
        _selectedWeightUnit = l10n.kg;
        _selectedHeightUnit = l10n.cm;
      });
      _loadRemoteConfigAndProfileData();
    });
  }

  Future<void> _loadRemoteConfigAndProfileData() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!; // Get l10n instance here
    setState(() => _isLoading = true);
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;

      String activityLevelsString = remoteConfig.getString('activity_levels');
      _activityLevelOptions = activityLevelsString.isNotEmpty
          ? activityLevelsString.split(',').map((e) => e.trim()).toList()
          : [ // Fallback defaults - these should be localized
              l10n.sedentary, // Assuming keys like sedentary, lightlyActive exist
              l10n.lightlyActive,
              l10n.moderatelyActive,
              l10n.veryActive,
              l10n.extraActive,
            ];

      String dietaryGoalsString = remoteConfig.getString('dietary_goals');
      _dietaryGoalOptions = dietaryGoalsString.isNotEmpty
          ? dietaryGoalsString.split(',').map((e) => e.trim()).toList()
          : [ // Fallback defaults - these should be localized
              // TODO: Add keys like loseWeightGoal, maintainWeightGoal, gainMuscleGoal, improveHealthGoal
              l10n.maintainWeight, // Placeholder, assuming maintainWeight exists
              "Lose Weight", // Placeholder - Add to ARB: loseWeight
              "Gain Muscle", // Placeholder - Add to ARB: gainMuscle
              "Improve Health", // Placeholder - Add to ARB: improveHealth
            ];

      await _loadUserProfile();
    } catch (e) {
      print("Error loading remote config for profile screen: $e");
      _activityLevelOptions = [
        l10n.sedentary,
        l10n.lightlyActive,
        l10n.moderatelyActive,
        l10n.veryActive,
        l10n.extraActive,
      ];
      _dietaryGoalOptions = [
        l10n.maintainWeight,
        "Lose Weight", // Placeholder
        "Gain Muscle", // Placeholder
        "Improve Health", // Placeholder
      ];
      await _loadUserProfile();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadUserProfile() async {
    User? user = ref.read(firebaseAuthProvider).currentUser; // Changed
    if (user == null) return;
    final l10n = AppLocalizations.of(context)!; // Get l10n instance

    try {
      DocumentSnapshot userDoc = await ref.read(firebaseFirestoreProvider).collection('users').doc(user.uid).get(); // Changed
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data() as Map<String, dynamic>;

        _nameController.text = data['name'] ?? '';
        _ageController.text = data['age']?.toString() ?? '';

        if (data['weight'] != null) {
          _weightController.text = data['weight']?.toString() ?? '';
        }
        // Compare with l10n values if _weightUnits is initialized with them
        _selectedWeightUnit = _weightUnits.contains(data['weightUnit']) ? data['weightUnit'] : l10n.kg;

        if (data['height'] != null) {
          _heightController.text = data['height']?.toString() ?? '';
        }
        _selectedHeightUnit = _heightUnits.contains(data['heightUnit']) ? data['heightUnit'] : l10n.cm;

        // For biologicalSex, activityLevel, dietaryGoal, ensure comparison is against the lists populated with l10n strings
        if (data['biologicalSex'] != null && _biologicalSexes.contains(data['biologicalSex'])) {
             _selectedBiologicalSex = data['biologicalSex'];
        }

        if (data['activityLevel'] != null && _activityLevelOptions.contains(data['activityLevel'])) {
          _selectedActivityLevel = data['activityLevel'];
        } else if (_activityLevelOptions.isNotEmpty && data['activityLevel'] != null) {
            // If not found, try to match based on a non-localized key if stored that way
            // This part is tricky if remote config provides English and ARB provides localized.
            // For now, this assumes _activityLevelOptions contains the display strings.
        }

        if (data['dietaryGoal'] != null && _dietaryGoalOptions.contains(data['dietaryGoal'])) {
          _selectedDietaryGoal = data['dietaryGoal'];
        }
      }
    } catch (e) {
      print("Error loading user profile data: $e");
    }
  }

  @override
  void dispose() {
    _nameController.dispose(); // Dispose name controller
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final l10n = AppLocalizations.of(context)!; // Get l10n instance
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isSaving = true); // Start saving state

      User? user = ref.read(firebaseAuthProvider).currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.errorOccurred)), // TODO: Add specific key: errorNoUserLoggedIn
          );
          setState(() => _isSaving = false);
        }
        return;
      }

      String uid = user.uid;

      // Get form values
      String name = _nameController.text;
      int age = int.parse(_ageController.text);
      double weightInput = double.parse(_weightController.text);
      double heightInput = double.parse(_heightController.text); // Renamed to avoid conflict
      String weightUnit = _selectedWeightUnit!;
      String heightUnit = _selectedHeightUnit!;
      String biologicalSex = _selectedBiologicalSex!;
      String activityLevelString = _selectedActivityLevel!;
      String dietaryGoalString = _selectedDietaryGoal!;

      // Convert weight to kg
      double weightInKg = weightInput;
      if (weightUnit == l10n.lbs) { // Compare with localized string
        weightInKg = weightInput * 0.453592;
      }

      // Convert height to cm
      double heightInCm = heightInput;
      if (heightUnit == "ft-in") { // TODO: Use l10n key for "ft-in" comparison if it's localized
        // Assuming heightInput is like 5.10 for 5 feet 10 inches
        int feet = heightInput.floor();
        double inches = (heightInput - feet) * (_heightController.text.contains('.') && _heightController.text.split('.')[1].length == 2 ? 100 : 10) ; // more robust for 5.1 vs 5.10
        heightInCm = (feet * 30.48) + (inches * 2.54);
      }

      // Calculate BMR (Mifflin-St Jeor)
      double bmr;
      if (biologicalSex == l10n.male) { // Compare with localized string
        bmr = (10 * weightInKg) + (6.25 * heightInCm) - (5 * age) + 5;
      } else if (biologicalSex == l10n.female) { // Compare with localized string
        bmr = (10 * weightInKg) + (6.25 * heightInCm) - (5 * age) - 161;
      } else { // 'Other' or any other case, use an average or a neutral formula if available
        // Using female formula as a fallback, or consider a blended approach / average if more appropriate
        // For simplicity, let's use a slightly adjusted average of male and female offsets
        bmr = (10 * weightInKg) + (6.25 * heightInCm) - (5 * age) - 78; // Midpoint-ish
      }

      // Determine Activity Multiplier
      // IMPORTANT: This logic relies on string matching. If _activityLevelOptions are localized,
      // this will break unless we store a non-localized key or compare against l10n.sedentary etc.
      // For now, assuming the strings from Remote Config are English OR that the fallback (localized) strings are used for comparison.
      // This needs careful review based on how Remote Config strings are managed.
      double activityMultiplier;
      // Example if comparing against localized fallbacks:
      if (activityLevelString == l10n.sedentary) {
        activityMultiplier = 1.2;
      } else if (activityLevelString == l10n.lightlyActive) {
        activityMultiplier = 1.375;
      } else if (activityLevelString == l10n.moderatelyActive) {
        activityMultiplier = 1.55;
      } else if (activityLevelString == l10n.veryActive) {
        activityMultiplier = 1.725;
      } else if (activityLevelString == l10n.extraActive) {
        activityMultiplier = 1.9;
      } else {
        activityMultiplier = 1.2; // Default
      }

      double tdee = bmr * activityMultiplier;

      // Adjust TDEE for Dietary Goal
      // Similar caution for dietaryGoalString comparison if localized.
      double targetCalories = tdee;
      Map<String, double> macronutrientPercentages;

      // Example if comparing against localized fallbacks (assuming keys like l10n.loseWeight exist)
      if (dietaryGoalString == "Lose Weight") { // Placeholder - use l10n.loseWeight
        targetCalories -= 500;
        macronutrientPercentages = {
          'protein': 0.40,
          'carbs': 0.30,
          'fat': 0.30,
        };
      } else if (dietaryGoalString == "Gain Muscle") { // Placeholder - use l10n.gainMuscle
        targetCalories += 500;
        macronutrientPercentages = {
          'protein': 0.30,
          'carbs': 0.40,
          'fat': 0.30,
        };
      } else {
        macronutrientPercentages = {
          'protein': 0.30,
          'carbs': 0.40,
          'fat': 0.30,
        };
      }

      // Calculate Macronutrient Grams
      double proteinGrams =
          (targetCalories * macronutrientPercentages['protein']!) / 4;
      double carbsGrams =
          (targetCalories * macronutrientPercentages['carbs']!) / 4;
      double fatGrams = (targetCalories * macronutrientPercentages['fat']!) / 9;

      Map<String, dynamic> profileData = {
        'name': name,
        'age': age,
        'weight': double.parse(weightInKg.toStringAsFixed(2)), // Storing in kg
        'weightUnit': _selectedWeightUnit, // Store the unit they selected for potential display later
        'height': double.parse(heightInCm.toStringAsFixed(2)), // Storing in cm
        'heightUnit': _selectedHeightUnit, // Store the unit
        'biologicalSex': biologicalSex,
        'activityLevel': activityLevelString,
        'dietaryGoal': dietaryGoalString,
        'profileCompleted': true,
        'bmr': bmr.round(),
        'tdee': tdee.round(),
        'targetCalories': targetCalories.round(),
        'targetProteinGrams': proteinGrams.round(),
        'targetCarbsGrams': carbsGrams.round(),
        'targetFatGrams': fatGrams.round(),
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      try {
        await ref.read(firebaseFirestoreProvider)
            .collection('users')
            .doc(uid)
            .set(profileData, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.profileUpdatedSuccessfully), // TODO: Add specific key: profileSavedSuccessProfileSetup
            ),
          );
          // Navigate to DietaryPreferencesScreen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const DietaryPreferencesScreen(),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("${l10n.errorOccurred}: $e"))); // TODO: Add specific key: failedToSaveProfile
        }
        print('Error saving profile: $e');
      } finally {
        if (mounted) {
          setState(() => _isSaving = false); // Stop saving state
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Get l10n instance

    // It's better to initialize these lists here if they depend on l10n,
    // or ensure initState completes before build if l10n is accessed there for list init.
    // For simplicity, assuming _activityLevelOptions and _dietaryGoalOptions are populated correctly before build.

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileSetupTitle), // Localized
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
                      l10n.tellUsAboutYourself, // TODO: Add key
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.helpsCalculateNeeds, // TODO: Add key
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: l10n.nameHint, // Localized
                        hintText: l10n.nameExample, // TODO: Add key: nameExample (e.g., 'Alex Smith')
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.pleaseEnterName; // TODO: Add key
                        }
                        if (value.trim().length < 2) return l10n.nameTooShort; // TODO: Add key
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ageController,
                      decoration: InputDecoration(
                        labelText: l10n.ageHint, // Localized
                        hintText: l10n.ageExample, // TODO: Add key: ageExample (e.g., '30')
                        prefixIcon: const Icon(Icons.cake_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.pleaseEnterAge; // TODO: Add key
                        }
                        final age = int.tryParse(value);
                        if (age == null) return l10n.invalidNumber; // Localized (used existing)
                        if (age <= 12 || age > 100) {
                          return l10n.unrealisticAge; // TODO: Add key (e.g., 'Please enter age between 13-100')
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _weightController,
                            decoration: InputDecoration(
                              labelText: l10n.weightHint, // Localized
                              hintText: l10n.weightExample, // TODO: Add key (e.g., '70')
                              prefixIcon: const Icon(Icons.monitor_weight_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n.pleaseEnterWeight; // TODO: Add key
                              }
                              final weight = double.tryParse(value);
                              if (weight == null || weight <= 0) {
                                return l10n.invalidPositiveWeight; // TODO: Add key
                              }
                              if (weight > 500) {
                                return l10n.weightTooHigh; // TODO: Add key
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 90,
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10.0,
                                vertical: 15.0,
                              ),
                            ),
                            value: _selectedWeightUnit,
                            items: _weightUnits.map((String val) {
                              return DropdownMenuItem<String>(
                                value: val,
                                child: Text(val), // These are already l10n.kg, l10n.lbs from initState
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedWeightUnit = newValue;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _heightController,
                            decoration: InputDecoration(
                              labelText: l10n.heightHint, // Localized
                              hintText: _selectedHeightUnit == l10n.cm
                                  ? l10n.heightExampleCm // TODO: Add key (e.g., '175')
                                  : l10n.heightExampleFtIn, // TODO: Add key (e.g., '5.10 (5ft 10in)')
                              prefixIcon: const Icon(Icons.height_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n.pleaseEnterHeight; // TODO: Add key
                              }
                              final height = double.tryParse(value);
                              if (height == null || height <= 0) {
                                return l10n.invalidPositiveHeight; // TODO: Add key
                              }
                              if (_selectedHeightUnit == "ft-in") { // TODO: Use l10n key for "ft-in" comparison
                                if (!value.contains('.')) {
                                  return l10n.heightFtInFormatHint; // TODO: Add key
                                }
                                final parts = value.split('.');
                                if (parts.length != 2) return l10n.invalidFtInFormat; // TODO: Add key
                                final feet = int.tryParse(parts[0]);
                                final inches = int.tryParse(parts[1]);
                                if (feet == null ||
                                    inches == null ||
                                    feet < 0 ||
                                    inches < 0 ||
                                    inches >= 12) {
                                  return l10n.validFtInExample; // TODO: Add key
                                }
                                if ((feet * 30.48 + inches * 2.54) > 300) {
                                  return l10n.heightTooHigh; // TODO: Add key
                                }
                              } else {
                                if (height > 300) {
                                  return l10n.heightTooHighCm; // TODO: Add key
                                }
                                if (height < 50) {
                                  return l10n.heightTooLowCm; // TODO: Add key
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 90,
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10.0,
                                vertical: 15.0,
                              ),
                            ),
                            value: _selectedHeightUnit,
                            items: _heightUnits.map((String val) {
                              return DropdownMenuItem<String>(
                                value: val,
                                child: Text(val), // These are l10n.cm, "ft-in" from initState
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedHeightUnit = newValue;
                                _heightController.clear();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: l10n.sexPrompt, // Used existing sexPrompt, or biologicalSexPrompt
                        prefixIcon: const Icon(Icons.wc_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      value: _selectedBiologicalSex,
                      items: _biologicalSexes.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value), // These are l10n.male, l10n.female, l10n.other from initState
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedBiologicalSex = newValue;
                        });
                      },
                      validator: (value) =>
                          value == null ? l10n.pleaseSelectBiologicalSex : null, // TODO: Add key
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: l10n.activityLevelPrompt, // Localized
                        prefixIcon: const Icon(Icons.fitness_center_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      value: _selectedActivityLevel,
                      isExpanded: true,
                      items: _activityLevelOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value, // These are from remote config or localized fallbacks
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedActivityLevel = newValue;
                        });
                      },
                      validator: (value) =>
                          value == null || value.isEmpty ? l10n.pleaseSelectActivityLevel : null, // TODO: Add key
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: l10n.goalPrompt, // Used existing goalPrompt, or dietaryGoalPrompt
                        prefixIcon: const Icon(Icons.flag_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      value: _selectedDietaryGoal,
                      isExpanded: true,
                      items: _dietaryGoalOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value, // These are from remote config or localized fallbacks
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedDietaryGoal = newValue;
                        });
                      },
                      validator: (value) =>
                          value == null || value.isEmpty ? l10n.pleaseSelectDietaryGoal : null, // TODO: Add key
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
                      onPressed: _isSaving ? null : _saveProfile,
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                          : Text(l10n.saveButton), // Used existing saveButton, or saveProfileAndContinueButton
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
