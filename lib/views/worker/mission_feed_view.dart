import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/mission_activity_model.dart';
import '../../providers/mission_feed_provider.dart';
import '../../providers/auth_provider.dart';
import '../common/loading_indicator.dart';

class MissionFeedView extends StatefulWidget {
  const MissionFeedView({super.key});

  @override
  State<MissionFeedView> createState() => _MissionFeedViewState();
}

class _MissionFeedViewState extends State<MissionFeedView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MissionFeedProvider>().listenToActivities();
    });

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      context.read<MissionFeedProvider>().loadMoreActivities();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.grey900,
      appBar: AppBar(
        backgroundColor: AppTheme.grey800,
        title: const Text('Mission Feed'),
        elevation: 0,
      ),
      body: Consumer<MissionFeedProvider>(
        builder: (context, feedProvider, child) {
          if (feedProvider.isLoading && feedProvider.activities.isEmpty) {
            return const Center(child: LoadingIndicator());
          }

          if (feedProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${feedProvider.error}',
                    style: TextStyle(color: AppTheme.grey400),
                  ),
                ],
              ),
            );
          }

          if (feedProvider.activities.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.feed_outlined, size: 64, color: AppTheme.grey600),
                  const SizedBox(height: 16),
                  Text(
                    'No activities yet',
                    style: TextStyle(
                      color: AppTheme.grey400,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete missions to see activity here',
                    style: TextStyle(color: AppTheme.grey500, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              feedProvider.listenToActivities();
            },
            color: AppTheme.primaryPurple,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: feedProvider.activities.length,
              itemBuilder: (context, index) {
                final activity = feedProvider.activities[index];
                return _ActivityCard(activity: activity);
              },
            ),
          );
        },
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final MissionActivity activity;

  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUserId = authProvider.currentUser?.id ?? '';
    final isLiked = activity.likedBy.contains(currentUserId);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.grey800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.grey700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryPurple,
                  child: activity.userAvatar != null
                      ? null
                      : Text(
                          activity.userName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatTimestamp(activity.timestamp),
                        style: TextStyle(color: AppTheme.grey400, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Activity content based on type
          _buildActivityContent(),

          // Actions (like, comment)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    context.read<MissionFeedProvider>().toggleLike(
                      activity.id,
                      currentUserId,
                    );
                  },
                  child: Row(
                    children: [
                      Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 20,
                        color: isLiked ? AppTheme.errorRed : AppTheme.grey400,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${activity.likedBy.length}',
                        style: TextStyle(color: AppTheme.grey400, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Row(
                  children: [
                    Icon(
                      Icons.comment_outlined,
                      size: 20,
                      color: AppTheme.grey400,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${activity.commentCount}',
                      style: TextStyle(color: AppTheme.grey400, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityContent() {
    switch (activity.type) {
      case ActivityType.missionCompleted:
        return _MissionCompletedCard(activity: activity);
      case ActivityType.paymentReceived:
        return _PaymentReceivedCard(activity: activity);
      case ActivityType.levelUp:
        return _LevelUpCard(activity: activity);
      case ActivityType.milestoneReached:
        return _MilestoneCard(activity: activity);
      default:
        return _DefaultCard(activity: activity);
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    }
  }
}

class _MissionCompletedCard extends StatelessWidget {
  final MissionActivity activity;

  const _MissionCompletedCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    final missionTitle = activity.data['missionTitle'] ?? 'Unknown Mission';
    final reward = activity.data['reward'] ?? 0;
    final difficulty = activity.data['difficulty'] ?? 1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryPurple.withOpacity(0.1),
            AppTheme.accentBlue.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.successGreen, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Completed a mission!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            missionTitle,
            style: TextStyle(color: AppTheme.grey300, fontSize: 15),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatChip(
                icon: Icons.monetization_on,
                label: '$reward points',
                color: AppTheme.warningYellow,
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.star,
                label: 'Difficulty $difficulty',
                color: AppTheme.accentBlue,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentReceivedCard extends StatelessWidget {
  final MissionActivity activity;

  const _PaymentReceivedCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    final amount = activity.data['amount'] ?? 0;
    final missionTitle = activity.data['missionTitle'] ?? 'Unknown Mission';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.successGreen.withOpacity(0.1),
            AppTheme.warningYellow.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.successGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.attach_money,
              color: AppTheme.successGreen,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Received!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Earned $amount points',
                  style: TextStyle(
                    color: AppTheme.successGreen,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'From: $missionTitle',
                  style: TextStyle(color: AppTheme.grey400, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelUpCard extends StatelessWidget {
  final MissionActivity activity;

  const _LevelUpCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    final newLevel = activity.data['newLevel'] ?? 1;
    final totalXP = activity.data['totalXP'] ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryPurple, AppTheme.accentBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🎉 LEVEL UP!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reached Level $newLevel',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total XP: $totalXP',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  final MissionActivity activity;

  const _MilestoneCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    final milestone = activity.data['milestone'] ?? 'Unknown';
    final count = activity.data['count'] ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.grey700,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.warningYellow.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events, color: AppTheme.warningYellow, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Milestone Reached!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count $milestone',
                  style: TextStyle(
                    color: AppTheme.warningYellow,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DefaultCard extends StatelessWidget {
  final MissionActivity activity;

  const _DefaultCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        'Activity: ${activity.type.name}',
        style: TextStyle(color: AppTheme.grey300),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
