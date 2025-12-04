import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/messaging_provider.dart';

class AppSidebar extends StatefulWidget {
  final String currentRoute;
  final Function(String) onNavigate;

  const AppSidebar({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  bool _isExpanded = true;
  // ignore: unused_field
  bool _isHistoryExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final borderColor = theme.brightness == Brightness.dark
        ? primary.withValues(alpha: 0.2)
        : AppTheme.grey800;
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.isAdmin;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _isExpanded ? 240 : 72,
      decoration: BoxDecoration(
        color: theme.drawerTheme.backgroundColor ?? AppTheme.grey900,
        border: Border(right: BorderSide(color: borderColor, width: 1)),
      ),
      child: Column(
        children: [
          // Sidebar header with logo and collapse button
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor, width: 1)),
            ),
            child: Row(
              children: [
                if (_isExpanded) ...[
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [primary, primary.withValues(alpha: 0.7)],
                            ),
                          ),
                          child: const Icon(
                            Icons.stars,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Flexible(
                          child: Text(
                            'Mission Board',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [primary, primary.withValues(alpha: 0.7)],
                          ),
                        ),
                        child: const Icon(
                          Icons.stars,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.chevron_left : Icons.chevron_right,
                    color: AppTheme.grey400,
                  ),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                      if (!_isExpanded) {
                        _isHistoryExpanded = false;
                      }
                    });
                    // Close drawer if in mobile mode
                    if (MediaQuery.of(context).size.width < 900) {
                      Navigator.of(context).pop();
                    }
                  },
                  tooltip: _isExpanded ? 'Collapse sidebar' : 'Expand sidebar',
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildNavItem(
                  icon: Icons.feed_outlined,
                  activeIcon: Icons.feed,
                  label: 'Mission Feed',
                  route: '/mission-feed',
                ),
                _buildNavItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  label: 'Missions',
                  route: '/missions',
                ),

                _buildNavItem(
                  icon: Icons.people_outline,
                  activeIcon: Icons.people,
                  label: 'Teams',
                  route: '/teams',
                ),

                _buildNavItem(
                  icon: Icons.leaderboard_outlined,
                  activeIcon: Icons.leaderboard,
                  label: 'Leaderboard',
                  route: '/leaderboard',
                ),

                _buildNavItem(
                  icon: Icons.forum_outlined,
                  activeIcon: Icons.forum,
                  label: 'Lobby',
                  route: '/lobby',
                ),

                _buildMessagesNavItem(
                  icon: Icons.chat_bubble_outline,
                  activeIcon: Icons.chat_bubble,
                  label: 'Messages',
                  route: '/messages',
                ),

                if (isAdmin) ...[
                  const SizedBox(height: 16),
                  if (_isExpanded)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        'ADMIN',
                        style: TextStyle(
                          color: AppTheme.grey400,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  _buildNavItem(
                    icon: Icons.admin_panel_settings_outlined,
                    activeIcon: Icons.admin_panel_settings,
                    label: 'Admin Panel',
                    route: '/admin',
                  ),
                ],

                const SizedBox(height: 16),
                if (_isExpanded)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      'ACCOUNT',
                      style: TextStyle(
                        color: AppTheme.grey400,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                _buildNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profile',
                  route: '/profile',
                ),

                _buildNavItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  label: 'Settings',
                  route: '/settings',
                ),
              ],
            ),
          ),

          // User info at bottom
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: borderColor, width: 1)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    if (_isExpanded)
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primary.withValues(alpha: 0.2),
                        ),
                        child: authProvider.appUser?.photoURL != null
                            ? ClipOval(
                                child: Image.network(
                                  authProvider.appUser!.photoURL!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(
                                        Icons.person,
                                        color: primary,
                                        size: 20,
                                      ),
                                ),
                              )
                            : Icon(Icons.person, color: primary, size: 20),
                      )
                    else
                      Center(
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primary.withValues(alpha: 0.2),
                          ),
                          child: Icon(Icons.person, color: primary, size: 18),
                        ),
                      ),
                    if (_isExpanded) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              authProvider.appUser?.displayName ??
                                  authProvider.appUser?.username ??
                                  'User',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              authProvider.isAdmin ? 'Admin' : 'Agent',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                // Logout button
                InkWell(
                  onTap: () async {
                    await authProvider.signOut();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _isExpanded ? 12 : 4,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.errorRed.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.logout,
                          color: AppTheme.errorRed,
                          size: _isExpanded ? 18 : 16,
                        ),
                        if (_isExpanded) ...[
                          const SizedBox(width: 12),
                          const Flexible(
                            child: Text(
                              'Logout',
                              style: TextStyle(
                                color: AppTheme.errorRed,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required String route,
    bool hasSubItems = false,
  }) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isActive =
        widget.currentRoute == route ||
        (hasSubItems && widget.currentRoute.startsWith(route));

    return Tooltip(
      message: _isExpanded ? '' : label,
      waitDuration: const Duration(milliseconds: 500),
      child: InkWell(
        onTap: () => widget.onNavigate(route),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: EdgeInsets.symmetric(
            horizontal: _isExpanded ? 12 : 4,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: _isExpanded
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isActive ? activeIcon : icon,
                      color: isActive ? primary : AppTheme.grey400,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isActive ? Colors.white : AppTheme.grey400,
                          fontSize: 14,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Icon(
                    isActive ? activeIcon : icon,
                    color: isActive ? primary : AppTheme.grey400,
                    size: 20,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildNavItemWithBadge({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required String route,
  }) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isActive = widget.currentRoute == route;

    return Tooltip(
      message: _isExpanded ? '' : label,
      waitDuration: const Duration(milliseconds: 500),
      child: InkWell(
        onTap: () => widget.onNavigate(route),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: EdgeInsets.symmetric(
            horizontal: _isExpanded ? 12 : 4,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: _isExpanded
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            isActive ? activeIcon : icon,
                            color: isActive ? primary : AppTheme.grey400,
                            size: 20,
                          ),
                          // Badge for unread notifications
                          Consumer<NotificationProvider>(
                            builder: (context, notificationProvider, _) {
                              final unreadCount =
                                  notificationProvider.unreadCount;
                              if (unreadCount == 0) {
                                return const SizedBox.shrink();
                              }

                              return Positioned(
                                right: -8,
                                top: -8,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.errorRed,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppTheme.grey900,
                                      width: 1,
                                    ),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: FittedBox(
                                    child: Text(
                                      unreadCount > 9 ? '9+' : '$unreadCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isActive ? Colors.white : AppTheme.grey400,
                          fontSize: 14,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              : Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          isActive ? activeIcon : icon,
                          color: isActive ? primary : AppTheme.grey400,
                          size: 20,
                        ),
                        // Badge for unread notifications
                        Consumer<NotificationProvider>(
                          builder: (context, notificationProvider, _) {
                            final unreadCount =
                                notificationProvider.unreadCount;
                            if (unreadCount == 0) {
                              return const SizedBox.shrink();
                            }

                            return Positioned(
                              right: -6,
                              top: -6,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: AppTheme.errorRed,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.grey900,
                                    width: 1,
                                  ),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 14,
                                  minHeight: 14,
                                ),
                                child: FittedBox(
                                  child: Text(
                                    unreadCount > 9 ? '9+' : '$unreadCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildMessagesNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required String route,
  }) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isActive = widget.currentRoute == route;
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.user?.uid;

    if (currentUserId == null) {
      return _buildNavItem(
        icon: icon,
        activeIcon: activeIcon,
        label: label,
        route: route,
      );
    }

    return Tooltip(
      message: _isExpanded ? '' : label,
      waitDuration: const Duration(milliseconds: 500),
      child: InkWell(
        onTap: () => widget.onNavigate(route),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: EdgeInsets.symmetric(
            horizontal: _isExpanded ? 12 : 4,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: _isExpanded
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            isActive ? activeIcon : icon,
                            color: isActive ? primary : AppTheme.grey400,
                            size: 20,
                          ),
                          // Badge for unread messages
                          Consumer<MessagingProvider>(
                            builder: (context, messagingProvider, _) {
                              final unreadCount = messagingProvider
                                  .getTotalUnreadCount(currentUserId);
                              if (unreadCount == 0) {
                                return const SizedBox.shrink();
                              }

                              return Positioned(
                                right: -8,
                                top: -8,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.errorRed,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppTheme.grey900,
                                      width: 1,
                                    ),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: FittedBox(
                                    child: Text(
                                      unreadCount > 9 ? '9+' : '$unreadCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isActive ? Colors.white : AppTheme.grey400,
                          fontSize: 14,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              : Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          isActive ? activeIcon : icon,
                          color: isActive ? primary : AppTheme.grey400,
                          size: 20,
                        ),
                        // Badge for unread messages (collapsed view)
                        Consumer<MessagingProvider>(
                          builder: (context, messagingProvider, _) {
                            final unreadCount = messagingProvider
                                .getTotalUnreadCount(currentUserId);
                            if (unreadCount == 0) {
                              return const SizedBox.shrink();
                            }

                            return Positioned(
                              right: -6,
                              top: -6,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: AppTheme.errorRed,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.grey900,
                                    width: 1,
                                  ),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 14,
                                  minHeight: 14,
                                ),
                                child: FittedBox(
                                  child: Text(
                                    unreadCount > 9 ? '9+' : '$unreadCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
