import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/messaging_provider.dart';
import '../../providers/friends_provider.dart';
import '../../providers/block_report_provider.dart';
import '../../services/sound_service.dart';
import '../../utils/permissions.dart';
import '../../views/common/message_thread_screen.dart';
import '../../views/common/full_profile_screen.dart';

class UserProfileDialog extends StatelessWidget {
  final AppUser user;

  const UserProfileDialog({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.appUser;
    final isOwnProfile = currentUser?.uid == user.uid;

    return Dialog(
      backgroundColor: AppTheme.darkGrey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Back button at top left
            if (!isOwnProfile)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                      color: Colors.white,
                      iconSize: 24,
                      tooltip: 'Back',
                    ),
                  ],
                ),
              ),
            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with avatar
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppTheme.primaryPurple, AppTheme.infoBlue],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          (user.displayName ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name
                    Text(
                      user.displayName ?? 'Unknown User',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    // Username (if exists)
                    if (user.username != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '@${user.username}',
                        style: TextStyle(fontSize: 14, color: AppTheme.grey400),
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Role badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Color(
                          int.parse(
                            Permissions.getRoleBadgeColor(
                              user.role,
                            ).replaceAll('#', '0xFF'),
                          ),
                        ).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Color(
                            int.parse(
                              Permissions.getRoleBadgeColor(
                                user.role,
                              ).replaceAll('#', '0xFF'),
                            ),
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            user.role == UserRole.admin
                                ? Icons.admin_panel_settings
                                : Icons.military_tech,
                            size: 16,
                            color: Color(
                              int.parse(
                                Permissions.getRoleBadgeColor(
                                  user.role,
                                ).replaceAll('#', '0xFF'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            Permissions.getRoleDisplayName(user.role),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(
                                int.parse(
                                  Permissions.getRoleBadgeColor(
                                    user.role,
                                  ).replaceAll('#', '0xFF'),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Stats
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.grey900,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.grey700),
                      ),
                      child: Column(
                        children: [
                          _buildStatRow(
                            Icons.stars_rounded,
                            'Total Points',
                            '${user.totalPoints}',
                            AppTheme.primaryPurple,
                          ),
                          const Divider(height: 24, color: AppTheme.grey700),
                          _buildStatRow(
                            Icons.trending_up,
                            'Level',
                            '${user.level}',
                            AppTheme.infoBlue,
                          ),
                          const Divider(height: 24, color: AppTheme.grey700),
                          _buildStatRow(
                            Icons.check_circle,
                            'Completed Missions',
                            '${user.completedMissions}',
                            AppTheme.successGreen,
                          ),
                          const Divider(height: 24, color: AppTheme.grey700),
                          _buildStatRow(
                            Icons.emoji_events,
                            'Rank',
                            AppUser.getRankTitle(user.level),
                            AppTheme.primaryPurple,
                          ),
                        ],
                      ),
                    ),

                    // Bio (if exists)
                    if (user.bio != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.grey900,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          user.bio!,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.grey200,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // View Full Profile Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  FullProfileScreen(user: user),
                            ),
                          );
                        },
                        icon: const Icon(Icons.person_outline, size: 20),
                        label: const Text('View Full Profile'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.infoBlue,
                          side: BorderSide(color: AppTheme.infoBlue, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Action Buttons (only if not own profile)
                    if (!isOwnProfile && currentUser != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _sendFriendRequest(context, currentUser),
                              icon: const Icon(
                                Icons.person_add_outlined,
                                size: 18,
                              ),
                              label: const Text('Add Friend'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryPurple,
                                side: BorderSide(color: AppTheme.primaryPurple),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _startConversation(context, currentUser),
                              icon: const Icon(
                                Icons.chat_bubble_outline,
                                size: 18,
                              ),
                              label: const Text('Message'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                _showUserOptionsMenu(context, currentUser),
                            icon: const Icon(Icons.more_vert),
                            color: AppTheme.grey400,
                          ),
                        ],
                      ),
                    ],

                    // Close button for own profile
                    if (isOwnProfile)
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Close'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: AppTheme.grey400),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Future<void> _startConversation(
    BuildContext context,
    AppUser currentUser,
  ) async {
    final messagingProvider = Provider.of<MessagingProvider>(
      context,
      listen: false,
    );
    final blockReportProvider = Provider.of<BlockReportProvider>(
      context,
      listen: false,
    );
    final soundService = Provider.of<SoundService>(context, listen: false);

    try {
      // Check if user is blocked
      final isBlocked = await blockReportProvider.isUserBlocked(
        currentUser.uid,
        user.uid,
      );

      if (isBlocked) {
        if (context.mounted) {
          Navigator.pop(context); // Close profile dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('You have blocked this user'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
        return;
      }

      // Close profile dialog first to avoid UI freeze
      if (context.mounted) Navigator.pop(context);

      // Show loading in a separate dialog
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Get or create conversation
      final conversationId = await messagingProvider.getOrCreateConversation(
        currentUserId: currentUser.uid,
        otherUserId: user.uid,
        currentUserName: currentUser.displayName ?? 'Unknown',
        otherUserName: user.displayName ?? 'Unknown',
      );

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      // Play sound
      soundService.play(SoundEffect.success);

      // Navigate to message thread
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessageThreadScreen(
              conversationId: conversationId,
              otherUserName: user.displayName ?? 'Unknown',
              otherUserId: user.uid,
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start conversation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendFriendRequest(
    BuildContext context,
    AppUser currentUser,
  ) async {
    final friendsProvider = Provider.of<FriendsProvider>(
      context,
      listen: false,
    );
    final soundService = Provider.of<SoundService>(context, listen: false);

    try {
      await friendsProvider.sendFriendRequest(
        senderId: currentUser.uid,
        senderName: currentUser.displayName ?? 'Unknown',
        receiverId: user.uid,
      );

      soundService.play(SoundEffect.success);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Friend request sent to ${user.displayName}!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showUserOptionsMenu(BuildContext context, AppUser currentUser) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkGrey,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.block, color: AppTheme.errorRed),
              title: const Text(
                'Block User',
                style: TextStyle(color: AppTheme.errorRed),
              ),
              onTap: () {
                Navigator.pop(context);
                _showBlockConfirmation(context, currentUser);
              },
            ),
            ListTile(
              leading: const Icon(Icons.report, color: AppTheme.warningOrange),
              title: const Text(
                'Report User',
                style: TextStyle(color: AppTheme.warningOrange),
              ),
              onTap: () {
                Navigator.pop(context);
                _showReportDialog(context, currentUser);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: AppTheme.grey400),
              title: const Text(
                'Cancel',
                style: TextStyle(color: AppTheme.grey400),
              ),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockConfirmation(BuildContext context, AppUser currentUser) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkGrey,
        title: const Text('Block User?'),
        content: Text(
          'Are you sure you want to block ${user.displayName}? '
          'They won\'t be able to message you or send friend requests.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _blockUser(context, currentUser);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  Future<void> _blockUser(BuildContext context, AppUser currentUser) async {
    final blockReportProvider = Provider.of<BlockReportProvider>(
      context,
      listen: false,
    );
    final soundService = Provider.of<SoundService>(context, listen: false);

    try {
      await blockReportProvider.blockUser(currentUser.uid, user.uid);
      soundService.play(SoundEffect.success);

      if (context.mounted) {
        Navigator.pop(context); // Close profile dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.displayName} has been blocked'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to block user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showReportDialog(BuildContext context, AppUser currentUser) {
    ReportReason selectedReason = ReportReason.spam;
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.darkGrey,
          title: const Text('Report User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report ${user.displayName} for:',
                  style: TextStyle(color: AppTheme.grey400),
                ),
                const SizedBox(height: 16),
                ...ReportReason.values.map((reason) {
                  final isSelected = selectedReason == reason;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        selectedReason = reason;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: isSelected
                                ? AppTheme.primaryPurple
                                : AppTheme.grey400,
                          ),
                          const SizedBox(width: 12),
                          Text(_getReasonLabel(reason)),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Additional details (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                await _submitReport(
                  context,
                  currentUser,
                  selectedReason,
                  descriptionController.text,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warningOrange,
              ),
              child: const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport(
    BuildContext context,
    AppUser currentUser,
    ReportReason reason,
    String description,
  ) async {
    final blockReportProvider = Provider.of<BlockReportProvider>(
      context,
      listen: false,
    );
    final soundService = Provider.of<SoundService>(context, listen: false);

    try {
      await blockReportProvider.reportUser(
        reporterId: currentUser.uid,
        reportedId: user.uid,
        reason: reason,
        description: description,
      );

      soundService.play(SoundEffect.success);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Report submitted successfully. Thank you for helping keep our community safe.',
            ),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getReasonLabel(ReportReason reason) {
    switch (reason) {
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.harassment:
        return 'Harassment or Bullying';
      case ReportReason.inappropriate:
        return 'Inappropriate Content';
      case ReportReason.impersonation:
        return 'Impersonation';
      case ReportReason.other:
        return 'Other';
    }
  }
}
