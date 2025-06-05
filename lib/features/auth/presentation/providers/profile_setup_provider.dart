import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrivision/core/providers/firebase_providers.dart';
import 'package:nutrivision/features/auth/presentation/providers/auth_notifier_simple.dart';

/// Provider to check if the user's profile setup is fully completed
/// This checks both basic profile setup and dietary preferences
final profileSetupCompletedProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;

  try {
    final firestore = ref.read(firebaseFirestoreProvider);
    final doc = await firestore.collection('users').doc(user.id).get();

    if (!doc.exists) return false;

    final data = doc.data()!;

    // Check basic profile completion
    final bool profileCompleted = data['profileCompleted'] == true;

    // Check dietary preferences completion
    bool dietaryPreferencesCompleted = false;
    if (data.containsKey('dietary_info')) {
      final dietaryInfo = data['dietary_info'] as Map<String, dynamic>;
      dietaryPreferencesCompleted = dietaryInfo.containsKey(
        'preferencesLastUpdated',
      );
    }

    // User needs to complete both steps
    return profileCompleted && dietaryPreferencesCompleted;
  } catch (e) {
    // Log the error but return false to be safe
    print('Error checking profile setup status: $e');
    return false;
  }
});
