import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/mission_provider.dart';
import '../../models/mission_model.dart';
import '../../core/theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../widgets/layout/app_layout.dart';
import '../../utils/notification_helper.dart';

class AdminPanelScreen extends StatelessWidget {
  final Function(String)? onNavigate;

  const AdminPanelScreen({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final missionProvider = Provider.of<MissionProvider>(context);

    final pendingMissions = missionProvider.missions
        .where((m) => m.status == MissionStatus.pendingReview)
        .toList();

    return AppLayout(
      currentRoute: '/admin',
      title: 'Admin Panel',
      onNavigate: onNavigate ?? (route) {},
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            children: [
              // Header with create button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppTheme.grey700, width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          size: 24,
                          color: AppTheme.primaryPurple,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Admin Panel',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.white,
                              ),
                            ),
                            Text(
                              'Review and manage missions',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.grey400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: pendingMissions.isEmpty
                                ? AppTheme.successGreen.withValues(alpha: 0.15)
                                : AppTheme.warningOrange.withValues(
                                    alpha: 0.15,
                                  ),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: pendingMissions.isEmpty
                                  ? AppTheme.successGreen.withValues(alpha: 0.3)
                                  : AppTheme.warningOrange.withValues(
                                      alpha: 0.3,
                                    ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                pendingMissions.isEmpty
                                    ? Icons.check_circle
                                    : Icons.pending_actions,
                                size: 14,
                                color: pendingMissions.isEmpty
                                    ? AppTheme.successGreen
                                    : AppTheme.warningOrange,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${pendingMissions.length} Pending Review${pendingMissions.length == 1 ? '' : 's'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: pendingMissions.isEmpty
                                      ? AppTheme.successGreen
                                      : AppTheme.warningOrange,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        PopupMenuButton<String>(
                          tooltip: 'Create new mission',
                          onSelected: (value) {
                            if (value == 'team') {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.createTeamMission,
                              );
                            } else {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.createMission,
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'team',
                              child: Row(
                                children: [
                                  Icon(Icons.groups, size: 18),
                                  SizedBox(width: 12),
                                  Text('Team Mission'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'personal',
                              child: Row(
                                children: [
                                  Icon(Icons.person, size: 18),
                                  SizedBox(width: 12),
                                  Text('Personal Mission'),
                                ],
                              ),
                            ),
                          ],
                          child: ElevatedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Create Mission'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryPurple,
                              disabledBackgroundColor: AppTheme.primaryPurple,
                              foregroundColor: Colors.white,
                              disabledForegroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Pending reviews list
              Expanded(
                child: pendingMissions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 64,
                              color: AppTheme.successGreen,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'All Caught Up!',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No missions pending review',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.grey400,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(20),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 32,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.grey900,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.grey700),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Quick Stats',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.white,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildStatItem(
                                        Icons.task_alt,
                                        '${missionProvider.missions.where((m) => m.status == MissionStatus.open).length}',
                                        'Open',
                                        AppTheme.successGreen,
                                      ),
                                      _buildStatItem(
                                        Icons.trending_up,
                                        '${missionProvider.missions.where((m) => m.status == MissionStatus.assigned).length}',
                                        'In Progress',
                                        AppTheme.infoBlue,
                                      ),
                                      _buildStatItem(
                                        Icons.done_all,
                                        '${missionProvider.missions.where((m) => m.status == MissionStatus.completed).length}',
                                        'Completed',
                                        AppTheme.primaryPurple,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: pendingMissions.length,
                        itemBuilder: (context, index) {
                          final mission = pendingMissions[index];
                          return _PendingMissionCard(mission: mission);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: AppTheme.grey400)),
      ],
    );
  }
}

class _PendingMissionCard extends StatelessWidget {
  final Mission mission;

  const _PendingMissionCard({required this.mission});

  @override
  Widget build(BuildContext context) {
    final missionProvider = Provider.of<MissionProvider>(
      context,
      listen: false,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.grey900,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.warningOrange.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                    color: AppTheme.warningOrange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppTheme.warningOrange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.pending,
                        size: 12,
                        color: AppTheme.warningOrange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'PENDING REVIEW',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.warningOrange,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.stars_rounded,
                  size: 14,
                  color: AppTheme.primaryPurple,
                ),
                const SizedBox(width: 4),
                Text(
                  '${mission.reward} pts',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.grey200,
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
            if (mission.proofNote != null && mission.proofNote!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.grey800,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.grey700),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note_outlined,
                      size: 14,
                      color: AppTheme.grey400,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        mission.proofNote!,
                        style: TextStyle(fontSize: 11, color: AppTheme.grey200),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        await missionProvider.rejectMission(mission.id);
                        if (context.mounted) {
                          context.showInfo(
                            'Mission rejected and returned to worker',
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          context.showError('Error: ${e.toString()}');
                        }
                      }
                    },
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorRed,
                      side: BorderSide(
                        color: AppTheme.errorRed.withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await missionProvider.approveMission(
                          mission.id,
                          mission.assignedTo!,
                          mission.reward,
                          mission.difficulty,
                        );
                        if (context.mounted) {
                          context.showSuccess(
                            'Approved! +${mission.reward} pts awarded',
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          context.showError('Error: ${e.toString()}');
                        }
                      }
                    },
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve & Award Points'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
                      foregroundColor: AppTheme.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
