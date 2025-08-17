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
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Consumer2<AuthProvider, UserProvider>(
        builder: (context, authProvider, userProvider, child) {
          final userProfile = userProvider.currentUser;
          
          // Show loading while checking authentication
          if (authProvider.status == AuthStatus.unknown || authProvider.status == AuthStatus.loading) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.primary.withOpacity(0.1),
                    colorScheme.surface,
                  ],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          // Check if user is authenticated
          if (authProvider.status == AuthStatus.unauthenticated || !authProvider.isAuthenticated) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.primary.withOpacity(0.1),
                    colorScheme.surface,
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Symbols.account_circle,
                      size: 64,
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Please log in to view your account',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // Enhanced App Bar with Profile Header
              SliverAppBar(
                expandedHeight: 320.0,
                pinned: true,
                backgroundColor: colorScheme.surface,
                surfaceTintColor: colorScheme.surfaceTint,
                elevation: 0,
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
                title: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    'Account',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Symbols.edit,
                        color: colorScheme.primary,
                      ),
                      onPressed: () => _navigateToEditProfile(context),
                    ),
                  ),
                ],
              ),
              
              // Menu Options
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      _buildMenuSection(),
                      const SizedBox(height: 32),
                      _buildAppSection(),
                      const SizedBox(height: 32),
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
    final colorScheme = Theme.of(context).colorScheme;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          height: constraints.maxHeight,
          padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary,
                colorScheme.secondary,
                colorScheme.primary.withOpacity(0.8),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.max,
            children: [
              // Profile Avatar
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white.withOpacity(0.9),
                  child: Icon(
                    Symbols.person,
                    size: 32,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // User Name
              Text(
                user.name.isNotEmpty ? user.name : 'Guest User',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              // User Email
              Text(
                user.email.isNotEmpty ? user.email : 'guest@example.com',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              
              // Points Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Symbols.star,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      children: [
                        Text(
                          '${user.points}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Points',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
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
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface,
            colorScheme.surface.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface,
            colorScheme.surface.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.red.shade50,
            Colors.red.shade50.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.red.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuTile(
            icon: Symbols.logout,
            title: 'Sign Out',
            subtitle: 'Sign out of your account',
            titleColor: Colors.red.shade700,
            onTap: () => _handleSignOut(context, authProvider),
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
    final colorScheme = Theme.of(context).colorScheme;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      (titleColor ?? colorScheme.primary).withOpacity(0.1),
                      (titleColor ?? colorScheme.primary).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (titleColor ?? colorScheme.primary).withOpacity(0.2),
                  ),
                ),
                child: Icon(
                  icon,
                  color: titleColor ?? colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: titleColor ?? colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Symbols.chevron_right,
                  color: colorScheme.onSurface.withOpacity(0.6),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            colorScheme.outline.withOpacity(0.2),
            Colors.transparent,
          ],
        ),
      ),
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