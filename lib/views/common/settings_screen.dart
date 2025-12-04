import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/layout/app_layout.dart';
import '../../utils/responsive_helper.dart';
import '../../utils/cleanup_demo_data.dart';
import '../../services/update_service.dart';

class SettingsScreen extends StatelessWidget {
  final Function(String)? onNavigate;
  const SettingsScreen({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();

    return AppLayout(
      title: 'Settings',
      currentRoute: '/settings',
      onNavigate: onNavigate ?? (_) {},
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: AppSizing.maxContentWidth(context),
          ),
          child: ListView(
            children: [
              const _SectionHeader(title: 'Account'),
              _buildCard(
                context,
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.lock_outline,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    title: const Text('Change Password'),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => _showChangePasswordDialog(context, auth),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      Icons.admin_panel_settings_outlined,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    title: const Text('Role'),
                    subtitle: Text(
                      auth.isAdmin ? 'Administrator' : 'Agent',
                      style: TextStyle(
                        color: auth.isAdmin
                            ? Theme.of(context).colorScheme.primary
                            : AppTheme.successGreen,
                      ),
                    ),
                    trailing: const Icon(Icons.swap_horiz, size: 20),
                    onTap: () => _showRoleSwitchDialog(context, auth),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const _SectionHeader(title: 'Theme'),
              _buildCard(
                context,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _ThemeChip(
                          label: 'Dark',
                          selected: theme.currentTheme == AppThemeMode.dark,
                          onTap: () => theme.setThemeMode(AppThemeMode.dark),
                        ),
                        _ThemeChip(
                          label: 'Blue Aurora',
                          selected: theme.currentTheme == AppThemeMode.blue,
                          onTap: () => theme.setThemeMode(AppThemeMode.blue),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const _SectionHeader(title: 'About'),
              _buildCard(
                context,
                children: [
                  ListTile(
                    leading: Icon(Icons.info_outline),
                    title: const Text('Version'),
                    subtitle: const Text('1.2.0'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      Icons.system_update,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    title: const Text('Check for Updates'),
                    subtitle: const Text('Get the latest version'),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => _checkForUpdates(context),
                  ),
                  if (auth.appUser?.role == UserRole.admin) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.delete_sweep,
                        color: AppTheme.warningOrange,
                      ),
                      title: const Text('Clean Demo Data'),
                      subtitle: const Text('Remove test activities from feed'),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => _cleanupDemoData(context),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await auth.signOut();
                    if (context.mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        AppTheme.errorRed, // Keep error red for logout
                    side: const BorderSide(color: AppTheme.errorRed),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(children: children),
    );
  }

  void _showChangePasswordDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Change Password'),
        content: Text(
          'A password reset link will be sent to ${auth.user?.email ?? 'your email'}',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodySmall?.color,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final email = auth.user?.email ?? '';
                await auth.sendPasswordReset(email);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password reset email sent!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  void _checkForUpdates(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final updateInfo = await UpdateService.checkForUpdate();

      if (!context.mounted) return;
      navigator.pop(); // Close loading dialog

      if (updateInfo != null) {
        await UpdateService.showUpdateDialog(context, updateInfo);
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('You\'re on the latest version!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      navigator.pop(); // Close loading dialog
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error checking for updates: $e'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  Future<void> _cleanupDemoData(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Row(
          children: [
            Icon(Icons.warning, color: AppTheme.warningOrange),
            const SizedBox(width: 8),
            const Text('Clean Demo Data'),
          ],
        ),
        content: const Text(
          'This will permanently delete all demo activities from the Mission Feed. '
          'This action cannot be undone.\n\n'
          'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => navigator.pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningOrange,
            ),
            child: const Text('Clean Data'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.warningOrange),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Cleaning demo data...'),
            ),
          ],
        ),
      ),
    );

    try {
      final deletedCount = await DemoDataCleanup.cleanupDemoActivities();

      if (!context.mounted) return;
      navigator.pop(); // Close loading dialog

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            deletedCount > 0
                ? 'Successfully deleted $deletedCount demo activities'
                : 'No demo data found - database is clean',
          ),
          backgroundColor: AppTheme.successGreen,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      navigator.pop(); // Close loading dialog
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error cleaning demo data: $e'),
          backgroundColor: AppTheme.errorRed,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _showRoleSwitchDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.grey800,
        title: const Text('Switch Role'),
        content: Text(
          'Switch to ${auth.isAdmin ? 'Agent' : 'Administrator'} role?',
          style: TextStyle(color: AppTheme.grey400, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await auth.switchRole();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Switched to ${auth.isAdmin ? 'Administrator' : 'Agent'} role',
                    ),
                  ),
                );
              }
            },
            child: const Text('Switch'),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
