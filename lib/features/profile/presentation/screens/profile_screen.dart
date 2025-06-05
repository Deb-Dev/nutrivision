import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrivision/signin_screen.dart';
import 'package:nutrivision/core/providers/firebase_providers.dart';
import 'package:nutrivision/dietary_preferences_screen.dart';
import 'package:nutrivision/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../features/settings/presentation/screens/font_settings_screen.dart';
import '../../../../features/settings/presentation/screens/font_demo_screen.dart';

/// Profile screen for user account management
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(firebaseAuthProvider).currentUser;

      if (user != null) {
        DocumentSnapshot userDoc = await ref
            .read(firebaseFirestoreProvider)
            .collection('users')
            .doc(user.uid)
            .get();

        if (mounted && userDoc.exists) {
          setState(() {
            _userData = userDoc.data() as Map<String, dynamic>?;
            _isLoading = false;
          });
        } else if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await ref.read(firebaseAuthProvider).signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SignInScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final user = ref.watch(firebaseAuthProvider).currentUser;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.profileTitle ?? 'Profile'),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle ?? 'Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User profile header
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userData?['name'] ??
                        user?.displayName ??
                        user?.email ??
                        l10n.userGeneric ??
                        'User',
                    style: theme.textTheme.titleLarge,
                  ),
                  Text(
                    user?.email ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Profile options
            _buildProfileOption(
              context,
              icon: Icons.person,
              title: l10n.editProfile ?? 'Edit Profile',
              onTap: () {
                // Navigate to edit profile screen
              },
            ),

            _buildProfileOption(
              context,
              icon: Icons.restaurant_menu,
              title: l10n.dietaryPreferences ?? 'Dietary Preferences',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DietaryPreferencesScreen(),
                  ),
                );
              },
            ),

            _buildProfileOption(
              context,
              icon: Icons.font_download,
              title: 'Font Settings',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FontSettingsScreen(),
                  ),
                );
              },
            ),

            _buildProfileOption(
              context,
              icon: Icons.style,
              title: 'Font Demo & Experimentation',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FontDemoScreen(),
                  ),
                );
              },
            ),

            _buildProfileOption(
              context,
              icon: Icons.settings,
              title: l10n.appSettings ?? 'App Settings',
              onTap: () {
                // Navigate to app settings
              },
            ),

            _buildProfileOption(
              context,
              icon: Icons.sync,
              title: l10n.connectHealthApps ?? 'Connect Health Apps',
              onTap: () {
                // Navigate to health app connection screen
              },
            ),

            _buildProfileOption(
              context,
              icon: Icons.help_outline,
              title: l10n.helpSupport ?? 'Help & Support',
              onTap: () {
                // Navigate to help & support screen
              },
            ),

            const SizedBox(height: 16),

            // Sign out button
            _buildProfileOption(
              context,
              icon: Icons.logout,
              title: l10n.signOut ?? 'Sign Out',
              isDestructive: true,
              onTap: () => _signOut(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: isDestructive
          ? Colors.red.withOpacity(0.1)
          : Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? Colors.red : Theme.of(context).primaryColor,
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: isDestructive ? Colors.red : null,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }
}
