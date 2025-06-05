// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'NutriVision';

  @override
  String get signUpTitle => 'Sign Up';

  @override
  String get signInTitle => 'Sign In';

  @override
  String get emailHint => 'Email';

  @override
  String get passwordHint => 'Password';

  @override
  String get confirmPasswordHint => 'Confirm Password';

  @override
  String get signUpButton => 'Sign Up';

  @override
  String get signInButton => 'Sign In';

  @override
  String get forgotPasswordButton => 'Forgot Password?';

  @override
  String get alreadyHaveAccount => 'Already have an account? Sign In';

  @override
  String get dontHaveAccount => 'Dont have an account? Sign Up';

  @override
  String get nameHint => 'Name';

  @override
  String get ageHint => 'Age';

  @override
  String get weightHint => 'Weight';

  @override
  String get heightHint => 'Height';

  @override
  String get activityLevelPrompt => 'Activity Level';

  @override
  String get goalPrompt => 'Goal';

  @override
  String get saveButton => 'Save';

  @override
  String get nextButton => 'Next';

  @override
  String get selectDietaryPreferences => 'Select Dietary Preferences';

  @override
  String get selectAllergies => 'Select Allergies or Restrictions';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get logMealButton => 'Log Meal';

  @override
  String get previousDay => 'Previous Day';

  @override
  String get nextDay => 'Next Day';

  @override
  String get calories => 'Calories';

  @override
  String get protein => 'Protein';

  @override
  String get carbs => 'Carbs';

  @override
  String get fats => 'Fats';

  @override
  String get targets => 'Targets';

  @override
  String get consumed => 'Consumed';

  @override
  String get remaining => 'Remaining';

  @override
  String get mealNameHint => 'Meal Name (e.g., Lunch)';

  @override
  String get foodItemHint => 'Food Item';

  @override
  String get quantityHint => 'Quantity (e.g., 100g or 1 cup)';

  @override
  String get addFoodItemButton => 'Add Food Item';

  @override
  String get submitMealButton => 'Submit Meal';

  @override
  String get forgotPasswordTitle => 'Forgot Password';

  @override
  String get sendResetLinkButton => 'Send Reset Link';

  @override
  String get passwordResetEmailSent =>
      'Password reset email sent. Please check your inbox.';

  @override
  String get errorOccurred => 'An error occurred. Please try again.';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match.';

  @override
  String get weakPassword => 'Password should be at least 6 characters.';

  @override
  String get invalidEmail => 'Invalid email address.';

  @override
  String get userNotFound => 'User not found.';

  @override
  String get wrongPassword => 'Wrong password.';

  @override
  String welcomeMessage(String userName) {
    return 'Welcome $userName';
  }

  @override
  String get termsAndConditions => 'Terms and Conditions';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String iAgreeToThe(String terms, String privacyPolicy) {
    return 'I agree to the $terms and $privacyPolicy';
  }

  @override
  String get pleaseAgreeToTerms =>
      'Please agree to the terms and privacy policy.';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get sexPrompt => 'Sex';

  @override
  String get heightUnitPrompt => 'Height Unit';

  @override
  String get weightUnitPrompt => 'Weight Unit';

  @override
  String get cm => 'cm';

  @override
  String get inches => 'inches';

  @override
  String get kg => 'kg';

  @override
  String get lbs => 'lbs';

  @override
  String get bmr => 'BMR';

  @override
  String get tdee => 'TDEE';

  @override
  String get macronutrientTargets => 'Macronutrient Targets';

  @override
  String get profileSetupTitle => 'Profile Setup';

  @override
  String get dietaryPreferencesTitle => 'Dietary Preferences';

  @override
  String get logMealTitle => 'Log Meal';

  @override
  String get viewProfile => 'View Profile';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get signOut => 'Sign Out';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get searchFood => 'Search Food (e.g., Apple)';

  @override
  String get addSelectedFood => 'Add Selected Food';

  @override
  String get noResultsFound => 'No results found.';

  @override
  String get search => 'Search';

  @override
  String get servingSize => 'Serving Size';

  @override
  String get caloriesPerServing => 'Calories per serving';

  @override
  String get proteinPerServing => 'Protein per serving';

  @override
  String get carbsPerServing => 'Carbs per serving';

  @override
  String get fatsPerServing => 'Fats per serving';

  @override
  String get manualEntry => 'Manual Entry';

  @override
  String get scanBarcode => 'Scan Barcode (Coming Soon!)';

  @override
  String get recentMeals => 'Recent Meals';

  @override
  String get quickAdd => 'Quick Add';

  @override
  String get waterIntake => 'Water Intake';

  @override
  String get addWater => 'Add Water (ml)';

  @override
  String waterGoal(int goal) {
    return 'Water Goal: $goal ml';
  }

  @override
  String waterConsumed(int consumed) {
    return 'Consumed: $consumed ml';
  }

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get english => 'English';

  @override
  String get spanish => 'Spanish';

  @override
  String get french => 'French';

  @override
  String get language => 'Language';

  @override
  String get notifications => 'Notifications';

  @override
  String get enableNotifications => 'Enable Notifications';

  @override
  String get theme => 'Theme';

  @override
  String get lightTheme => 'Light Theme';

  @override
  String get darkTheme => 'Dark Theme';

  @override
  String get systemTheme => 'System Theme';

  @override
  String get account => 'Account';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get confirmDeleteAccount =>
      'Are you sure you want to delete your account? This action cannot be undone.';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get reauthenticateToDelete =>
      'Please sign in again to delete your account.';

  @override
  String get profileUpdatedSuccessfully => 'Profile updated successfully!';

  @override
  String get mealLoggedSuccessfully => 'Meal logged successfully!';

  @override
  String get dataSavedSuccessfully => 'Data saved successfully!';

  @override
  String get requiredField => 'This field is required.';

  @override
  String get invalidNumber => 'Please enter a valid number.';

  @override
  String minAge(int min) {
    return 'Age must be at least $min years.';
  }

  @override
  String maxAge(int max) {
    return 'Age must be at most $max years.';
  }

  @override
  String minWeight(double min, String unit) {
    return 'Weight must be at least $min $unit.';
  }

  @override
  String maxWeight(double max, String unit) {
    return 'Weight must be at most $max $unit.';
  }

  @override
  String minHeight(double min, String unit) {
    return 'Height must be at least $min $unit.';
  }

  @override
  String maxHeight(double max, String unit) {
    return 'Height must be at most $max $unit.';
  }

  @override
  String get sedentary => 'Sedentary (little or no exercise)';

  @override
  String get lightlyActive =>
      'Lightly active (light exercise/sports 1-3 days/week)';

  @override
  String get moderatelyActive =>
      'Moderately active (moderate exercise/sports 3-5 days/week)';

  @override
  String get veryActive => 'Very active (hard exercise/sports 6-7 days a week)';

  @override
  String get extraActive =>
      'Extra active (very hard exercise/sports & physical job or 2x training)';

  @override
  String get maintainWeight => 'Maintain weight';

  @override
  String get mildWeightLoss => 'Mild weight loss (0.25 kg/week)';

  @override
  String get weightLoss => 'Weight loss (0.5 kg/week)';

  @override
  String get extremeWeightLoss => 'Extreme weight loss (1 kg/week)';

  @override
  String get mildWeightGain => 'Mild weight gain (0.25 kg/week)';

  @override
  String get weightGain => 'Weight gain (0.5 kg/week)';

  @override
  String get extremeWeightGain => 'Extreme weight gain (1 kg/week)';

  @override
  String get vegetarian => 'Vegetarian';

  @override
  String get vegan => 'Vegan';

  @override
  String get pescatarian => 'Pescatarian';

  @override
  String get glutenFree => 'Gluten-Free';

  @override
  String get dairyFree => 'Dairy-Free';

  @override
  String get keto => 'Keto';

  @override
  String get paleo => 'Paleo';

  @override
  String get lowCarb => 'Low Carb';

  @override
  String get lowFat => 'Low Fat';

  @override
  String get highProtein => 'High Protein';

  @override
  String get nuts => 'Nuts';

  @override
  String get shellfish => 'Shellfish';

  @override
  String get soy => 'Soy';

  @override
  String get eggs => 'Eggs';

  @override
  String get fish => 'Fish';

  @override
  String get other => 'Other';

  @override
  String get needsUppercaseLetter => 'Needs uppercase letter';

  @override
  String get needsLowercaseLetter => 'Needs lowercase letter';

  @override
  String get needsNumber => 'Needs a number';

  @override
  String get needsSpecialCharacter => 'Needs a special character';

  @override
  String get strongPassword => 'Strong';

  @override
  String get chooseStrongerPassword =>
      'Please choose a stronger password based on the criteria.';

  @override
  String get emailAlreadyInUse =>
      'An account already exists for this email. Please sign in.';

  @override
  String get createAccountJourney =>
      'Create an account to start your nutritional journey.';

  @override
  String get pleaseEnterEmail => 'Please enter your email';

  @override
  String get pleaseEnterPassword => 'Please enter your password';

  @override
  String get pleaseConfirmPassword => 'Please confirm your password';

  @override
  String get passwordTooShort => 'Too short (min 8 chars)';

  @override
  String get passwordCriteriaNotMet =>
      'Please ensure your password meets all criteria.';

  @override
  String get welcomeToNutrivision => 'Welcome to NutriVision!';

  @override
  String get createAccountToStart =>
      'Create an account to start your nutritional journey.';

  @override
  String get emailExample => 'you@example.com';

  @override
  String get tellUsAboutYourself => 'Tell us a bit about yourself';

  @override
  String get helpsCalculateNeeds =>
      'This helps us calculate your nutritional needs.';

  @override
  String get nameExample => 'E.g., Alex Smith';

  @override
  String get pleaseEnterName => 'Please enter your name';

  @override
  String get nameTooShort => 'Name seems too short (min 2 characters)';

  @override
  String get ageExample => 'E.g., 30';

  @override
  String get pleaseEnterAge => 'Please enter your age';

  @override
  String get unrealisticAge => 'Please enter a realistic age (13-100 years)';

  @override
  String get weightExample => 'E.g., 70';

  @override
  String get pleaseEnterWeight => 'Please enter your weight';

  @override
  String get invalidPositiveWeight => 'Please enter a valid positive weight';

  @override
  String get weightTooHigh => 'Weight seems too high, please verify';

  @override
  String get heightExampleCm => 'E.g., 175';

  @override
  String get heightExampleFtIn => 'E.g., 5.10 (5 feet 10 inches)';

  @override
  String get pleaseEnterHeight => 'Please enter your height';

  @override
  String get invalidPositiveHeight => 'Please enter a valid positive height';

  @override
  String get heightFtInFormatHint => 'Use . for ft-in (e.g., 5.10)';

  @override
  String get invalidFtInFormat => 'Invalid ft-in format (e.g., 5.10)';

  @override
  String get validFtInExample => 'Valid ft-in: e.g., 5.10 (0-11 inches)';

  @override
  String get heightTooHigh => 'Height seems too high, please verify';

  @override
  String get heightTooHighCm => 'Height seems too high (max 300cm)';

  @override
  String get heightTooLowCm => 'Height seems too low (min 50cm)';

  @override
  String get pleaseSelectBiologicalSex => 'Please select your biological sex';

  @override
  String get pleaseSelectActivityLevel => 'Please select your activity level';

  @override
  String get pleaseSelectDietaryGoal =>
      'Please select your primary dietary goal';

  @override
  String get errorNoUserLoggedIn =>
      'Error: No user logged in. Please sign in again.';

  @override
  String get profileSavedSuccessProfileSetup =>
      'Profile and nutritional targets saved! Next: Dietary Preferences.';

  @override
  String get failedToSaveProfile => 'Failed to save profile. Please try again.';

  @override
  String get ftIn => 'ft-in';

  @override
  String get otherBiologicalSex => 'Other';

  @override
  String get loseWeightGoal => 'Lose Weight';

  @override
  String get gainMuscleGoal => 'Gain Muscle';

  @override
  String get improveHealthGoal => 'Improve Health';

  @override
  String get refreshData => 'Refresh Data';

  @override
  String get couldNotLoadUserData =>
      'Could not load user data. Please try again.';

  @override
  String get retryButton => 'Retry';

  @override
  String get userGeneric => 'User';

  @override
  String welcomeBackMessage(String userName) {
    return 'Welcome back, $userName!';
  }

  @override
  String get todaysSummary => 'Today\'s Progress';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get viewAll => 'View All';

  @override
  String get noRecentMeals => 'No recent meals logged';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String get aiPhotoLog => 'AI Photo Log';

  @override
  String get manualLog => 'Manual Log';

  @override
  String get mealSuggestions => 'Meal Suggestions';

  @override
  String get gramsUnit => 'g';

  @override
  String get kcalUnit => 'kcal';

  @override
  String get logNewMealButton => 'Log New Meal';

  @override
  String get navigateToEditProfilePlaceholder =>
      'Navigate to Edit Profile/Preferences - TBD';

  @override
  String get editProfilePreferencesButton => 'Edit Profile & Preferences';

  @override
  String summaryForDate(String date) {
    return 'Summary for $date';
  }

  @override
  String get dietaryPreferencesHeadline => 'Help us tailor your experience!';

  @override
  String get dietaryPreferencesSubheadline =>
      'Select any preferences and list allergies or restrictions.';

  @override
  String get commonDietaryPreferencesTitle =>
      'Common Dietary Preferences (Optional):';

  @override
  String get commonAllergiesTitle =>
      'Common Allergies/Intolerances (Optional):';

  @override
  String get otherRestrictionsTitle => 'Other Notes/Restrictions (Optional):';

  @override
  String get otherRestrictionsLabel => 'Other Dietary Notes or Restrictions';

  @override
  String get otherRestrictionsHint =>
      'E.g., low-sodium, avoid spicy food, specific dislikes';

  @override
  String get savePreferencesButton => 'Save Preferences & Continue';

  @override
  String get dietaryPreferencesSaved => 'Dietary preferences saved!';

  @override
  String failedToSavePreferences(String error) {
    return 'Failed to save preferences: $error';
  }

  @override
  String get none => 'None';

  @override
  String get logMealHeadline => 'What did you eat?';

  @override
  String get mealDescriptionLabel => 'Meal Description';

  @override
  String get mealDescriptionHint => 'E.g., Grilled chicken salad, Apple slices';

  @override
  String get pleaseEnterMealDescription => 'Please enter a meal description';

  @override
  String get descriptionTooShort => 'Description seems too short';

  @override
  String descriptionTooLong(String maxLength) {
    return 'Description too long (max $maxLength chars)';
  }

  @override
  String get dateLabel => 'Date';

  @override
  String get timeLabel => 'Time';

  @override
  String get caloriesLabelKcal => 'Calories (kcal)';

  @override
  String get caloriesHint => 'E.g., 350';

  @override
  String get pleaseEnterCalories => 'Please enter calories';

  @override
  String get pleaseEnterValidPositiveNumber =>
      'Please enter a valid positive number';

  @override
  String get caloriesTooHighSingleMeal =>
      'Calories seem very high for a single meal';

  @override
  String get proteinLabelG => 'Protein (g)';

  @override
  String get proteinHint => 'E.g., 30';

  @override
  String get enterProteinOrZero => 'Enter protein (0 if none)';

  @override
  String get invalidAmount => 'Invalid amount';

  @override
  String get proteinTooHigh => 'Protein seems very high';

  @override
  String get carbsLabelG => 'Carbs (g)';

  @override
  String get carbsHint => 'E.g., 45';

  @override
  String get enterCarbsOrZero => 'Enter carbs (0 if none)';

  @override
  String get carbsTooHigh => 'Carbs seem very high';

  @override
  String get fatLabelG => 'Fat (g)';

  @override
  String get fatHint => 'E.g., 15';

  @override
  String get enterFatOrZero => 'Enter fat (0 if none)';

  @override
  String get fatTooHigh => 'Fat seems very high';

  @override
  String failedToLogMeal(String error) {
    return 'Failed to log meal: $error';
  }

  @override
  String get forgotPasswordPrompt =>
      'Enter your email address below and we\'ll send you a link to reset your password.';

  @override
  String get passwordResetEmailSentFeedback =>
      'Password reset email sent successfully. Please check your inbox (and spam folder).';

  @override
  String get backToSignIn => 'Back to Sign In';

  @override
  String get homeTab => 'Home';

  @override
  String get logTab => 'Log';

  @override
  String get statsTab => 'Stats';

  @override
  String get goalsTab => 'Goals';

  @override
  String get profileTab => 'Profile';

  @override
  String get logYourMeal => 'Log Your Meal';

  @override
  String get aiPhotoRecognition => 'AI Photo Recognition';

  @override
  String get takePhotoForLogging =>
      'Take a photo of your meal for instant logging';

  @override
  String get searchFoods => 'Search Foods';

  @override
  String get searchFoodsDescription =>
      'Search our database of foods and recipes';

  @override
  String get createCustomMeal => 'Create Custom Meal';

  @override
  String get createCustomMealDescription => 'Build and save your own meal';

  @override
  String get favorites => 'Favorites';

  @override
  String get favoritesDescription => 'Quickly log your favorite meals';

  @override
  String get profileTitle => 'Profile';

  @override
  String get dietaryPreferences => 'Dietary Preferences';

  @override
  String get appSettings => 'App Settings';

  @override
  String get connectHealthApps => 'Connect Health Apps';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get moreActions => 'More Actions';
}
