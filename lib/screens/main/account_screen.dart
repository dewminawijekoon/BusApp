import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../../config/app_theme.dart';
import '../../config/app_routes.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Consumer2<AuthProvider, UserProvider>(
        builder: (context, authProvider, userProvider, child) {
          final userProfile = userProvider.currentUser;
          
          // Show loading while checking authentication
          if (authProvider.status == AuthStatus.unknown || authProvider.status == AuthStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          // Check if user is authenticated
          if (authProvider.status == AuthStatus.unauthenticated || !authProvider.isAuthenticated) {
            return const Center(
              child: Text('Please log in to view your account'),
            );
          }

          return CustomScrollView(
            slivers: [
              // Custom App Bar with Profile Header
              SliverAppBar(
                expandedHeight: 280.0, // Further increased height to eliminate remaining overflow
                pinned: true,
                backgroundColor: AppTheme.primaryColor,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildProfileHeader(
                    userProfile ?? authProvider.currentUser ?? UserModel(
                      uid: '',
                      email: '',
                      name: 'Guest User',
                      points: 0,
                      savedRoutes: [],
                      recentRoutes: [],
                      createdAt: DateTime.now(),
                    )
                  ),
                ),
                title: Text(
                  'Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      Symbols.edit,
                      color: Colors.white,
                    ),
                    onPressed: () => _navigateToEditProfile(context),
                  ),
                ],
              ),
              
              // Menu Options
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildMenuSection(),
                      const SizedBox(height: 24),
                      _buildAppSection(),
                      const SizedBox(height: 24),
                      _buildDangerSection(context, authProvider),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          height: constraints.maxHeight, // Ensure it matches the FlexibleSpaceBar's height
          padding: const EdgeInsets.fromLTRB(16, 80, 16, 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withOpacity(0.8),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.max,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Icon(
                  Symbols.person,
                  size: 28,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                user.name.isNotEmpty ? user.name : 'Guest User',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                user.email.isNotEmpty ? user.email : 'No email',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Symbols.star,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${user.points} Points',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildMenuTile(
            icon: Symbols.route,
            title: 'Saved Routes',
            subtitle: 'View and manage your favorite routes',
            onTap: () => _navigateToSavedRoutes(context),
          ),
          _buildDivider(),
          _buildMenuTile(
            icon: Symbols.star,
            title: 'Points & Rewards',
            subtitle: 'Check your points balance and rewards',
            onTap: () => _navigateToPoints(context),
          ),
          _buildDivider(),
          _buildMenuTile(
            icon: Symbols.history,
            title: 'Journey History',
            subtitle: 'View your past journeys',
            onTap: () => _navigateToJourneyHistory(context),
          ),
          _buildDivider(),
          _buildMenuTile(
            icon: Symbols.notifications,
            title: 'Notifications',
            subtitle: 'Manage your notification preferences',
            onTap: () => _navigateToNotificationSettings(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAppSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildMenuTile(
            icon: Symbols.settings,
            title: 'App Settings',
            subtitle: 'Configure app preferences',
            onTap: () => _navigateToAppSettings(context),
          ),
          _buildDivider(),
          _buildMenuTile(
            icon: Symbols.help,
            title: 'Help & Support',
            subtitle: 'Get help or contact support',
            onTap: () => _navigateToHelpSupport(context),
          ),
          _buildDivider(),
          _buildMenuTile(
            icon: Symbols.info,
            title: 'About',
            subtitle: 'App version and information',
            onTap: () => _showAboutDialog(context),
          ),
          _buildDivider(),
          _buildMenuTile(
            icon: Symbols.privacy_tip,
            title: 'Privacy Policy',
            subtitle: 'View our privacy policy',
            onTap: () => _navigateToPrivacyPolicy(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerSection(BuildContext context, AuthProvider authProvider) {
    return Card(
      elevation: 2,
      color: Colors.red.shade50, // Light red background instead of dark
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.red.shade200, // Lighter border color
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildMenuTile(
            icon: Symbols.logout,
            title: 'Sign Out',
            subtitle: 'Sign out of your account',
            titleColor: Colors.red.shade700, // Better contrast red
            onTap: () => _handleSignOut(context, authProvider),
          ),
          _buildDivider(),
          _buildMenuTile(
            icon: Symbols.delete_forever,
            title: 'Delete Account',
            subtitle: 'Permanently delete your account',
            titleColor: Colors.red.shade700, // Better contrast red
            onTap: () => _showDeleteAccountDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: titleColor != null 
              ? titleColor.withOpacity(0.1) 
              : AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: titleColor ?? AppTheme.primaryColor,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: titleColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
      trailing: Icon(
        Symbols.chevron_right,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 68,
      endIndent: 20,
      color: Colors.grey[300],
    );
  }

  // Navigation Methods
  void _navigateToEditProfile(BuildContext context) {
    // TODO: Navigate to edit profile screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit Profile - Coming Soon')),
    );
  }

  void _navigateToSavedRoutes(BuildContext context) {
    context.go(AppRoutes.savedRoutes);
  }

  void _navigateToPoints(BuildContext context) {
    context.go(AppRoutes.points);
  }

  void _navigateToJourneyHistory(BuildContext context) {
    // TODO: Navigate to journey history screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Journey History - Coming Soon')),
    );
  }

  void _navigateToNotificationSettings(BuildContext context) {
    // TODO: Navigate to notification settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification Settings - Coming Soon')),
    );
  }

  void _navigateToAppSettings(BuildContext context) {
    context.go(AppRoutes.settings);
  }

  void _navigateToHelpSupport(BuildContext context) {
    context.go(AppRoutes.helpSupport);
  }

  void _navigateToPrivacyPolicy(BuildContext context) {
    // TODO: Navigate to privacy policy
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Privacy Policy - Coming Soon')),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'TransitTracker',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Symbols.directions_bus,
          color: Colors.white,
          size: 24,
        ),
      ),
      children: [
        Text(
          'A comprehensive public transportation app with real-time tracking, route planning, and crowd-sourced bus location sharing.',
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // Action Methods
  Future<void> _handleSignOut(BuildContext context, AuthProvider authProvider) async {
    final confirmed = await _showConfirmationDialog(
      context,
      'Sign Out',
      'Are you sure you want to sign out?',
    );

    if (confirmed == true) {
      try {
        await authProvider.signOut();
        if (mounted) {
          // Navigate to login screen after successful sign out
          context.go(AppRoutes.login);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Signed out successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to sign out: ${e.toString()}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Symbols.warning,
                color: AppTheme.errorColor,
              ),
              const SizedBox(width: 8),
              const Text('Delete Account'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This action cannot be undone. All your data including:',
              ),
              const SizedBox(height: 8),
              Text(
                '• Saved routes\n'
                '• Journey history\n'
                '• Points and rewards\n'
                '• Profile information',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              const Text('will be permanently deleted.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Implement account deletion
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account deletion - Coming Soon'),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showConfirmationDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }
}