import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/friends_provider.dart';
import '../../models/friend_request_model.dart';
import '../../services/sound_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/layout/app_layout.dart';
import '../../utils/responsive_helper.dart';

class NotificationsScreen extends StatefulWidget {
  final Function(String)? onNavigate;

  const NotificationsScreen({super.key, this.onNavigate});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.appUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view notifications')),
      );
    }

    return AppLayout(
      currentRoute: '/notifications',
      title: 'Notifications',
      onNavigate: widget.onNavigate ?? (route) {},
      child: ResponsiveContent(
        maxWidth: AppSizing.maxContentWidth(context),
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Container(
                color: AppTheme.grey900,
                child: TabBar(
                  indicatorColor: AppTheme.primaryPurple,
                  labelColor: AppTheme.primaryPurple,
                  unselectedLabelColor: AppTheme.grey400,
                  tabs: const [
                    Tab(text: 'Friend Requests'),
                    Tab(text: 'All Notifications'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildFriendRequestsTab(context, currentUser.uid),
                    _buildNotificationsTab(context, currentUser.uid),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFriendRequestsTab(BuildContext context, String userId) {
    final friendsProvider = Provider.of<FriendsProvider>(context);

    return StreamBuilder<List<FriendRequest>>(
      stream: friendsProvider.streamFriendRequests(userId),
      builder: (context, snapshot) {
        debugPrint(
          '📬 Friend Requests Stream - State: ${snapshot.connectionState}',
        );
        debugPrint(
          '   Has Data: ${snapshot.hasData}, Count: ${snapshot.data?.length ?? 0}',
        );
        debugPrint(
          '   Has Error: ${snapshot.hasError}, Error: ${snapshot.error}',
        );

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Loading friend requests...',
                  style: TextStyle(color: AppTheme.grey400),
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
                Icon(Icons.error_outline, size: 64, color: AppTheme.errorRed),
                const SizedBox(height: 16),
                Text(
                  'Error Loading Requests',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.grey400,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(fontSize: 12, color: AppTheme.grey600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: AppTheme.grey600),
                const SizedBox(height: 16),
                Text(
                  'No pending friend requests',
                  style: TextStyle(fontSize: 16, color: AppTheme.grey400),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: AppPadding.page(context),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return _buildFriendRequestCard(context, request);
          },
        );
      },
    );
  }

  Widget _buildFriendRequestCard(BuildContext context, FriendRequest request) {
    final friendsProvider = Provider.of<FriendsProvider>(
      context,
      listen: false,
    );
    final soundService = Provider.of<SoundService>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.grey900,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              backgroundColor: AppTheme.primaryPurple.withValues(alpha: 0.2),
              radius: 24,
              child: Text(
                request.senderName[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryPurple,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.senderName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sent ${_formatTime(request.createdAt)}',
                    style: TextStyle(fontSize: 12, color: AppTheme.grey400),
                  ),
                ],
              ),
            ),

            // Actions
            Row(
              children: [
                IconButton(
                  onPressed: () async {
                    try {
                      await friendsProvider.acceptFriendRequest(
                        request.id,
                        authProvider.appUser!.uid,
                      );
                      soundService.play(SoundEffect.success);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Now friends with ${request.senderName}!',
                            ),
                            backgroundColor: AppTheme.successGreen,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to accept: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.check_circle),
                  color: AppTheme.successGreen,
                  tooltip: 'Accept',
                ),
                IconButton(
                  onPressed: () async {
                    try {
                      await friendsProvider.rejectFriendRequest(request.id);
                      soundService.play(SoundEffect.error);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to reject: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.cancel),
                  color: Colors.red,
                  tooltip: 'Reject',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsTab(BuildContext context, String userId) {
    final notificationProvider = Provider.of<NotificationProvider>(context);

    return StreamBuilder<List<AppNotification>>(
      stream: notificationProvider.streamNotifications(userId),
      builder: (context, snapshot) {
        debugPrint(
          '🔔 All Notifications Stream - State: ${snapshot.connectionState}',
        );
        debugPrint('   User ID: $userId');
        debugPrint(
          '   Has Data: ${snapshot.hasData}, Count: ${snapshot.data?.length ?? 0}',
        );
        debugPrint(
          '   Has Error: ${snapshot.hasError}, Error: ${snapshot.error}',
        );
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          debugPrint('   First notification: ${snapshot.data!.first.title}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading notifications: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final notifications = snapshot.data ?? [];

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 64,
                  color: AppTheme.grey600,
                ),
                const SizedBox(height: 16),
                Text(
                  'No notifications yet',
                  style: TextStyle(fontSize: 16, color: AppTheme.grey400),
                ),
                const SizedBox(height: 8),
                Text(
                  'You\'ll see notifications here when you receive them',
                  style: TextStyle(fontSize: 14, color: AppTheme.grey600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: AppPadding.page(context),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return _buildNotificationCard(context, notification);
          },
        );
      },
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    AppNotification notification,
  ) {
    final notificationProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        notificationProvider.deleteNotification(notification.id);
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        color: notification.isRead ? AppTheme.grey900 : AppTheme.grey800,
        child: ListTile(
          leading: Icon(
            _getNotificationIcon(notification.type),
            color: _getNotificationColor(notification.type),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight: notification.isRead
                  ? FontWeight.normal
                  : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notification.message),
              const SizedBox(height: 4),
              Text(
                _formatTime(notification.createdAt),
                style: TextStyle(fontSize: 11, color: AppTheme.grey400),
              ),
            ],
          ),
          onTap: () {
            if (!notification.isRead) {
              notificationProvider.markAsRead(notification.id);
            }
          },
        ),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.friendRequest:
        return Icons.person_add;
      case NotificationType.friendRequestAccepted:
        return Icons.people;
      case NotificationType.newMessage:
        return Icons.chat_bubble;
      case NotificationType.missionCompleted:
        return Icons.check_circle;
      case NotificationType.missionAssigned:
        return Icons.assignment;
      case NotificationType.missionApproved:
        return Icons.verified;
      case NotificationType.achievementUnlocked:
        return Icons.emoji_events;
      case NotificationType.levelUp:
        return Icons.trending_up;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.friendRequest:
      case NotificationType.friendRequestAccepted:
        return AppTheme.infoBlue;
      case NotificationType.newMessage:
        return AppTheme.primaryPurple;
      case NotificationType.missionCompleted:
      case NotificationType.missionApproved:
        return AppTheme.successGreen;
      case NotificationType.missionAssigned:
        return AppTheme.infoBlue;
      case NotificationType.achievementUnlocked:
      case NotificationType.levelUp:
        return AppTheme.primaryPurple;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat.MMMd().format(time);
    }
  }
}
