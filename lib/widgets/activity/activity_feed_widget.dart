import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/activity_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/activity_model.dart';

class ActivityFeedWidget extends StatelessWidget {
  const ActivityFeedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final activityProvider = Provider.of<ActivityProvider>(context);

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.grey900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.grey700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.feed, size: 20, color: AppTheme.primaryPurple),
              const SizedBox(width: 8),
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Flexible(
            child: StreamBuilder<List<Activity>>(
              stream: activityProvider.streamRecentActivities(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading activities',
                      style: TextStyle(color: AppTheme.grey400),
                    ),
                  );
                }

                final activities = snapshot.data ?? [];

                if (activities.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(Icons.inbox, size: 48, color: AppTheme.grey600),
                          const SizedBox(height: 8),
                          Text(
                            'No recent activity',
                            style: TextStyle(
                              color: AppTheme.grey400,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: activities.take(10).length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final activity = activities[index];
                      return _ActivityCard(activity: activity);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Activity activity;

  const _ActivityCard({required this.activity});

  IconData _getIcon() {
    switch (activity.type) {
      case ActivityType.missionCreated:
        return Icons.add_task;
      case ActivityType.missionAccepted:
        return Icons.check_circle_outline;
      case ActivityType.missionCompleted:
        return Icons.stars;
      case ActivityType.teamCreated:
        return Icons.group_add;
      case ActivityType.userJoined:
        return Icons.person_add;
    }
  }

  Color _getColor() {
    switch (activity.type) {
      case ActivityType.missionCreated:
        return AppTheme.infoBlue;
      case ActivityType.missionAccepted:
        return AppTheme.warningOrange;
      case ActivityType.missionCompleted:
        return AppTheme.successGreen;
      case ActivityType.teamCreated:
        return AppTheme.primaryPurple;
      case ActivityType.userJoined:
        return AppTheme.grey600;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${(difference.inDays / 7).floor()}w';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.grey800,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.2),
                ),
                child: activity.userPhotoUrl != null
                    ? ClipOval(
                        child: Image.network(
                          activity.userPhotoUrl!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(_getIcon(), color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.userName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      activity.getDescription(),
                      style: TextStyle(fontSize: 11, color: AppTheme.grey400),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (activity.getSubtitle() != null) ...[
            const SizedBox(height: 8),
            Text(
              activity.getSubtitle()!,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.grey200,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const Spacer(),
          Text(
            _formatTimeAgo(activity.createdAt),
            style: TextStyle(fontSize: 10, color: AppTheme.grey600),
          ),
        ],
      ),
    );
  }
}
