// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'NutriVision';

  @override
  String get signUpTitle => 'Registrarse';

  @override
  String get signInTitle => 'Iniciar Sesión';

  @override
  String get emailHint => 'Correo Electrónico';

  @override
  String get passwordHint => 'Contraseña';

  @override
  String get confirmPasswordHint => 'Confirmar Contraseña';

  @override
  String get signUpButton => 'Registrarse';

  @override
  String get signInButton => 'Iniciar Sesión';

  @override
  String get forgotPasswordButton => '¿Olvidaste tu contraseña?';

  @override
  String get alreadyHaveAccount => '¿Ya tienes una cuenta? Inicia Sesión';

  @override
  String get dontHaveAccount => '¿No tienes una cuenta? Regístrate';

  @override
  String get nameHint => 'Nombre';

  @override
  String get ageHint => 'Edad';

  @override
  String get weightHint => 'Peso';

  @override
  String get heightHint => 'Altura';

  @override
  String get activityLevelPrompt => 'Nivel de Actividad';

  @override
  String get goalPrompt => 'Objetivo';

  @override
  String get saveButton => 'Guardar';

  @override
  String get nextButton => 'Siguiente';

  @override
  String get selectDietaryPreferences => 'Seleccionar Preferencias Dietéticas';

  @override
  String get selectAllergies => 'Seleccionar Alergias o Restricciones';

  @override
  String get dashboardTitle => 'Panel de Control';

  @override
  String get logMealButton => 'Registrar Comida';

  @override
  String get previousDay => 'Día Anterior';

  @override
  String get nextDay => 'Día Siguiente';

  @override
  String get calories => 'Calorías';

  @override
  String get protein => 'Proteína';

  @override
  String get carbs => 'Carbohidratos';

  @override
  String get fats => 'Grasas';

  @override
  String get targets => 'Objetivos';

  @override
  String get consumed => 'Consumido';

  @override
  String get remaining => 'Restante';

  @override
  String get mealNameHint => 'Nombre de la Comida (ej. Almuerzo)';

  @override
  String get foodItemHint => 'Alimento';

  @override
  String get quantityHint => 'Cantidad (ej. 100g o 1 taza)';

  @override
  String get addFoodItemButton => 'Añadir Alimento';

  @override
  String get submitMealButton => 'Enviar Comida';

  @override
  String get forgotPasswordTitle => 'Olvidé mi Contraseña';

  @override
  String get sendResetLinkButton => 'Enviar Enlace de Restablecimiento';

  @override
  String get passwordResetEmailSent =>
      'Correo de restablecimiento de contraseña enviado. Por favor, revisa tu bandeja de entrada.';

  @override
  String get errorOccurred =>
      'Ocurrió un error. Por favor, inténtalo de nuevo.';

  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden.';

  @override
  String get weakPassword => 'La contraseña debe tener al menos 6 caracteres.';

  @override
  String get invalidEmail => 'Dirección de correo electrónico inválida.';

  @override
  String get userNotFound => 'Usuario no encontrado.';

  @override
  String get wrongPassword => 'Contraseña incorrecta.';

  @override
  String welcomeMessage(String userName) {
    return 'Bienvenido $userName';
  }

  @override
  String get termsAndConditions => 'Términos y Condiciones';

  @override
  String get privacyPolicy => 'Política de Privacidad';

  @override
  String iAgreeToThe(String terms, String privacyPolicy) {
    return 'Acepto los $terms y la $privacyPolicy';
  }

  @override
  String get pleaseAgreeToTerms =>
      'Por favor, acepta los términos y la política de privacidad.';

  @override
  String get male => 'Masculino';

  @override
  String get female => 'Femenino';

  @override
  String get sexPrompt => 'Sexo';

  @override
  String get heightUnitPrompt => 'Unidad de Altura';

  @override
  String get weightUnitPrompt => 'Unidad de Peso';

  @override
  String get cm => 'cm';

  @override
  String get inches => 'pulgadas';

  @override
  String get kg => 'kg';

  @override
  String get lbs => 'libras';

  @override
  String get bmr => 'TMB';

  @override
  String get tdee => 'GETD';

  @override
  String get macronutrientTargets => 'Objetivos de Macronutrientes';

  @override
  String get profileSetupTitle => 'Configuración de Perfil';

  @override
  String get dietaryPreferencesTitle => 'Preferencias Dietéticas';

  @override
  String get logMealTitle => 'Registrar Comida';

  @override
  String get viewProfile => 'Ver Perfil';

  @override
  String get editProfile => 'Editar Perfil';

  @override
  String get signOut => 'Cerrar Sesión';

  @override
  String get profile => 'Perfil';

  @override
  String get settings => 'Ajustes';

  @override
  String get searchFood => 'Buscar Alimento (ej. Manzana)';

  @override
  String get addSelectedFood => 'Añadir Alimento Seleccionado';

  @override
  String get noResultsFound => 'No se encontraron resultados.';

  @override
  String get search => 'Buscar';

  @override
  String get servingSize => 'Tamaño de la Porción';

  @override
  String get caloriesPerServing => 'Calorías por porción';

  @override
  String get proteinPerServing => 'Proteína por porción';

  @override
  String get carbsPerServing => 'Carbohidratos por porción';

  @override
  String get fatsPerServing => 'Grasas por porción';

  @override
  String get manualEntry => 'Entrada Manual';

  @override
  String get scanBarcode => 'Escanear Código de Barras (¡Próximamente!)';

  @override
  String get recentMeals => 'Comidas Recientes';

  @override
  String get quickAdd => 'Añadir Rápido';

  @override
  String get waterIntake => 'Consumo de Agua';

  @override
  String get addWater => 'Añadir Agua (ml)';

  @override
  String waterGoal(int goal) {
    return 'Meta de Agua: $goal ml';
  }

  @override
  String waterConsumed(int consumed) {
    return 'Consumido: $consumed ml';
  }

  @override
  String get selectLanguage => 'Seleccionar Idioma';

  @override
  String get english => 'Inglés';

  @override
  String get spanish => 'Español';

  @override
  String get french => 'Francés';

  @override
  String get language => 'Idioma';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get enableNotifications => 'Activar Notificaciones';

  @override
  String get theme => 'Tema';

  @override
  String get lightTheme => 'Tema Claro';

  @override
  String get darkTheme => 'Tema Oscuro';

  @override
  String get systemTheme => 'Tema del Sistema';

  @override
  String get account => 'Cuenta';

  @override
  String get deleteAccount => 'Eliminar Cuenta';

  @override
  String get confirmDeleteAccount =>
      '¿Estás seguro de que quieres eliminar tu cuenta? Esta acción no se puede deshacer.';

  @override
  String get delete => 'Eliminar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get reauthenticateToDelete =>
      'Por favor, inicia sesión de nuevo para eliminar tu cuenta.';

  @override
  String get profileUpdatedSuccessfully => '¡Perfil actualizado con éxito!';

  @override
  String get mealLoggedSuccessfully => '¡Comida registrada con éxito!';

  @override
  String get dataSavedSuccessfully => '¡Datos guardados con éxito!';

  @override
  String get requiredField => 'Este campo es obligatorio.';

  @override
  String get invalidNumber => 'Por favor, introduce un número válido.';

  @override
  String minAge(int min) {
    return 'La edad debe ser de al menos $min años.';
  }

  @override
  String maxAge(int max) {
    return 'La edad debe ser como máximo $max años.';
  }

  @override
  String minWeight(double min, String unit) {
    return 'El peso debe ser de al menos $min $unit.';
  }

  @override
  String maxWeight(double max, String unit) {
    return 'El peso debe ser como máximo $max $unit.';
  }

  @override
  String minHeight(double min, String unit) {
    return 'La altura debe ser de al menos $min $unit.';
  }

  @override
  String maxHeight(double max, String unit) {
    return 'La altura debe ser como máximo $max $unit.';
  }

  @override
  String get sedentary => 'Sedentario (poco o ningún ejercicio)';

  @override
  String get lightlyActive =>
      'Ligeramente activo (ejercicio ligero/deportes 1-3 días/semana)';

  @override
  String get moderatelyActive =>
      'Moderadamente activo (ejercicio moderado/deportes 3-5 días/semana)';

  @override
  String get veryActive =>
      'Muy activo (ejercicio intenso/deportes 6-7 días a la semana)';

  @override
  String get extraActive =>
      'Extra activo (ejercicio muy intenso/deportes y trabajo físico o doble entrenamiento)';

  @override
  String get maintainWeight => 'Mantener peso';

  @override
  String get mildWeightLoss => 'Pérdida de peso leve (0.25 kg/semana)';

  @override
  String get weightLoss => 'Pérdida de peso (0.5 kg/semana)';

  @override
  String get extremeWeightLoss => 'Pérdida de peso extrema (1 kg/semana)';

  @override
  String get mildWeightGain => 'Aumento de peso leve (0.25 kg/semana)';

  @override
  String get weightGain => 'Aumento de peso (0.5 kg/semana)';

  @override
  String get extremeWeightGain => 'Aumento de peso extremo (1 kg/semana)';

  @override
  String get vegetarian => 'Vegetariano';

  @override
  String get vegan => 'Vegano';

  @override
  String get pescatarian => 'Pescatariano';

  @override
  String get glutenFree => 'Sin Gluten';

  @override
  String get dairyFree => 'Sin Lácteos';

  @override
  String get keto => 'Keto';

  @override
  String get paleo => 'Paleo';

  @override
  String get lowCarb => 'Bajo en Carbohidratos';

  @override
  String get lowFat => 'Bajo en Grasas';

  @override
  String get highProtein => 'Alto en Proteínas';

  @override
  String get nuts => 'Frutos Secos';

  @override
  String get shellfish => 'Mariscos';

  @override
  String get soy => 'Soja';

  @override
  String get eggs => 'Huevos';

  @override
  String get fish => 'Pescado';

  @override
  String get other => 'Otro';

  @override
  String get needsUppercaseLetter => 'Necesita mayúscula';

  @override
  String get needsLowercaseLetter => 'Necesita minúscula';

  @override
  String get needsNumber => 'Necesita un número';

  @override
  String get needsSpecialCharacter => 'Necesita un carácter especial';

  @override
  String get strongPassword => 'Contraseña segura';

  @override
  String get chooseStrongerPassword =>
      'Por favor, elige una contraseña más segura según los criterios.';

  @override
  String get emailAlreadyInUse =>
      'Ya existe una cuenta para este correo. Por favor, inicia sesión.';

  @override
  String get createAccountJourney =>
      'Crea una cuenta para comenzar tu viaje nutricional.';

  @override
  String get pleaseEnterEmail => 'Por favor, introduce tu correo electrónico';

  @override
  String get pleaseEnterPassword => 'Por favor, introduce tu contraseña';

  @override
  String get pleaseConfirmPassword => 'Por favor, confirma tu contraseña';

  @override
  String get passwordTooShort => 'Demasiado corta (mín. 8 caracteres)';

  @override
  String get passwordCriteriaNotMet =>
      'Por favor, asegúrate de que tu contraseña cumple todos los criterios.';

  @override
  String get welcomeToNutrivision => '¡Bienvenido a NutriVision!';

  @override
  String get createAccountToStart =>
      'Crea una cuenta para comenzar tu viaje nutricional.';

  @override
  String get emailExample => 'tu@ejemplo.com';

  @override
  String get tellUsAboutYourself => 'Cuéntanos un poco sobre ti';

  @override
  String get helpsCalculateNeeds =>
      'Esto nos ayuda a calcular tus necesidades nutricionales.';

  @override
  String get nameExample => 'Ej., Alex Pérez';

  @override
  String get pleaseEnterName => 'Por favor, introduce tu nombre';

  @override
  String get nameTooShort =>
      'El nombre parece demasiado corto (mín. 2 caracteres)';

  @override
  String get ageExample => 'Ej., 30';

  @override
  String get pleaseEnterAge => 'Por favor, introduce tu edad';

  @override
  String get unrealisticAge =>
      'Por favor, introduce una edad realista (13-100 años)';

  @override
  String get weightExample => 'Ej., 70';

  @override
  String get pleaseEnterWeight => 'Por favor, introduce tu peso';

  @override
  String get invalidPositiveWeight =>
      'Por favor, introduce un peso positivo válido';

  @override
  String get weightTooHigh =>
      'El peso parece demasiado alto, por favor verifica';

  @override
  String get heightExampleCm => 'Ej., 175';

  @override
  String get heightExampleFtIn => 'Ej., 5.10 (5 pies 10 pulgadas)';

  @override
  String get pleaseEnterHeight => 'Por favor, introduce tu altura';

  @override
  String get invalidPositiveHeight =>
      'Por favor, introduce una altura positiva válida';

  @override
  String get heightFtInFormatHint => 'Usa . para pies-pulgadas (ej., 5.10)';

  @override
  String get invalidFtInFormat => 'Formato pies-pulgadas inválido (ej., 5.10)';

  @override
  String get validFtInExample =>
      'Pies-pulgadas válido: ej., 5.10 (0-11 pulgadas)';

  @override
  String get heightTooHigh =>
      'La altura parece demasiado alta, por favor verifica';

  @override
  String get heightTooHighCm => 'La altura parece demasiado alta (máx. 300cm)';

  @override
  String get heightTooLowCm => 'La altura parece demasiado baja (mín. 50cm)';

  @override
  String get pleaseSelectBiologicalSex =>
      'Por favor, selecciona tu sexo biológico';

  @override
  String get pleaseSelectActivityLevel =>
      'Por favor, selecciona tu nivel de actividad';

  @override
  String get pleaseSelectDietaryGoal =>
      'Por favor, selecciona tu objetivo dietético principal';

  @override
  String get errorNoUserLoggedIn =>
      'Error: Ningún usuario ha iniciado sesión. Por favor, inicia sesión de nuevo.';

  @override
  String get profileSavedSuccessProfileSetup =>
      '¡Perfil y objetivos nutricionales guardados! Siguiente: Preferencias Dietéticas.';

  @override
  String get failedToSaveProfile =>
      'Error al guardar el perfil. Por favor, inténtalo de nuevo.';

  @override
  String get ftIn => 'pies-pulgadas';

  @override
  String get otherBiologicalSex => 'Otro';

  @override
  String get loseWeightGoal => 'Perder Peso';

  @override
  String get gainMuscleGoal => 'Ganar Músculo';

  @override
  String get improveHealthGoal => 'Mejorar la Salud';

  @override
  String get refreshData => 'Actualizar Datos';

  @override
  String get couldNotLoadUserData =>
      'No se pudieron cargar los datos del usuario. Por favor, inténtalo de nuevo.';

  @override
  String get retryButton => 'Reintentar';

  @override
  String get userGeneric => 'Usuario';

  @override
  String welcomeBackMessage(String userName) {
    return '¡Bienvenido de nuevo, $userName!';
  }

  @override
  String get todaysSummary => 'Resumen de Hoy';

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
  String get logNewMealButton => 'Registrar Nueva Comida';

  @override
  String get navigateToEditProfilePlaceholder =>
      'Navegar a Editar Perfil/Preferencias - PENDIENTE';

  @override
  String get editProfilePreferencesButton => 'Editar Perfil y Preferencias';

  @override
  String summaryForDate(String date) {
    return 'Resumen para $date';
  }

  @override
  String get dietaryPreferencesHeadline =>
      '¡Ayúdanos a personalizar tu experiencia!';

  @override
  String get dietaryPreferencesSubheadline =>
      'Selecciona cualquier preferencia y enumera alergias o restricciones.';

  @override
  String get commonDietaryPreferencesTitle =>
      'Preferencias Dietéticas Comunes (Opcional):';

  @override
  String get commonAllergiesTitle =>
      'Alergias/Intolerancias Comunes (Opcional):';

  @override
  String get otherRestrictionsTitle => 'Otras Notas/Restricciones (Opcional):';

  @override
  String get otherRestrictionsLabel => 'Otras Notas o Restricciones Dietéticas';

  @override
  String get otherRestrictionsHint =>
      'Ej., bajo en sodio, evitar comida picante, aversiones específicas';

  @override
  String get savePreferencesButton => 'Guardar Preferencias y Continuar';

  @override
  String get dietaryPreferencesSaved => '¡Preferencias dietéticas guardadas!';

  @override
  String failedToSavePreferences(String error) {
    return 'Error al guardar las preferencias: $error';
  }

  @override
  String get none => 'Ninguna';

  @override
  String get logMealHeadline => '¿Qué comiste?';

  @override
  String get mealDescriptionLabel => 'Descripción de la Comida';

  @override
  String get mealDescriptionHint =>
      'Ej., Ensalada de pollo a la parrilla, Rodajas de manzana';

  @override
  String get pleaseEnterMealDescription =>
      'Por favor, introduce una descripción de la comida';

  @override
  String get descriptionTooShort => 'La descripción parece demasiado corta';

  @override
  String descriptionTooLong(String maxLength) {
    return 'Descripción demasiado larga (máx. $maxLength caracteres)';
  }

  @override
  String get dateLabel => 'Fecha';

  @override
  String get timeLabel => 'Hora';

  @override
  String get caloriesLabelKcal => 'Calorías (kcal)';

  @override
  String get caloriesHint => 'Ej., 350';

  @override
  String get pleaseEnterCalories => 'Por favor, introduce las calorías';

  @override
  String get pleaseEnterValidPositiveNumber =>
      'Por favor, introduce un número positivo válido';

  @override
  String get caloriesTooHighSingleMeal =>
      'Las calorías parecen muy altas para una sola comida';

  @override
  String get proteinLabelG => 'Proteína (g)';

  @override
  String get proteinHint => 'Ej., 30';

  @override
  String get enterProteinOrZero => 'Introduce proteína (0 si no hay)';

  @override
  String get invalidAmount => 'Cantidad inválida';

  @override
  String get proteinTooHigh => 'La proteína parece muy alta';

  @override
  String get carbsLabelG => 'Carbohidratos (g)';

  @override
  String get carbsHint => 'Ej., 45';

  @override
  String get enterCarbsOrZero => 'Introduce carbohidratos (0 si no hay)';

  @override
  String get carbsTooHigh => 'Los carbohidratos parecen muy altos';

  @override
  String get fatLabelG => 'Grasa (g)';

  @override
  String get fatHint => 'Ej., 15';

  @override
  String get enterFatOrZero => 'Introduce grasa (0 si no hay)';

  @override
  String get fatTooHigh => 'La grasa parece muy alta';

  @override
  String failedToLogMeal(String error) {
    return 'Error al registrar la comida: $error';
  }

  @override
  String get forgotPasswordPrompt =>
      'Introduce tu dirección de correo electrónico a continuación y te enviaremos un enlace para restablecer tu contraseña.';

  @override
  String get passwordResetEmailSentFeedback =>
      'Correo electrónico de restablecimiento de contraseña enviado con éxito. Por favor, revisa tu bandeja de entrada (y la carpeta de spam).';

  @override
  String get backToSignIn => 'Volver a Iniciar Sesión';

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
