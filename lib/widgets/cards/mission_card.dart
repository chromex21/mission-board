import 'package:flutter/material.dart';
import '../../models/mission_model.dart';
import '../../routes/app_routes.dart';
import '../../core/theme/app_theme.dart';

class MissionCard extends StatelessWidget {
  final Mission mission;
  const MissionCard({super.key, required this.mission});

  Color _getStatusColor() {
    switch (mission.status) {
      case MissionStatus.open:
        return AppTheme.successGreen;
      case MissionStatus.assigned:
        return AppTheme.infoBlue;
      case MissionStatus.pendingReview:
        return AppTheme.warningOrange;
      case MissionStatus.completed:
        return AppTheme.grey600;
    }
  }

  String _getStatusLabel() {
    switch (mission.status) {
      case MissionStatus.open:
        return 'OPEN';
      case MissionStatus.assigned:
        return 'IN PROGRESS';
      case MissionStatus.pendingReview:
        return 'PENDING REVIEW';
      case MissionStatus.completed:
        return 'COMPLETED';
    }
  }

  String _getDifficultyLabel() {
    final stars = '⭐' * mission.difficulty;
    return stars;
  }

  String _getTimeAgo() {
    final now = DateTime.now();
    final created = mission.createdAt ?? now;
    final diff = now.difference(created);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Semantics(
      label:
          '${mission.title}, ${_getStatusLabel()}, ${mission.reward} points, $_getDifficultyLabel(), $_getTimeAgo()',
      button: true,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.grey900,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.grey700),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.missionDetail,
              arguments: mission,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        _getStatusLabel(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Tooltip(
                      message: 'Reward Points',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.stars_rounded,
                            size: 14,
                            color: AppTheme.primaryPurple,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${mission.reward}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  mission.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (mission.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    mission.description,
                    style: TextStyle(fontSize: 12, color: AppTheme.grey400),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 11, color: AppTheme.grey600),
                    const SizedBox(width: 4),
                    Text(
                      _getTimeAgo(),
                      style: TextStyle(fontSize: 10, color: AppTheme.grey200),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _getDifficultyLabel(),
                      style: TextStyle(fontSize: 11, color: AppTheme.grey200),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppTheme.grey600,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
