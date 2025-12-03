import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/sound_service.dart';
import '../../services/update_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/layout/app_layout.dart';
import '../../utils/notification_helper.dart';
import '../../utils/responsive_helper.dart';
import '../../utils/demo_data_helper.dart';

class SettingsScreen extends StatefulWidget {
  final Function(String)? onNavigate;

  const SettingsScreen({super.key, this.onNavigate});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;
  bool emailNotifications = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final soundService = Provider.of<SoundService>(context);

    return AppLayout(
      currentRoute: '/settings',
      title: 'Settings',
      onNavigate: widget.onNavigate ?? (route) {},
      child: ResponsiveContent(
        maxWidth: AppSizing.maxContentWidth(context),
        child: ListView(
          padding: AppPadding.page(context),
          children: [
            // Account Section
            _SectionHeader(title: 'Account'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.grey900,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.grey700),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.email_outlined,
                      color: AppTheme.grey200,
                    ),
                    title: const Text('Email'),
                    subtitle: Text(
                      authProvider.user?.email ?? 'Not available',
                      style: TextStyle(color: AppTheme.grey400),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                  ),
                  Divider(height: 1, color: AppTheme.grey700),
                  ListTile(
                    leading: Icon(Icons.lock_outline, color: AppTheme.grey200),
                    title: const Text('Change Password'),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () {
                      _showChangePasswordDialog(context, authProvider);
                    },
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                  ),
                  Divider(height: 1, color: AppTheme.grey700),
                  ListTile(
                    leading: Icon(
                      Icons.admin_panel_settings_outlined,
                      color: AppTheme.grey200,
                    ),
                    title: const Text('Role'),
                    subtitle: Text(
                      authProvider.isAdmin ? 'Administrator' : 'Agent',
                      style: TextStyle(
                        color: authProvider.isAdmin
                            ? AppTheme.primaryPurple
                            : AppTheme.successGreen,
                      ),
                    ),
                    trailing: const Icon(Icons.swap_horiz, size: 20),
                    onTap: () {
                      _showRoleSwitchDialog(context, authProvider);
                    },
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Theme Section
            _SectionHeader(title: 'Theme'),
            _ThemeSelector(),
            const SizedBox(height: 24),

            // Notifications Section
            _SectionHeader(title: 'Notifications'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.grey900,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.grey700),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: Icon(
                      Icons.volume_up_outlined,
                      color: AppTheme.grey200,
                    ),
                    title: const Text('Sound Effects'),
                    subtitle: Text(
                      'Play sounds for missions and achievements',
                      style: TextStyle(fontSize: 12, color: AppTheme.grey400),
                    ),
                    value: soundService.soundEnabled,
                    onChanged: (value) {
                      soundService.toggleSound();
                      soundService.play(SoundEffect.success);
                    },
                    activeThumbColor: AppTheme.primaryPurple,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Demo Data Section
            _SectionHeader(title: 'Demo Data'),
            _DemoDataSection(),
            const SizedBox(height: 24),

            // App Info Section
            _SectionHeader(title: 'App Info'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.grey900,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.grey700),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.system_update_outlined,
                  color: AppTheme.grey200,
                ),
                title: const Text('Check for Updates'),
                subtitle: Text(
                  'Version 1.2.0',
                  style: TextStyle(fontSize: 12, color: AppTheme.grey400),
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => _checkForUpdates(context, authProvider),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Data & Privacy Section
            _SectionHeader(title: 'Data & Privacy'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.grey900,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.grey700),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.download_outlined,
                      color: AppTheme.grey200,
                    ),
                    title: const Text('Export Data'),
                    subtitle: Text(
                      'Download your mission history',
                      style: TextStyle(fontSize: 12, color: AppTheme.grey400),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () {
                      context.showInfo('Export feature coming soon!');
                    },
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                  ),
                  Divider(height: 1, color: AppTheme.grey700),
                  ListTile(
                    leading: Icon(
                      Icons.delete_outline,
                      color: AppTheme.errorRed,
                    ),
                    title: Text(
                      'Delete Account',
                      style: TextStyle(color: AppTheme.errorRed),
                    ),
                    subtitle: Text(
                      'Permanently delete your account',
                      style: TextStyle(fontSize: 12, color: AppTheme.grey400),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: AppTheme.errorRed,
                    ),
                    onTap: () {
                      _showDeleteAccountDialog(context, authProvider);
                    },
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // About Section
            _SectionHeader(title: 'About'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.grey900,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.grey700),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.info_outline, color: AppTheme.grey200),
                    title: const Text('Version'),
                    subtitle: Text(
                      '1.0.0',
                      style: TextStyle(fontSize: 12, color: AppTheme.grey400),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                  ),
                  Divider(height: 1, color: AppTheme.grey700),
                  ListTile(
                    leading: Icon(
                      Icons.description_outlined,
                      color: AppTheme.grey200,
                    ),
                    title: const Text('Terms of Service'),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () {
                      context.showInfo('Terms of Service coming soon!');
                    },
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                  ),
                  Divider(height: 1, color: AppTheme.grey700),
                  ListTile(
                    leading: Icon(
                      Icons.privacy_tip_outlined,
                      color: AppTheme.grey200,
                    ),
                    title: const Text('Privacy Policy'),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () {
                      context.showInfo('Privacy Policy coming soon!');
                    },
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: () async {
                  await authProvider.signOut();
                  if (context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorRed,
                  side: BorderSide(color: AppTheme.errorRed),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.grey800,
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'A password reset link will be sent to ${authProvider.user?.email}',
              style: TextStyle(color: AppTheme.grey400, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await authProvider.sendPasswordReset(
                  authProvider.user?.email ?? '',
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  context.showSuccess('Password reset email sent!');
                }
              } catch (e) {
                if (context.mounted) {
                  context.showError('Error: ${e.toString()}');
                }
              }
            },
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  void _showRoleSwitchDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.grey800,
        title: const Text('Switch Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Current role: ${authProvider.isAdmin ? "Administrator" : "Agent"}',
              style: TextStyle(color: AppTheme.grey400, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              authProvider.isAdmin
                  ? 'Switch to Agent role to accept and complete missions'
                  : 'Switch to Admin role to create missions and manage teams',
              style: TextStyle(color: AppTheme.grey200, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newRole = authProvider.isAdmin ? "Agent" : "Admin";
              try {
                await authProvider.switchRole();
                if (context.mounted) {
                  Navigator.pop(context);
                  context.showSuccess('Role switched to $newRole');
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  context.showError('Failed to switch role: $e');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
            ),
            child: Text(
              'Switch to ${authProvider.isAdmin ? "Agent" : "Admin"}',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkForUpdates(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.primaryPurple),
                const SizedBox(height: 16),
                Text('Checking for updates...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final updateInfo = await UpdateService.checkForUpdate();

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (updateInfo != null) {
        await UpdateService.showUpdateDialog(context, updateInfo);
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.successGreen),
                const SizedBox(width: 8),
                const Text('Up to Date'),
              ],
            ),
            content: const Text(
              'You\'re running the latest version of Mission Board (v1.2.0)!',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog

      context.showError('Failed to check for updates. Please try again later.');
    }
  }

  void _showDeleteAccountDialog(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.grey800,
        title: Text(
          'Delete Account',
          style: TextStyle(color: AppTheme.errorRed),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppTheme.errorRed,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'This action cannot be undone. All your missions, points, and achievements will be permanently deleted.',
              style: TextStyle(color: AppTheme.grey400, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.showInfo('Account deletion feature coming soon!');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: themeProvider.availableThemes.map((theme) {
          final isSelected = themeProvider.currentTheme == theme['mode'];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppTheme.grey900,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppTheme.primaryPurple : AppTheme.grey700,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: ListTile(
              leading: Icon(
                theme['icon'] as IconData,
                color: isSelected ? AppTheme.primaryPurple : AppTheme.grey400,
              ),
              title: Text(
                theme['name'] as String,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.grey200,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(
                theme['description'] as String,
                style: TextStyle(color: AppTheme.grey400, fontSize: 12),
              ),
              trailing: isSelected
                  ? Icon(Icons.check_circle, color: AppTheme.primaryPurple)
                  : null,
              onTap: () => themeProvider.setThemeMode(theme['mode'] as AppThemeMode),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DemoDataSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.grey900,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.grey700),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.group_outlined, color: AppTheme.infoBlue),
            title: const Text('Load Demo Leaderboard'),
            subtitle: Text(
              '5 demo users with rankings',
              style: TextStyle(fontSize: 12, color: AppTheme.grey400),
            ),
            trailing: const Icon(Icons.arrow_forward, size: 20),
            onTap: () async {
              try {
                await DemoDataHelper.populateDemoLeaderboard();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('✅ Demo leaderboard loaded!'),
                      backgroundColor: AppTheme.successGreen,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Error: \$e'),
                      backgroundColor: AppTheme.errorRed,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.grey400,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
