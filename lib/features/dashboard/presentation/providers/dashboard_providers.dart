import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutrivision/core/providers/auth_providers.dart';
import 'package:nutrivision/core/providers/firebase_providers.dart';

part 'dashboard_providers.freezed.dart';

@freezed
class DashboardState with _$DashboardState {
  const factory DashboardState({
    User? user,
    Map<String, dynamic>? userData,
    @Default(true) bool isLoading,
    DateTime? selectedDisplayDate,
    @Default(0) int displayedConsumedCalories,
    @Default(0.0) double displayedConsumedProtein,
    @Default(0.0) double displayedConsumedCarbs,
    @Default(0.0) double displayedConsumedFat,
    String? errorMessage,
  }) = _DashboardState;
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return DashboardNotifier(userId, ref);
});

class DashboardNotifier extends StateNotifier<DashboardState> {
  final String? _userId;
  final Ref _ref;

  DashboardNotifier(this._userId, this._ref) : super(const DashboardState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    final user = _ref.read(firebaseAuthProvider).currentUser;
    state = state.copyWith(user: user, selectedDisplayDate: DateTime.now());
    if (user != null && _userId != null) {
      await loadDashboardData();
    } else {
      state = state.copyWith(isLoading: false, errorMessage: "User not logged in.");
    }
  }

  Future<void> loadDashboardData() async {
    if (_userId == null) {
      state = state.copyWith(isLoading: false, errorMessage: "User ID is null.");
      return;
    }
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      DocumentSnapshot userDoc = await _ref.read(firebaseFirestoreProvider)
          .collection('users')
          .doc(_userId)
          .get();

      Map<String, dynamic>? userData;
      if (userDoc.exists) {
        userData = userDoc.data() as Map<String, dynamic>?;
      } else {
        state = state.copyWith(isLoading: false, errorMessage: "User data not found!");
        return;
      }
      
      state = state.copyWith(userData: userData);
      await _calculateConsumptionForDate(state.selectedDisplayDate ?? DateTime.now());
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: "Error loading dashboard data: ${e.toString()}");
    }
  }

  Future<void> _calculateConsumptionForDate(DateTime date) async {
    if (_userId == null) {
       state = state.copyWith(errorMessage: "Cannot calculate consumption: User ID is null.");
      return;
    }

    DateTime startOfDay = DateTime(date.year, date.month, date.day);
    DateTime endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    try {
      QuerySnapshot mealSnapshot = await _ref.read(firebaseFirestoreProvider)
          .collection('users')
          .doc(_userId)
          .collection('loggedMeals')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      QuerySnapshot aiMealSnapshot = await _ref.read(firebaseFirestoreProvider)
          .collection('users')
          .doc(_userId)
          .collection('ai_meal_logs')
          .where('loggedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('loggedAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      int calories = 0;
      double protein = 0.0;
      double carbs = 0.0;
      double fat = 0.0;

      for (var doc in mealSnapshot.docs) {
        Map<String, dynamic> mealData = doc.data() as Map<String, dynamic>;
        calories += (mealData['calories'] as num?)?.toInt() ?? 0;
        protein += (mealData['proteinGrams'] as num?)?.toDouble() ?? 0.0;
        carbs += (mealData['carbsGrams'] as num?)?.toDouble() ?? 0.0;
        fat += (mealData['fatGrams'] as num?)?.toDouble() ?? 0.0;
      }

      for (var doc in aiMealSnapshot.docs) {
        Map<String, dynamic> aiMealData = doc.data() as Map<String, dynamic>;
        if (aiMealData['totalNutrition'] != null) {
          Map<String, dynamic> totalNutrition = aiMealData['totalNutrition'] as Map<String, dynamic>;
          calories += (totalNutrition['calories'] as num?)?.toInt() ?? 0;
          protein += (totalNutrition['protein'] as num?)?.toDouble() ?? 0.0;
          carbs += (totalNutrition['carbs'] as num?)?.toDouble() ?? 0.0;
          fat += (totalNutrition['fat'] as num?)?.toDouble() ?? 0.0;
        }
      }
      state = state.copyWith(
        displayedConsumedCalories: calories,
        displayedConsumedProtein: protein,
        displayedConsumedCarbs: carbs,
        displayedConsumedFat: fat,
      );
    } catch (e) {
       state = state.copyWith(errorMessage: "Error calculating consumption: ${e.toString()}");
    }
  }

  void changeDate(DateTime newDate) {
    state = state.copyWith(selectedDisplayDate: newDate);
    _calculateConsumptionForDate(newDate);
  }
  
  void refreshData() {
    loadDashboardData();
  }
}
