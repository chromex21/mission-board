import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/layout/app_layout.dart';
import '../../widgets/lobby/lobby_widget.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../utils/responsive_helper.dart';

class LobbyScreen extends StatelessWidget {
  final Function(String)? onNavigate;

  const LobbyScreen({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);

    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return AppLayout(
      currentRoute: '/lobby',
      title: 'Lobby',
      onNavigate: onNavigate ?? (route) {},
      onProfileTap: () => Navigator.pushNamed(context, '/profile'),
      child: Stack(
        children: [
          // Main content
          isMobile
              ? const LobbyWidget()
              : Row(
                  children: [
                    // Chat area (takes 70% of space)
                    const Expanded(flex: 7, child: LobbyWidget()),

                    // Active users sidebar (takes 30% of space)
                    Expanded(
                      flex: 3,
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(0, 20, 20, 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.grey900 : AppTheme.lightCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? AppTheme.grey700
                                : AppTheme.lightBorder,
                          ),
                        ),
                        child: const _ActiveUsersPanel(),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}

class _ActiveUsersPanel extends StatelessWidget {
  const _ActiveUsersPanel();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final textColor = isDark ? Colors.white : AppTheme.lightText;
    final subtextColor = isDark ? AppTheme.grey400 : AppTheme.lightSubtext;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.people, size: 20, color: AppTheme.successGreen),
            const SizedBox(width: 8),
            Text(
              'Active Users',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Online indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.successGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.successGreen.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.successGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'You are online',
                style: TextStyle(
                  color: AppTheme.successGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: authProvider.streamOnlineUsers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(
                        'Loading users...',
                        style: TextStyle(color: subtextColor, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 40,
                        color: AppTheme.errorRed,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Error loading users',
                        style: TextStyle(color: subtextColor, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }

              final users = snapshot.data ?? [];
              final onlineUsers = users
                  .where((u) => u['isOnline'] == true)
                  .toList();

              if (onlineUsers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 48,
                        color: isDark ? AppTheme.grey600 : AppTheme.lightBorder,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No one else online',
                        style: TextStyle(color: subtextColor, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: onlineUsers.length,
                itemBuilder: (context, index) {
                  final user = onlineUsers[index];
                  final isCurrentUser =
                      user['uid'] == authProvider.appUser?.uid;

                  if (isCurrentUser) return const SizedBox.shrink();

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    onTap: () {
                      // Navigate to user profile when clicked
                      Navigator.pushNamed(
                        context,
                        '/user-profile',
                        arguments: user['uid'],
                      );
                    },
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.primaryPurple.withValues(
                            alpha: 0.2,
                          ),
                          child: Text(
                            (user['displayName'] ?? 'U')[0].toUpperCase(),
                            style: TextStyle(
                              color: AppTheme.primaryPurple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppTheme.successGreen,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? AppTheme.grey900
                                    : AppTheme.lightCard,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    title: Text(
                      user['displayName'] ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      user['role'] == 'admin' ? 'Admin' : 'Agent',
                      style: TextStyle(
                        fontSize: 12,
                        color: user['role'] == 'admin'
                            ? AppTheme.primaryPurple
                            : AppTheme.successGreen,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
