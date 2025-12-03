import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/mission_model.dart';
import '../../providers/mission_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/comment_provider.dart';
import '../../providers/attachment_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/comments/comment_thread_widget.dart';
import '../../widgets/attachments/attachments_widget.dart';
import '../../utils/notification_helper.dart';

class MissionDetailScreen extends StatefulWidget {
  final Mission mission;
  const MissionDetailScreen({super.key, required this.mission});

  @override
  State<MissionDetailScreen> createState() => _MissionDetailScreenState();
}

class _MissionDetailScreenState extends State<MissionDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentProvider = Provider.of<CommentProvider>(context);
    final commentCount = commentProvider.getCommentCount(widget.mission.id);
    final attachmentProvider = Provider.of<AttachmentProvider>(context);
    final attachmentCount = attachmentProvider.getAttachmentCount(
      widget.mission.id,
    );

    return Scaffold(
      backgroundColor: AppTheme.darkGrey,
      appBar: AppBar(
        title: Text(widget.mission.title),
        backgroundColor: AppTheme.grey900,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryPurple,
          labelColor: Colors.white,
          unselectedLabelColor: AppTheme.grey600,
          tabs: [
            const Tab(
              icon: Icon(Icons.info_outline, size: 16),
              text: 'Details',
            ),
            Tab(
              icon: const Icon(Icons.chat_bubble_outline, size: 16),
              text: commentCount > 0 ? 'Comments ($commentCount)' : 'Comments',
            ),
            Tab(
              icon: const Icon(Icons.attach_file, size: 16),
              text: attachmentCount > 0 ? 'Files ($attachmentCount)' : 'Files',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDetailsTab(),
          CommentThreadWidget(missionId: widget.mission.id),
          AttachmentsWidget(missionId: widget.mission.id),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    final missionProvider = Provider.of<MissionProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.uid ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Stats Row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.grey900,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.grey700),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 18,
                        color: AppTheme.infoBlue,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Created',
                        style: TextStyle(fontSize: 10, color: AppTheme.grey400),
                      ),
                      Text(
                        _formatDate(widget.mission.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.grey900,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.grey700),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 18,
                        color: AppTheme.successGreen,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Type',
                        style: TextStyle(fontSize: 10, color: AppTheme.grey400),
                      ),
                      Text(
                        widget.mission.teamId != null ? 'Team' : 'Personal',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Description Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.grey900,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.grey700),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.description,
                      size: 20,
                      color: AppTheme.primaryPurple,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.mission.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.grey200,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Mission Info Cards
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.stars_rounded,
                  label: 'Reward',
                  value: '${widget.mission.reward} pts',
                  color: AppTheme.primaryPurple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.speed,
                  label: 'Difficulty',
                  value: 'Level ${widget.mission.difficulty}',
                  color: AppTheme.infoBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.info_outline,
            label: 'Status',
            value: _getStatusLabel(widget.mission.status),
            color: _getStatusColor(widget.mission.status),
          ),
          const SizedBox(height: 24),
          if (widget.mission.status == MissionStatus.open)
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      try {
                        await missionProvider.assignMission(
                          widget.mission.id,
                          userId,
                        );
                        if (context.mounted) {
                          navigator.pop();
                          // ignore: use_build_context_synchronously
                          context.showSuccess(
                            'Mission accepted! Time to complete it.',
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          String errorMessage = e.toString();
                          if (errorMessage.contains('not available')) {
                            // ignore: use_build_context_synchronously
                            context.showError(
                              'Someone else just accepted this mission. Try another one!',
                            );
                          } else {
                            // ignore: use_build_context_synchronously
                            context.showError(
                              'Could not accept mission. Please try again.',
                            );
                          }
                        }
                      }
                    },
                    icon: const Icon(Icons.rocket_launch, size: 20),
                    label: const Text('Accept & Start Mission'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryPurple,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (widget.mission.status == MissionStatus.assigned &&
              widget.mission.assignedTo == userId)
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      // Show dialog for proof note
                      final proofNote = await showDialog<String>(
                        context: context,
                        builder: (ctx) {
                          final controller = TextEditingController();
                          return AlertDialog(
                            title: const Text('Complete Mission'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Add a note about your completion (optional):',
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: controller,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    hintText: 'What did you accomplish?',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(null),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.of(
                                  ctx,
                                ).pop(controller.text.trim()),
                                child: const Text('Submit for Review'),
                              ),
                            ],
                          );
                        },
                      );

                      if (proofNote == null) return;

                      try {
                        await missionProvider.completeMission(
                          widget.mission.id,
                          userId,
                          proofNote: proofNote.isEmpty ? null : proofNote,
                        );
                        if (context.mounted) {
                          navigator.pop();
                          // ignore: use_build_context_synchronously
                          context.showSuccess('Submitted for admin review!');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          // ignore: use_build_context_synchronously
                          context.showError('Error: ${e.toString()}');
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      backgroundColor: AppTheme.successGreen,
                    ),
                    child: const Text('Mark as Complete'),
                  ),
                ),
              ),
            ),
          if (widget.mission.status == MissionStatus.pendingReview &&
              widget.mission.assignedTo == userId)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                border: Border.all(color: Colors.orange[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.pending, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Awaiting admin review...',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.grey900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.grey700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.grey400,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.white,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(MissionStatus status) {
    switch (status) {
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

  String _getStatusLabel(MissionStatus status) {
    switch (status) {
      case MissionStatus.open:
        return 'Open';
      case MissionStatus.assigned:
        return 'In Progress';
      case MissionStatus.pendingReview:
        return 'Pending Review';
      case MissionStatus.completed:
        return 'Completed';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.month}/${date.day}';
  }
}
