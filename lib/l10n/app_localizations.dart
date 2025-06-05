import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'NutriVision'**
  String get appTitle;

  /// No description provided for @signUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpTitle;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInTitle;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailHint;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordHint;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordHint;

  /// No description provided for @signUpButton.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpButton;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInButton;

  /// No description provided for @forgotPasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPasswordButton;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign In'**
  String get alreadyHaveAccount;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Dont have an account? Sign Up'**
  String get dontHaveAccount;

  /// No description provided for @nameHint.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameHint;

  /// No description provided for @ageHint.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get ageHint;

  /// No description provided for @weightHint.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weightHint;

  /// No description provided for @heightHint.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get heightHint;

  /// No description provided for @activityLevelPrompt.
  ///
  /// In en, this message translates to:
  /// **'Activity Level'**
  String get activityLevelPrompt;

  /// No description provided for @goalPrompt.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get goalPrompt;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @nextButton.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextButton;

  /// No description provided for @selectDietaryPreferences.
  ///
  /// In en, this message translates to:
  /// **'Select Dietary Preferences'**
  String get selectDietaryPreferences;

  /// No description provided for @selectAllergies.
  ///
  /// In en, this message translates to:
  /// **'Select Allergies or Restrictions'**
  String get selectAllergies;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @logMealButton.
  ///
  /// In en, this message translates to:
  /// **'Log Meal'**
  String get logMealButton;

  /// No description provided for @previousDay.
  ///
  /// In en, this message translates to:
  /// **'Previous Day'**
  String get previousDay;

  /// No description provided for @nextDay.
  ///
  /// In en, this message translates to:
  /// **'Next Day'**
  String get nextDay;

  /// No description provided for @calories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get calories;

  /// No description provided for @protein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get protein;

  /// No description provided for @carbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get carbs;

  /// No description provided for @fats.
  ///
  /// In en, this message translates to:
  /// **'Fats'**
  String get fats;

  /// No description provided for @targets.
  ///
  /// In en, this message translates to:
  /// **'Targets'**
  String get targets;

  /// No description provided for @consumed.
  ///
  /// In en, this message translates to:
  /// **'Consumed'**
  String get consumed;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @mealNameHint.
  ///
  /// In en, this message translates to:
  /// **'Meal Name (e.g., Lunch)'**
  String get mealNameHint;

  /// No description provided for @foodItemHint.
  ///
  /// In en, this message translates to:
  /// **'Food Item'**
  String get foodItemHint;

  /// No description provided for @quantityHint.
  ///
  /// In en, this message translates to:
  /// **'Quantity (e.g., 100g or 1 cup)'**
  String get quantityHint;

  /// No description provided for @addFoodItemButton.
  ///
  /// In en, this message translates to:
  /// **'Add Food Item'**
  String get addFoodItemButton;

  /// No description provided for @submitMealButton.
  ///
  /// In en, this message translates to:
  /// **'Submit Meal'**
  String get submitMealButton;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPasswordTitle;

  /// No description provided for @sendResetLinkButton.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLinkButton;

  /// No description provided for @passwordResetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent. Please check your inbox.'**
  String get passwordResetEmailSent;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get errorOccurred;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatch;

  /// No description provided for @weakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password should be at least 6 characters.'**
  String get weakPassword;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address.'**
  String get invalidEmail;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found.'**
  String get userNotFound;

  /// No description provided for @wrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password.'**
  String get wrongPassword;

  /// Welcome message on the dashboard
  ///
  /// In en, this message translates to:
  /// **'Welcome {userName}'**
  String welcomeMessage(String userName);

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get termsAndConditions;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Consent text for terms and privacy policy
  ///
  /// In en, this message translates to:
  /// **'I agree to the {terms} and {privacyPolicy}'**
  String iAgreeToThe(String terms, String privacyPolicy);

  /// No description provided for @pleaseAgreeToTerms.
  ///
  /// In en, this message translates to:
  /// **'Please agree to the terms and privacy policy.'**
  String get pleaseAgreeToTerms;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @sexPrompt.
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get sexPrompt;

  /// No description provided for @heightUnitPrompt.
  ///
  /// In en, this message translates to:
  /// **'Height Unit'**
  String get heightUnitPrompt;

  /// No description provided for @weightUnitPrompt.
  ///
  /// In en, this message translates to:
  /// **'Weight Unit'**
  String get weightUnitPrompt;

  /// No description provided for @cm.
  ///
  /// In en, this message translates to:
  /// **'cm'**
  String get cm;

  /// No description provided for @inches.
  ///
  /// In en, this message translates to:
  /// **'inches'**
  String get inches;

  /// No description provided for @kg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get kg;

  /// No description provided for @lbs.
  ///
  /// In en, this message translates to:
  /// **'lbs'**
  String get lbs;

  /// No description provided for @bmr.
  ///
  /// In en, this message translates to:
  /// **'BMR'**
  String get bmr;

  /// No description provided for @tdee.
  ///
  /// In en, this message translates to:
  /// **'TDEE'**
  String get tdee;

  /// No description provided for @macronutrientTargets.
  ///
  /// In en, this message translates to:
  /// **'Macronutrient Targets'**
  String get macronutrientTargets;

  /// No description provided for @profileSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile Setup'**
  String get profileSetupTitle;

  /// No description provided for @dietaryPreferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Dietary Preferences'**
  String get dietaryPreferencesTitle;

  /// No description provided for @logMealTitle.
  ///
  /// In en, this message translates to:
  /// **'Log Meal'**
  String get logMealTitle;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get viewProfile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @searchFood.
  ///
  /// In en, this message translates to:
  /// **'Search Food (e.g., Apple)'**
  String get searchFood;

  /// No description provided for @addSelectedFood.
  ///
  /// In en, this message translates to:
  /// **'Add Selected Food'**
  String get addSelectedFood;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found.'**
  String get noResultsFound;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @servingSize.
  ///
  /// In en, this message translates to:
  /// **'Serving Size'**
  String get servingSize;

  /// No description provided for @caloriesPerServing.
  ///
  /// In en, this message translates to:
  /// **'Calories per serving'**
  String get caloriesPerServing;

  /// No description provided for @proteinPerServing.
  ///
  /// In en, this message translates to:
  /// **'Protein per serving'**
  String get proteinPerServing;

  /// No description provided for @carbsPerServing.
  ///
  /// In en, this message translates to:
  /// **'Carbs per serving'**
  String get carbsPerServing;

  /// No description provided for @fatsPerServing.
  ///
  /// In en, this message translates to:
  /// **'Fats per serving'**
  String get fatsPerServing;

  /// No description provided for @manualEntry.
  ///
  /// In en, this message translates to:
  /// **'Manual Entry'**
  String get manualEntry;

  /// No description provided for @scanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan Barcode (Coming Soon!)'**
  String get scanBarcode;

  /// No description provided for @recentMeals.
  ///
  /// In en, this message translates to:
  /// **'Recent Meals'**
  String get recentMeals;

  /// No description provided for @quickAdd.
  ///
  /// In en, this message translates to:
  /// **'Quick Add'**
  String get quickAdd;

  /// No description provided for @waterIntake.
  ///
  /// In en, this message translates to:
  /// **'Water Intake'**
  String get waterIntake;

  /// No description provided for @addWater.
  ///
  /// In en, this message translates to:
  /// **'Add Water (ml)'**
  String get addWater;

  /// User's water intake goal
  ///
  /// In en, this message translates to:
  /// **'Water Goal: {goal} ml'**
  String waterGoal(int goal);

  /// User's consumed water amount
  ///
  /// In en, this message translates to:
  /// **'Consumed: {consumed} ml'**
  String waterConsumed(int consumed);

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @spanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get spanish;

  /// No description provided for @french.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get french;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light Theme'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get darkTheme;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System Theme'**
  String get systemTheme;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @confirmDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action cannot be undone.'**
  String get confirmDeleteAccount;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @reauthenticateToDelete.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to delete your account.'**
  String get reauthenticateToDelete;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @mealLoggedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Meal logged successfully!'**
  String get mealLoggedSuccessfully;

  /// No description provided for @dataSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Data saved successfully!'**
  String get dataSavedSuccessfully;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get requiredField;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number.'**
  String get invalidNumber;

  /// Validation message for minimum age
  ///
  /// In en, this message translates to:
  /// **'Age must be at least {min} years.'**
  String minAge(int min);

  /// Validation message for maximum age
  ///
  /// In en, this message translates to:
  /// **'Age must be at most {max} years.'**
  String maxAge(int max);

  /// Validation message for minimum weight
  ///
  /// In en, this message translates to:
  /// **'Weight must be at least {min} {unit}.'**
  String minWeight(double min, String unit);

  /// Validation message for maximum weight
  ///
  /// In en, this message translates to:
  /// **'Weight must be at most {max} {unit}.'**
  String maxWeight(double max, String unit);

  /// Validation message for minimum height
  ///
  /// In en, this message translates to:
  /// **'Height must be at least {min} {unit}.'**
  String minHeight(double min, String unit);

  /// Validation message for maximum height
  ///
  /// In en, this message translates to:
  /// **'Height must be at most {max} {unit}.'**
  String maxHeight(double max, String unit);

  /// No description provided for @sedentary.
  ///
  /// In en, this message translates to:
  /// **'Sedentary (little or no exercise)'**
  String get sedentary;

  /// No description provided for @lightlyActive.
  ///
  /// In en, this message translates to:
  /// **'Lightly active (light exercise/sports 1-3 days/week)'**
  String get lightlyActive;

  /// No description provided for @moderatelyActive.
  ///
  /// In en, this message translates to:
  /// **'Moderately active (moderate exercise/sports 3-5 days/week)'**
  String get moderatelyActive;

  /// No description provided for @veryActive.
  ///
  /// In en, this message translates to:
  /// **'Very active (hard exercise/sports 6-7 days a week)'**
  String get veryActive;

  /// No description provided for @extraActive.
  ///
  /// In en, this message translates to:
  /// **'Extra active (very hard exercise/sports & physical job or 2x training)'**
  String get extraActive;

  /// No description provided for @maintainWeight.
  ///
  /// In en, this message translates to:
  /// **'Maintain weight'**
  String get maintainWeight;

  /// No description provided for @mildWeightLoss.
  ///
  /// In en, this message translates to:
  /// **'Mild weight loss (0.25 kg/week)'**
  String get mildWeightLoss;

  /// No description provided for @weightLoss.
  ///
  /// In en, this message translates to:
  /// **'Weight loss (0.5 kg/week)'**
  String get weightLoss;

  /// No description provided for @extremeWeightLoss.
  ///
  /// In en, this message translates to:
  /// **'Extreme weight loss (1 kg/week)'**
  String get extremeWeightLoss;

  /// No description provided for @mildWeightGain.
  ///
  /// In en, this message translates to:
  /// **'Mild weight gain (0.25 kg/week)'**
  String get mildWeightGain;

  /// No description provided for @weightGain.
  ///
  /// In en, this message translates to:
  /// **'Weight gain (0.5 kg/week)'**
  String get weightGain;

  /// No description provided for @extremeWeightGain.
  ///
  /// In en, this message translates to:
  /// **'Extreme weight gain (1 kg/week)'**
  String get extremeWeightGain;

  /// No description provided for @vegetarian.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian'**
  String get vegetarian;

  /// No description provided for @vegan.
  ///
  /// In en, this message translates to:
  /// **'Vegan'**
  String get vegan;

  /// No description provided for @pescatarian.
  ///
  /// In en, this message translates to:
  /// **'Pescatarian'**
  String get pescatarian;

  /// No description provided for @glutenFree.
  ///
  /// In en, this message translates to:
  /// **'Gluten-Free'**
  String get glutenFree;

  /// No description provided for @dairyFree.
  ///
  /// In en, this message translates to:
  /// **'Dairy-Free'**
  String get dairyFree;

  /// No description provided for @keto.
  ///
  /// In en, this message translates to:
  /// **'Keto'**
  String get keto;

  /// No description provided for @paleo.
  ///
  /// In en, this message translates to:
  /// **'Paleo'**
  String get paleo;

  /// No description provided for @lowCarb.
  ///
  /// In en, this message translates to:
  /// **'Low Carb'**
  String get lowCarb;

  /// No description provided for @lowFat.
  ///
  /// In en, this message translates to:
  /// **'Low Fat'**
  String get lowFat;

  /// No description provided for @highProtein.
  ///
  /// In en, this message translates to:
  /// **'High Protein'**
  String get highProtein;

  /// No description provided for @nuts.
  ///
  /// In en, this message translates to:
  /// **'Nuts'**
  String get nuts;

  /// No description provided for @shellfish.
  ///
  /// In en, this message translates to:
  /// **'Shellfish'**
  String get shellfish;

  /// No description provided for @soy.
  ///
  /// In en, this message translates to:
  /// **'Soy'**
  String get soy;

  /// No description provided for @eggs.
  ///
  /// In en, this message translates to:
  /// **'Eggs'**
  String get eggs;

  /// No description provided for @fish.
  ///
  /// In en, this message translates to:
  /// **'Fish'**
  String get fish;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @needsUppercaseLetter.
  ///
  /// In en, this message translates to:
  /// **'Needs uppercase letter'**
  String get needsUppercaseLetter;

  /// No description provided for @needsLowercaseLetter.
  ///
  /// In en, this message translates to:
  /// **'Needs lowercase letter'**
  String get needsLowercaseLetter;

  /// No description provided for @needsNumber.
  ///
  /// In en, this message translates to:
  /// **'Needs a number'**
  String get needsNumber;

  /// No description provided for @needsSpecialCharacter.
  ///
  /// In en, this message translates to:
  /// **'Needs a special character'**
  String get needsSpecialCharacter;

  /// No description provided for @strongPassword.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get strongPassword;

  /// No description provided for @chooseStrongerPassword.
  ///
  /// In en, this message translates to:
  /// **'Please choose a stronger password based on the criteria.'**
  String get chooseStrongerPassword;

  /// No description provided for @emailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'An account already exists for this email. Please sign in.'**
  String get emailAlreadyInUse;

  /// No description provided for @createAccountJourney.
  ///
  /// In en, this message translates to:
  /// **'Create an account to start your nutritional journey.'**
  String get createAccountJourney;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterEmail;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// No description provided for @pleaseConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get pleaseConfirmPassword;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Too short (min 8 chars)'**
  String get passwordTooShort;

  /// No description provided for @passwordCriteriaNotMet.
  ///
  /// In en, this message translates to:
  /// **'Please ensure your password meets all criteria.'**
  String get passwordCriteriaNotMet;

  /// No description provided for @welcomeToNutrivision.
  ///
  /// In en, this message translates to:
  /// **'Welcome to NutriVision!'**
  String get welcomeToNutrivision;

  /// No description provided for @createAccountToStart.
  ///
  /// In en, this message translates to:
  /// **'Create an account to start your nutritional journey.'**
  String get createAccountToStart;

  /// No description provided for @emailExample.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get emailExample;

  /// No description provided for @tellUsAboutYourself.
  ///
  /// In en, this message translates to:
  /// **'Tell us a bit about yourself'**
  String get tellUsAboutYourself;

  /// No description provided for @helpsCalculateNeeds.
  ///
  /// In en, this message translates to:
  /// **'This helps us calculate your nutritional needs.'**
  String get helpsCalculateNeeds;

  /// No description provided for @nameExample.
  ///
  /// In en, this message translates to:
  /// **'E.g., Alex Smith'**
  String get nameExample;

  /// No description provided for @pleaseEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterName;

  /// No description provided for @nameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Name seems too short (min 2 characters)'**
  String get nameTooShort;

  /// No description provided for @ageExample.
  ///
  /// In en, this message translates to:
  /// **'E.g., 30'**
  String get ageExample;

  /// No description provided for @pleaseEnterAge.
  ///
  /// In en, this message translates to:
  /// **'Please enter your age'**
  String get pleaseEnterAge;

  /// No description provided for @unrealisticAge.
  ///
  /// In en, this message translates to:
  /// **'Please enter a realistic age (13-100 years)'**
  String get unrealisticAge;

  /// No description provided for @weightExample.
  ///
  /// In en, this message translates to:
  /// **'E.g., 70'**
  String get weightExample;

  /// No description provided for @pleaseEnterWeight.
  ///
  /// In en, this message translates to:
  /// **'Please enter your weight'**
  String get pleaseEnterWeight;

  /// No description provided for @invalidPositiveWeight.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid positive weight'**
  String get invalidPositiveWeight;

  /// No description provided for @weightTooHigh.
  ///
  /// In en, this message translates to:
  /// **'Weight seems too high, please verify'**
  String get weightTooHigh;

  /// No description provided for @heightExampleCm.
  ///
  /// In en, this message translates to:
  /// **'E.g., 175'**
  String get heightExampleCm;

  /// No description provided for @heightExampleFtIn.
  ///
  /// In en, this message translates to:
  /// **'E.g., 5.10 (5 feet 10 inches)'**
  String get heightExampleFtIn;

  /// No description provided for @pleaseEnterHeight.
  ///
  /// In en, this message translates to:
  /// **'Please enter your height'**
  String get pleaseEnterHeight;

  /// No description provided for @invalidPositiveHeight.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid positive height'**
  String get invalidPositiveHeight;

  /// No description provided for @heightFtInFormatHint.
  ///
  /// In en, this message translates to:
  /// **'Use . for ft-in (e.g., 5.10)'**
  String get heightFtInFormatHint;

  /// No description provided for @invalidFtInFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid ft-in format (e.g., 5.10)'**
  String get invalidFtInFormat;

  /// No description provided for @validFtInExample.
  ///
  /// In en, this message translates to:
  /// **'Valid ft-in: e.g., 5.10 (0-11 inches)'**
  String get validFtInExample;

  /// No description provided for @heightTooHigh.
  ///
  /// In en, this message translates to:
  /// **'Height seems too high, please verify'**
  String get heightTooHigh;

  /// No description provided for @heightTooHighCm.
  ///
  /// In en, this message translates to:
  /// **'Height seems too high (max 300cm)'**
  String get heightTooHighCm;

  /// No description provided for @heightTooLowCm.
  ///
  /// In en, this message translates to:
  /// **'Height seems too low (min 50cm)'**
  String get heightTooLowCm;

  /// No description provided for @pleaseSelectBiologicalSex.
  ///
  /// In en, this message translates to:
  /// **'Please select your biological sex'**
  String get pleaseSelectBiologicalSex;

  /// No description provided for @pleaseSelectActivityLevel.
  ///
  /// In en, this message translates to:
  /// **'Please select your activity level'**
  String get pleaseSelectActivityLevel;

  /// No description provided for @pleaseSelectDietaryGoal.
  ///
  /// In en, this message translates to:
  /// **'Please select your primary dietary goal'**
  String get pleaseSelectDietaryGoal;

  /// No description provided for @errorNoUserLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Error: No user logged in. Please sign in again.'**
  String get errorNoUserLoggedIn;

  /// No description provided for @profileSavedSuccessProfileSetup.
  ///
  /// In en, this message translates to:
  /// **'Profile and nutritional targets saved! Next: Dietary Preferences.'**
  String get profileSavedSuccessProfileSetup;

  /// No description provided for @failedToSaveProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to save profile. Please try again.'**
  String get failedToSaveProfile;

  /// No description provided for @ftIn.
  ///
  /// In en, this message translates to:
  /// **'ft-in'**
  String get ftIn;

  /// No description provided for @otherBiologicalSex.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherBiologicalSex;

  /// No description provided for @loseWeightGoal.
  ///
  /// In en, this message translates to:
  /// **'Lose Weight'**
  String get loseWeightGoal;

  /// No description provided for @gainMuscleGoal.
  ///
  /// In en, this message translates to:
  /// **'Gain Muscle'**
  String get gainMuscleGoal;

  /// No description provided for @improveHealthGoal.
  ///
  /// In en, this message translates to:
  /// **'Improve Health'**
  String get improveHealthGoal;

  /// No description provided for @refreshData.
  ///
  /// In en, this message translates to:
  /// **'Refresh Data'**
  String get refreshData;

  /// No description provided for @couldNotLoadUserData.
  ///
  /// In en, this message translates to:
  /// **'Could not load user data. Please try again.'**
  String get couldNotLoadUserData;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// No description provided for @userGeneric.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userGeneric;

  /// Welcome message on the dashboard greeting the user
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {userName}!'**
  String welcomeBackMessage(String userName);

  /// No description provided for @todaysSummary.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Progress'**
  String get todaysSummary;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @noRecentMeals.
  ///
  /// In en, this message translates to:
  /// **'No recent meals logged'**
  String get noRecentMeals;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @aiPhotoLog.
  ///
  /// In en, this message translates to:
  /// **'AI Photo Log'**
  String get aiPhotoLog;

  /// No description provided for @manualLog.
  ///
  /// In en, this message translates to:
  /// **'Manual Log'**
  String get manualLog;

  /// No description provided for @mealSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Meal Suggestions'**
  String get mealSuggestions;

  /// No description provided for @gramsUnit.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get gramsUnit;

  /// No description provided for @kcalUnit.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get kcalUnit;

  /// No description provided for @logNewMealButton.
  ///
  /// In en, this message translates to:
  /// **'Log New Meal'**
  String get logNewMealButton;

  /// No description provided for @navigateToEditProfilePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Navigate to Edit Profile/Preferences - TBD'**
  String get navigateToEditProfilePlaceholder;

  /// No description provided for @editProfilePreferencesButton.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile & Preferences'**
  String get editProfilePreferencesButton;

  /// Summary title with date
  ///
  /// In en, this message translates to:
  /// **'Summary for {date}'**
  String summaryForDate(String date);

  /// No description provided for @dietaryPreferencesHeadline.
  ///
  /// In en, this message translates to:
  /// **'Help us tailor your experience!'**
  String get dietaryPreferencesHeadline;

  /// No description provided for @dietaryPreferencesSubheadline.
  ///
  /// In en, this message translates to:
  /// **'Select any preferences and list allergies or restrictions.'**
  String get dietaryPreferencesSubheadline;

  /// No description provided for @commonDietaryPreferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Common Dietary Preferences (Optional):'**
  String get commonDietaryPreferencesTitle;

  /// No description provided for @commonAllergiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Common Allergies/Intolerances (Optional):'**
  String get commonAllergiesTitle;

  /// No description provided for @otherRestrictionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Other Notes/Restrictions (Optional):'**
  String get otherRestrictionsTitle;

  /// No description provided for @otherRestrictionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Other Dietary Notes or Restrictions'**
  String get otherRestrictionsLabel;

  /// No description provided for @otherRestrictionsHint.
  ///
  /// In en, this message translates to:
  /// **'E.g., low-sodium, avoid spicy food, specific dislikes'**
  String get otherRestrictionsHint;

  /// No description provided for @savePreferencesButton.
  ///
  /// In en, this message translates to:
  /// **'Save Preferences & Continue'**
  String get savePreferencesButton;

  /// No description provided for @dietaryPreferencesSaved.
  ///
  /// In en, this message translates to:
  /// **'Dietary preferences saved!'**
  String get dietaryPreferencesSaved;

  /// Error message when saving dietary preferences fails
  ///
  /// In en, this message translates to:
  /// **'Failed to save preferences: {error}'**
  String failedToSavePreferences(String error);

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @logMealHeadline.
  ///
  /// In en, this message translates to:
  /// **'What did you eat?'**
  String get logMealHeadline;

  /// No description provided for @mealDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Meal Description'**
  String get mealDescriptionLabel;

  /// No description provided for @mealDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'E.g., Grilled chicken salad, Apple slices'**
  String get mealDescriptionHint;

  /// No description provided for @pleaseEnterMealDescription.
  ///
  /// In en, this message translates to:
  /// **'Please enter a meal description'**
  String get pleaseEnterMealDescription;

  /// No description provided for @descriptionTooShort.
  ///
  /// In en, this message translates to:
  /// **'Description seems too short'**
  String get descriptionTooShort;

  /// Validation message for meal description exceeding max length
  ///
  /// In en, this message translates to:
  /// **'Description too long (max {maxLength} chars)'**
  String descriptionTooLong(String maxLength);

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @timeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeLabel;

  /// No description provided for @caloriesLabelKcal.
  ///
  /// In en, this message translates to:
  /// **'Calories (kcal)'**
  String get caloriesLabelKcal;

  /// No description provided for @caloriesHint.
  ///
  /// In en, this message translates to:
  /// **'E.g., 350'**
  String get caloriesHint;

  /// No description provided for @pleaseEnterCalories.
  ///
  /// In en, this message translates to:
  /// **'Please enter calories'**
  String get pleaseEnterCalories;

  /// No description provided for @pleaseEnterValidPositiveNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid positive number'**
  String get pleaseEnterValidPositiveNumber;

  /// No description provided for @caloriesTooHighSingleMeal.
  ///
  /// In en, this message translates to:
  /// **'Calories seem very high for a single meal'**
  String get caloriesTooHighSingleMeal;

  /// No description provided for @proteinLabelG.
  ///
  /// In en, this message translates to:
  /// **'Protein (g)'**
  String get proteinLabelG;

  /// No description provided for @proteinHint.
  ///
  /// In en, this message translates to:
  /// **'E.g., 30'**
  String get proteinHint;

  /// No description provided for @enterProteinOrZero.
  ///
  /// In en, this message translates to:
  /// **'Enter protein (0 if none)'**
  String get enterProteinOrZero;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get invalidAmount;

  /// No description provided for @proteinTooHigh.
  ///
  /// In en, this message translates to:
  /// **'Protein seems very high'**
  String get proteinTooHigh;

  /// No description provided for @carbsLabelG.
  ///
  /// In en, this message translates to:
  /// **'Carbs (g)'**
  String get carbsLabelG;

  /// No description provided for @carbsHint.
  ///
  /// In en, this message translates to:
  /// **'E.g., 45'**
  String get carbsHint;

  /// No description provided for @enterCarbsOrZero.
  ///
  /// In en, this message translates to:
  /// **'Enter carbs (0 if none)'**
  String get enterCarbsOrZero;

  /// No description provided for @carbsTooHigh.
  ///
  /// In en, this message translates to:
  /// **'Carbs seem very high'**
  String get carbsTooHigh;

  /// No description provided for @fatLabelG.
  ///
  /// In en, this message translates to:
  /// **'Fat (g)'**
  String get fatLabelG;

  /// No description provided for @fatHint.
  ///
  /// In en, this message translates to:
  /// **'E.g., 15'**
  String get fatHint;

  /// No description provided for @enterFatOrZero.
  ///
  /// In en, this message translates to:
  /// **'Enter fat (0 if none)'**
  String get enterFatOrZero;

  /// No description provided for @fatTooHigh.
  ///
  /// In en, this message translates to:
  /// **'Fat seems very high'**
  String get fatTooHigh;

  /// Error message when failing to log a meal
  ///
  /// In en, this message translates to:
  /// **'Failed to log meal: {error}'**
  String failedToLogMeal(String error);

  /// No description provided for @forgotPasswordPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address below and we\'ll send you a link to reset your password.'**
  String get forgotPasswordPrompt;

  /// No description provided for @passwordResetEmailSentFeedback.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent successfully. Please check your inbox (and spam folder).'**
  String get passwordResetEmailSentFeedback;

  /// No description provided for @backToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to Sign In'**
  String get backToSignIn;

  /// No description provided for @homeTab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTab;

  /// No description provided for @logTab.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get logTab;

  /// No description provided for @statsTab.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get statsTab;

  /// No description provided for @goalsTab.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goalsTab;

  /// No description provided for @profileTab.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTab;

  /// No description provided for @logYourMeal.
  ///
  /// In en, this message translates to:
  /// **'Log Your Meal'**
  String get logYourMeal;

  /// No description provided for @aiPhotoRecognition.
  ///
  /// In en, this message translates to:
  /// **'AI Photo Recognition'**
  String get aiPhotoRecognition;

  /// No description provided for @takePhotoForLogging.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of your meal for instant logging'**
  String get takePhotoForLogging;

  /// No description provided for @searchFoods.
  ///
  /// In en, this message translates to:
  /// **'Search Foods'**
  String get searchFoods;

  /// No description provided for @searchFoodsDescription.
  ///
  /// In en, this message translates to:
  /// **'Search our database of foods and recipes'**
  String get searchFoodsDescription;

  /// No description provided for @createCustomMeal.
  ///
  /// In en, this message translates to:
  /// **'Create Custom Meal'**
  String get createCustomMeal;

  /// No description provided for @createCustomMealDescription.
  ///
  /// In en, this message translates to:
  /// **'Build and save your own meal'**
  String get createCustomMealDescription;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @favoritesDescription.
  ///
  /// In en, this message translates to:
  /// **'Quickly log your favorite meals'**
  String get favoritesDescription;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @dietaryPreferences.
  ///
  /// In en, this message translates to:
  /// **'Dietary Preferences'**
  String get dietaryPreferences;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettings;

  /// No description provided for @connectHealthApps.
  ///
  /// In en, this message translates to:
  /// **'Connect Health Apps'**
  String get connectHealthApps;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @moreActions.
  ///
  /// In en, this message translates to:
  /// **'More Actions'**
  String get moreActions;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
