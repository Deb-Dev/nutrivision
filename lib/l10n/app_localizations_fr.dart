// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'NutriVision';

  @override
  String get signUpTitle => 'S\'inscrire';

  @override
  String get signInTitle => 'Se Connecter';

  @override
  String get emailHint => 'Email';

  @override
  String get passwordHint => 'Mot de passe';

  @override
  String get confirmPasswordHint => 'Confirmer le mot de passe';

  @override
  String get signUpButton => 'S\'inscrire';

  @override
  String get signInButton => 'Se Connecter';

  @override
  String get forgotPasswordButton => 'Mot de passe oublié ?';

  @override
  String get alreadyHaveAccount => 'Vous avez déjà un compte ? Se Connecter';

  @override
  String get dontHaveAccount => 'Vous n\'avez pas de compte ? S\'inscrire';

  @override
  String get nameHint => 'Nom';

  @override
  String get ageHint => 'Âge';

  @override
  String get weightHint => 'Poids';

  @override
  String get heightHint => 'Taille';

  @override
  String get activityLevelPrompt => 'Niveau d\'activité';

  @override
  String get goalPrompt => 'Objectif';

  @override
  String get saveButton => 'Enregistrer';

  @override
  String get nextButton => 'Suivant';

  @override
  String get selectDietaryPreferences =>
      'Sélectionner les préférences alimentaires';

  @override
  String get selectAllergies => 'Sélectionner les allergies ou restrictions';

  @override
  String get dashboardTitle => 'Tableau de bord';

  @override
  String get logMealButton => 'Enregistrer un repas';

  @override
  String get previousDay => 'Jour précédent';

  @override
  String get nextDay => 'Jour suivant';

  @override
  String get calories => 'Calories';

  @override
  String get protein => 'Protéines';

  @override
  String get carbs => 'Glucides';

  @override
  String get fats => 'Lipides';

  @override
  String get targets => 'Objectifs';

  @override
  String get consumed => 'Consommé';

  @override
  String get remaining => 'Restant';

  @override
  String get mealNameHint => 'Nom du repas (ex. Déjeuner)';

  @override
  String get foodItemHint => 'Aliment';

  @override
  String get quantityHint => 'Quantité (ex. 100g ou 1 tasse)';

  @override
  String get addFoodItemButton => 'Ajouter un aliment';

  @override
  String get submitMealButton => 'Soumettre le repas';

  @override
  String get forgotPasswordTitle => 'Mot de passe oublié';

  @override
  String get sendResetLinkButton => 'Envoyer le lien de réinitialisation';

  @override
  String get passwordResetEmailSent =>
      'E-mail de réinitialisation du mot de passe envoyé. Veuillez vérifier votre boîte de réception.';

  @override
  String get errorOccurred => 'Une erreur est survenue. Veuillez réessayer.';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas.';

  @override
  String get weakPassword =>
      'Le mot de passe doit contenir au moins 6 caractères.';

  @override
  String get invalidEmail => 'Adresse e-mail invalide.';

  @override
  String get userNotFound => 'Utilisateur non trouvé.';

  @override
  String get wrongPassword => 'Mot de passe incorrect.';

  @override
  String welcomeMessage(String userName) {
    return 'Bienvenue $userName';
  }

  @override
  String get termsAndConditions => 'Termes et Conditions';

  @override
  String get privacyPolicy => 'Politique de Confidentialité';

  @override
  String iAgreeToThe(String terms, String privacyPolicy) {
    return 'J\'accepte les $terms et la $privacyPolicy';
  }

  @override
  String get pleaseAgreeToTerms =>
      'Veuillez accepter les termes et la politique de confidentialité.';

  @override
  String get male => 'Homme';

  @override
  String get female => 'Femme';

  @override
  String get sexPrompt => 'Sexe';

  @override
  String get heightUnitPrompt => 'Unité de taille';

  @override
  String get weightUnitPrompt => 'Unité de poids';

  @override
  String get cm => 'cm';

  @override
  String get inches => 'pouces';

  @override
  String get kg => 'kg';

  @override
  String get lbs => 'livres';

  @override
  String get bmr => 'MB';

  @override
  String get tdee => 'DÉJ';

  @override
  String get macronutrientTargets => 'Objectifs en macronutriments';

  @override
  String get profileSetupTitle => 'Configuration du profil';

  @override
  String get dietaryPreferencesTitle => 'Préférences alimentaires';

  @override
  String get logMealTitle => 'Enregistrer un repas';

  @override
  String get viewProfile => 'Voir le profil';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Paramètres';

  @override
  String get searchFood => 'Rechercher un aliment (ex. Pomme)';

  @override
  String get addSelectedFood => 'Ajouter l\'aliment sélectionné';

  @override
  String get noResultsFound => 'Aucun résultat trouvé.';

  @override
  String get search => 'Rechercher';

  @override
  String get servingSize => 'Taille de la portion';

  @override
  String get caloriesPerServing => 'Calories par portion';

  @override
  String get proteinPerServing => 'Protéines par portion';

  @override
  String get carbsPerServing => 'Glucides par portion';

  @override
  String get fatsPerServing => 'Lipides par portion';

  @override
  String get manualEntry => 'Saisie manuelle';

  @override
  String get scanBarcode => 'Scanner le code-barres (Bientôt disponible !)';

  @override
  String get recentMeals => 'Repas récents';

  @override
  String get quickAdd => 'Ajout rapide';

  @override
  String get waterIntake => 'Consommation d\'eau';

  @override
  String get addWater => 'Ajouter de l\'eau (ml)';

  @override
  String waterGoal(int goal) {
    return 'Objectif d\'eau : $goal ml';
  }

  @override
  String waterConsumed(int consumed) {
    return 'Consommé : $consumed ml';
  }

  @override
  String get selectLanguage => 'Sélectionner la langue';

  @override
  String get english => 'Anglais';

  @override
  String get spanish => 'Espagnol';

  @override
  String get french => 'Français';

  @override
  String get language => 'Langue';

  @override
  String get notifications => 'Notifications';

  @override
  String get enableNotifications => 'Activer les notifications';

  @override
  String get theme => 'Thème';

  @override
  String get lightTheme => 'Thème clair';

  @override
  String get darkTheme => 'Thème sombre';

  @override
  String get systemTheme => 'Thème du système';

  @override
  String get account => 'Compte';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get confirmDeleteAccount =>
      'Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible.';

  @override
  String get delete => 'Supprimer';

  @override
  String get cancel => 'Annuler';

  @override
  String get reauthenticateToDelete =>
      'Veuillez vous reconnecter pour supprimer votre compte.';

  @override
  String get profileUpdatedSuccessfully => 'Profil mis à jour avec succès !';

  @override
  String get mealLoggedSuccessfully => 'Repas enregistré avec succès !';

  @override
  String get dataSavedSuccessfully => 'Données enregistrées avec succès !';

  @override
  String get requiredField => 'Ce champ est obligatoire.';

  @override
  String get invalidNumber => 'Veuillez entrer un nombre valide.';

  @override
  String minAge(int min) {
    return 'L\'âge doit être d\'au moins $min ans.';
  }

  @override
  String maxAge(int max) {
    return 'L\'âge doit être au maximum de $max ans.';
  }

  @override
  String minWeight(double min, String unit) {
    return 'Le poids doit être d\'au moins $min $unit.';
  }

  @override
  String maxWeight(double max, String unit) {
    return 'Le poids doit être au maximum de $max $unit.';
  }

  @override
  String minHeight(double min, String unit) {
    return 'La taille doit être d\'au moins $min $unit.';
  }

  @override
  String maxHeight(double max, String unit) {
    return 'La taille doit être au maximum de $max $unit.';
  }

  @override
  String get sedentary => 'Sédentaire (peu ou pas d\'exercice)';

  @override
  String get lightlyActive =>
      'Légèrement actif (exercice léger/sport 1-3 jours/semaine)';

  @override
  String get moderatelyActive =>
      'Modérément actif (exercice modéré/sport 3-5 jours/semaine)';

  @override
  String get veryActive =>
      'Très actif (exercice intense/sport 6-7 jours par semaine)';

  @override
  String get extraActive =>
      'Extra actif (exercice très intense/sport et travail physique ou double entraînement)';

  @override
  String get maintainWeight => 'Maintenir le poids';

  @override
  String get mildWeightLoss => 'Perte de poids légère (0.25 kg/semaine)';

  @override
  String get weightLoss => 'Perte de poids (0.5 kg/semaine)';

  @override
  String get extremeWeightLoss => 'Perte de poids extrême (1 kg/semaine)';

  @override
  String get mildWeightGain => 'Prise de poids légère (0.25 kg/semaine)';

  @override
  String get weightGain => 'Prise de poids (0.5 kg/semaine)';

  @override
  String get extremeWeightGain => 'Prise de poids extrême (1 kg/semaine)';

  @override
  String get vegetarian => 'Végétarien';

  @override
  String get vegan => 'Végétalien';

  @override
  String get pescatarian => 'Pescatarien';

  @override
  String get glutenFree => 'Sans Gluten';

  @override
  String get dairyFree => 'Sans Produits Laitiers';

  @override
  String get keto => 'Céto';

  @override
  String get paleo => 'Paléo';

  @override
  String get lowCarb => 'Faible en Glucides';

  @override
  String get lowFat => 'Faible en Gras';

  @override
  String get highProtein => 'Riche en Protéines';

  @override
  String get nuts => 'Noix';

  @override
  String get shellfish => 'Fruits de mer';

  @override
  String get soy => 'Soja';

  @override
  String get eggs => 'Œufs';

  @override
  String get fish => 'Poisson';

  @override
  String get other => 'Autre';

  @override
  String get needsUppercaseLetter => 'Nécessite une majuscule';

  @override
  String get needsLowercaseLetter => 'Nécessite une minuscule';

  @override
  String get needsNumber => 'Nécessite un chiffre';

  @override
  String get needsSpecialCharacter => 'Nécessite un caractère spécial';

  @override
  String get strongPassword => 'Mot de passe fort';

  @override
  String get chooseStrongerPassword =>
      'Veuillez choisir un mot de passe plus fort selon les critères.';

  @override
  String get emailAlreadyInUse =>
      'Un compte existe déjà pour cet e-mail. Veuillez vous connecter.';

  @override
  String get createAccountJourney =>
      'Créez un compte pour commencer votre parcours nutritionnel.';

  @override
  String get pleaseEnterEmail => 'Veuillez entrer votre email';

  @override
  String get pleaseEnterPassword => 'Veuillez entrer votre mot de passe';

  @override
  String get pleaseConfirmPassword => 'Veuillez confirmer votre mot de passe';

  @override
  String get passwordTooShort => 'Trop court (min 8 caractères)';

  @override
  String get passwordCriteriaNotMet =>
      'Veuillez vous assurer que votre mot de passe respecte tous les critères.';

  @override
  String get welcomeToNutrivision => 'Bienvenue chez NutriVision !';

  @override
  String get createAccountToStart =>
      'Créez un compte pour commencer votre parcours nutritionnel.';

  @override
  String get emailExample => 'vous@exemple.com';

  @override
  String get tellUsAboutYourself => 'Parlez-nous un peu de vous';

  @override
  String get helpsCalculateNeeds =>
      'Cela nous aide à calculer vos besoins nutritionnels.';

  @override
  String get nameExample => 'Ex., Alex Dupont';

  @override
  String get pleaseEnterName => 'Veuillez entrer votre nom';

  @override
  String get nameTooShort => 'Le nom semble trop court (min 2 caractères)';

  @override
  String get ageExample => 'Ex., 30';

  @override
  String get pleaseEnterAge => 'Veuillez entrer votre âge';

  @override
  String get unrealisticAge => 'Veuillez entrer un âge réaliste (13-100 ans)';

  @override
  String get weightExample => 'Ex., 70';

  @override
  String get pleaseEnterWeight => 'Veuillez entrer votre poids';

  @override
  String get invalidPositiveWeight => 'Veuillez entrer un poids positif valide';

  @override
  String get weightTooHigh => 'Le poids semble trop élevé, veuillez vérifier';

  @override
  String get heightExampleCm => 'Ex., 175';

  @override
  String get heightExampleFtIn => 'Ex., 5.10 (5 pieds 10 pouces)';

  @override
  String get pleaseEnterHeight => 'Veuillez entrer votre taille';

  @override
  String get invalidPositiveHeight =>
      'Veuillez entrer une taille positive valide';

  @override
  String get heightFtInFormatHint => 'Utilisez . pour pieds-pouces (ex., 5.10)';

  @override
  String get invalidFtInFormat => 'Format pieds-pouces invalide (ex., 5.10)';

  @override
  String get validFtInExample =>
      'Pieds-pouces valide : ex., 5.10 (0-11 pouces)';

  @override
  String get heightTooHigh => 'La taille semble trop élevée, veuillez vérifier';

  @override
  String get heightTooHighCm => 'La taille semble trop élevée (max 300cm)';

  @override
  String get heightTooLowCm => 'La taille semble trop basse (min 50cm)';

  @override
  String get pleaseSelectBiologicalSex =>
      'Veuillez sélectionner votre sexe biologique';

  @override
  String get pleaseSelectActivityLevel =>
      'Veuillez sélectionner votre niveau d\'activité';

  @override
  String get pleaseSelectDietaryGoal =>
      'Veuillez sélectionner votre objectif diététique principal';

  @override
  String get errorNoUserLoggedIn =>
      'Erreur : Aucun utilisateur connecté. Veuillez vous reconnecter.';

  @override
  String get profileSavedSuccessProfileSetup =>
      'Profil et objectifs nutritionnels enregistrés ! Suivant : Préférences Alimentaires.';

  @override
  String get failedToSaveProfile =>
      'Échec de l\'enregistrement du profil. Veuillez réessayer.';

  @override
  String get ftIn => 'pi-po';

  @override
  String get otherBiologicalSex => 'Autre';

  @override
  String get loseWeightGoal => 'Perdre du Poids';

  @override
  String get gainMuscleGoal => 'Gagner du Muscle';

  @override
  String get improveHealthGoal => 'Améliorer la Santé';

  @override
  String get refreshData => 'Actualiser les données';

  @override
  String get couldNotLoadUserData =>
      'Impossible de charger les données utilisateur. Veuillez réessayer.';

  @override
  String get retryButton => 'Réessayer';

  @override
  String get userGeneric => 'Utilisateur';

  @override
  String welcomeBackMessage(String userName) {
    return 'Content de vous revoir, $userName!';
  }

  @override
  String get todaysSummary => 'Résumé d\'aujourd\'hui';

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
  String get logNewMealButton => 'Enregistrer un nouveau repas';

  @override
  String get navigateToEditProfilePlaceholder =>
      'Accéder à la modification du profil/préférences - À FAIRE';

  @override
  String get editProfilePreferencesButton =>
      'Modifier le profil et les préférences';

  @override
  String summaryForDate(String date) {
    return 'Résumé pour le $date';
  }

  @override
  String get dietaryPreferencesHeadline =>
      'Aidez-nous à personnaliser votre expérience !';

  @override
  String get dietaryPreferencesSubheadline =>
      'Sélectionnez vos préférences et listez vos allergies ou restrictions.';

  @override
  String get commonDietaryPreferencesTitle =>
      'Préférences Alimentaires Courantes (Optionnel) :';

  @override
  String get commonAllergiesTitle =>
      'Allergies/Intolérances Courantes (Optionnel) :';

  @override
  String get otherRestrictionsTitle =>
      'Autres Notes/Restrictions (Optionnel) :';

  @override
  String get otherRestrictionsLabel =>
      'Autres Notes ou Restrictions Alimentaires';

  @override
  String get otherRestrictionsHint =>
      'Ex., faible en sodium, éviter les plats épicés, aversions spécifiques';

  @override
  String get savePreferencesButton =>
      'Enregistrer les Préférences et Continuer';

  @override
  String get dietaryPreferencesSaved =>
      'Préférences alimentaires enregistrées !';

  @override
  String failedToSavePreferences(String error) {
    return 'Échec de l\'enregistrement des préférences : $error';
  }

  @override
  String get none => 'Aucune';

  @override
  String get logMealHeadline => 'Qu\'avez-vous mangé ?';

  @override
  String get mealDescriptionLabel => 'Description du repas';

  @override
  String get mealDescriptionHint =>
      'Ex., Salade de poulet grillé, Tranches de pomme';

  @override
  String get pleaseEnterMealDescription =>
      'Veuillez entrer une description du repas';

  @override
  String get descriptionTooShort => 'La description semble trop courte';

  @override
  String descriptionTooLong(String maxLength) {
    return 'Description trop longue (max $maxLength caractères)';
  }

  @override
  String get dateLabel => 'Date';

  @override
  String get timeLabel => 'Heure';

  @override
  String get caloriesLabelKcal => 'Calories (kcal)';

  @override
  String get caloriesHint => 'Ex., 350';

  @override
  String get pleaseEnterCalories => 'Veuillez entrer les calories';

  @override
  String get pleaseEnterValidPositiveNumber =>
      'Veuillez entrer un nombre positif valide';

  @override
  String get caloriesTooHighSingleMeal =>
      'Les calories semblent très élevées pour un seul repas';

  @override
  String get proteinLabelG => 'Protéines (g)';

  @override
  String get proteinHint => 'Ex., 30';

  @override
  String get enterProteinOrZero => 'Entrez les protéines (0 si aucune)';

  @override
  String get invalidAmount => 'Montant invalide';

  @override
  String get proteinTooHigh => 'Les protéines semblent très élevées';

  @override
  String get carbsLabelG => 'Glucides (g)';

  @override
  String get carbsHint => 'Ex., 45';

  @override
  String get enterCarbsOrZero => 'Entrez les glucides (0 si aucun)';

  @override
  String get carbsTooHigh => 'Les glucides semblent très élevés';

  @override
  String get fatLabelG => 'Lipides (g)';

  @override
  String get fatHint => 'Ex., 15';

  @override
  String get enterFatOrZero => 'Entrez les lipides (0 si aucun)';

  @override
  String get fatTooHigh => 'Les lipides semblent très élevés';

  @override
  String failedToLogMeal(String error) {
    return 'Échec de l\'enregistrement du repas : $error';
  }

  @override
  String get forgotPasswordPrompt =>
      'Entrez votre adresse e-mail ci-dessous et nous vous enverrons un lien pour réinitialiser votre mot de passe.';

  @override
  String get passwordResetEmailSentFeedback =>
      'E-mail de réinitialisation du mot de passe envoyé avec succès. Veuillez vérifier votre boîte de réception (et votre dossier spam).';

  @override
  String get backToSignIn => 'Retour à la connexion';

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
