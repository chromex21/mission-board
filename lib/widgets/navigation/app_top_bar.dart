import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/friend_request_model.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final TextEditingController? searchController;
  final Function(String)? onSearchChanged;
  final VoidCallback? onCreateMission;
  final VoidCallback? onProfileTap;
  final bool showMenuButton;

  const AppTopBar({
    super.key,
    required this.title,
    this.searchController,
    this.onSearchChanged,
    this.onCreateMission,
    this.onProfileTap,
    this.showMenuButton = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: AppTheme.grey900,
        border: Border(bottom: BorderSide(color: AppTheme.grey800, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Menu button (mobile only)
          if (showMenuButton) ...[
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
            const SizedBox(width: 12),
          ],

          // Title
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(width: 32),

          // Search bar (hide on mobile if width is constrained)
          if (searchController != null && onSearchChanged != null)
            if (MediaQuery.of(context).size.width > 600)
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search missions...',
                      prefixIcon: Icon(
                        Icons.search,
                        size: 20,
                        color: AppTheme.grey400,
                      ),
                      suffixIcon: searchController!.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                size: 18,
                                color: AppTheme.grey400,
                              ),
                              onPressed: () {
                                searchController!.clear();
                                onSearchChanged!('');
                              },
                              tooltip: 'Clear search',
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.grey800,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.grey700),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.grey700),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppTheme.primaryPurple,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ),
              )
            else
              // Search icon button for mobile
              IconButton(
                icon: Icon(Icons.search, color: AppTheme.grey400),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppTheme.grey900,
                      title: Text('Search Missions'),
                      content: TextField(
                        controller: searchController,
                        onChanged: onSearchChanged,
                        autofocus: true,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search missions...',
                          hintStyle: TextStyle(color: AppTheme.grey400),
                          filled: true,
                          fillColor: AppTheme.grey800,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            searchController!.clear();
                            onSearchChanged!('');
                            Navigator.pop(context);
                          },
                          child: Text('Clear'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Done'),
                        ),
                      ],
                    ),
                  );
                },
                tooltip: 'Search',
              ),

          const Spacer(),

          // Quick action button
          if (onCreateMission != null) ...[
            ElevatedButton.icon(
              onPressed: onCreateMission,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create Mission'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Notifications button
          _NotificationsButton(),
          const SizedBox(width: 12),

          // Profile button
          Tooltip(
            message: 'View profile',
            child: InkWell(
              onTap: onProfileTap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryPurple.withValues(alpha: 0.2),
                  border: Border.all(
                    color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: authProvider.appUser?.photoURL != null
                    ? ClipOval(
                        child: Image.network(
                          authProvider.appUser!.photoURL!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        Icons.person,
                        color: AppTheme.primaryPurple,
                        size: 20,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, _) {
        final unreadCount = notificationProvider.unreadCount;

        return PopupMenuButton<String>(
          offset: const Offset(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: AppTheme.grey800,
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                unreadCount > 0
                    ? Icons.notifications_active
                    : Icons.notifications_outlined,
                color: unreadCount > 0
                    ? AppTheme.primaryPurple
                    : AppTheme.grey400,
                size: 24,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
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
                ),
            ],
          ),
          itemBuilder: (context) {
            final notifications = notificationProvider.notifications
                .take(5)
                .toList();

            if (notifications.isEmpty) {
              return [
                PopupMenuItem<String>(
                  enabled: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 48,
                            color: AppTheme.grey600,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No notifications',
                            style: TextStyle(color: AppTheme.grey400),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ];
            }

            return [
              ...notifications.map(
                (notif) => PopupMenuItem<String>(
                  value: notif.id,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        _getNotificationIcon(notif.type),
                        color: notif.isRead
                            ? AppTheme.grey400
                            : AppTheme.primaryPurple,
                        size: 20,
                      ),
                      title: Text(
                        notif.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: notif.isRead
                              ? FontWeight.normal
                              : FontWeight.w600,
                          color: notif.isRead ? AppTheme.grey400 : Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        notif.message,
                        style: TextStyle(fontSize: 12, color: AppTheme.grey400),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'view_all',
                child: Center(
                  child: Text(
                    'View All Notifications',
                    style: TextStyle(
                      color: AppTheme.primaryPurple,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ];
          },
          onSelected: (value) {
            if (value == 'view_all') {
              Navigator.pushNamed(context, '/notifications');
            } else {
              // Mark as read and navigate
              notificationProvider.markAsRead(value);
            }
          },
        );
      },
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.missionAssigned:
        return Icons.assignment_turned_in;
      case NotificationType.missionCompleted:
        return Icons.check_circle;
      case NotificationType.friendRequest:
        return Icons.person_add;
      case NotificationType.friendRequestAccepted:
        return Icons.people;
      case NotificationType.newMessage:
        return Icons.chat_bubble;
      case NotificationType.achievementUnlocked:
        return Icons.emoji_events;
      case NotificationType.levelUp:
        return Icons.trending_up;
      case NotificationType.missionApproved:
        return Icons.check_circle_outline;
    }
  }
}
