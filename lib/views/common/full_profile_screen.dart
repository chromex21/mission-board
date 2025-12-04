import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/messaging_provider.dart';
import '../../providers/friends_provider.dart';
import '../../providers/block_report_provider.dart';
import '../../utils/permissions.dart';
import '../../widgets/common/custom_notification_banner.dart';
import '../common/message_thread_screen.dart';

class FullProfileScreen extends StatefulWidget {
  final AppUser user;

  const FullProfileScreen({super.key, required this.user});

  @override
  State<FullProfileScreen> createState() => _FullProfileScreenState();
}

class _FullProfileScreenState extends State<FullProfileScreen>
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
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.appUser;
    final isOwnProfile = currentUser?.uid == widget.user.uid;

    return Scaffold(
      backgroundColor: AppTheme.darkGrey,
      body: CustomScrollView(
        slivers: [
          // Header with gradient
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppTheme.grey900,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primaryPurple, AppTheme.infoBlue],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    // Avatar
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.3),
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: Center(
                        child: Text(
                          (widget.user.displayName ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              if (!isOwnProfile)
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showOptionsMenu(context, currentUser!),
                ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and role
                      Text(
                        widget.user.displayName ?? 'Unknown User',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (widget.user.username != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '@${widget.user.username}',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.grey400,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Role badge
                      _buildRoleBadge(),

                      const SizedBox(height: 24),

                      // Bio
                      if (widget.user.bio != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.grey900,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.grey800),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    color: AppTheme.primaryPurple,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'About',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                widget.user.bio!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.grey200,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Stats
                      _buildStatsSection(),

                      const SizedBox(height: 24),

                      // Action buttons
                      if (!isOwnProfile && currentUser != null)
                        _buildActionButtons(context, currentUser),

                      const SizedBox(height: 24),

                      // QR Code Section
                      _buildQRCodeSection(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge() {
    final roleColor = Color(
      int.parse(
        Permissions.getRoleBadgeColor(widget.user.role).replaceAll('#', '0xFF'),
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: roleColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: roleColor, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.user.role == UserRole.admin
                ? Icons.admin_panel_settings
                : Icons.military_tech,
            size: 18,
            color: roleColor,
          ),
          const SizedBox(width: 8),
          Text(
            Permissions.getRoleDisplayName(widget.user.role),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: roleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.grey900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.grey800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: AppTheme.primaryPurple, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Stats',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatRow(
            Icons.military_tech,
            'Rank Points',
            '${widget.user.totalPoints}',
            AppTheme.primaryPurple,
          ),
          const Divider(height: 24, color: AppTheme.grey800),
          _buildStatRow(
            Icons.emoji_events,
            'Missions Completed',
            '0', // TODO: Add completedMissions field to user model
            AppTheme.successGreen,
          ),
          const Divider(height: 24, color: AppTheme.grey800),
          _buildStatRow(
            Icons.calendar_today,
            'Member Since',
            _formatDate(widget.user.createdAt ?? DateTime.now()),
            AppTheme.infoBlue,
          ),
        ],
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
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, AppUser currentUser) {
    final friendsProvider = Provider.of<FriendsProvider>(context);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _startConversation(context, currentUser),
                icon: const Icon(Icons.chat_bubble, size: 20),
                label: const Text('Message'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FutureBuilder<String?>(
                future: friendsProvider.getPendingRequestBetween(
                  currentUser.uid,
                  widget.user.uid,
                ),
                builder: (context, snapshot) {
                  final requestStatus = snapshot.data;
                  final isFriend = friendsProvider.isFriend(widget.user.uid);

                  if (isFriend) {
                    return OutlinedButton.icon(
                      onPressed: () => _showFriendOptions(context, currentUser),
                      icon: const Icon(Icons.check, size: 20),
                      label: const Text('Friends'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.successGreen,
                        side: BorderSide(
                          color: AppTheme.successGreen,
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }

                  // THEY sent YOU a request - show Accept button
                  if (requestStatus == 'received') {
                    return OutlinedButton.icon(
                      onPressed: () =>
                          _acceptFriendRequest(context, currentUser),
                      icon: const Icon(Icons.person_add_alt_1, size: 20),
                      label: const Text('Accept Request'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.successGreen,
                        side: BorderSide(
                          color: AppTheme.successGreen,
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }

                  // YOU sent THEM a request - show Cancel button
                  if (requestStatus == 'sent') {
                    return OutlinedButton.icon(
                      onPressed: () =>
                          _cancelFriendRequest(context, currentUser),
                      icon: const Icon(Icons.cancel, size: 20),
                      label: const Text('Cancel Request'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.warningOrange,
                        side: BorderSide(
                          color: AppTheme.warningOrange,
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }

                  return OutlinedButton.icon(
                    onPressed: () => _sendFriendRequest(context, currentUser),
                    icon: const Icon(Icons.person_add, size: 20),
                    label: const Text('Add Friend'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryPurple,
                      side: BorderSide(color: AppTheme.primaryPurple, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQRCodeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.grey900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.grey800),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.qr_code_2, color: AppTheme.primaryPurple, size: 20),
              const SizedBox(width: 8),
              const Text(
                'QR Code',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _showLargeQRCode(context),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: widget.user.uid,
                version: QrVersions.auto,
                size: 200,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tap to enlarge for scanning',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.grey400,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  void _showLargeQRCode(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.darkGrey,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Scan to Add Friend',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: widget.user.uid,
                  version: QrVersions.auto,
                  size: 300,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.user.displayName ?? 'Unknown User',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context, AppUser currentUser) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.grey900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final blockReportProvider = Provider.of<BlockReportProvider>(
          context,
          listen: false,
        );

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.block, color: AppTheme.errorRed),
                title: const Text('Block User'),
                onTap: () {
                  Navigator.pop(context);
                  _showBlockConfirmation(
                    context,
                    currentUser,
                    blockReportProvider,
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.report,
                  color: AppTheme.warningOrange,
                ),
                title: const Text('Report User'),
                onTap: () {
                  Navigator.pop(context);
                  _showReportDialog(context, currentUser, blockReportProvider);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _startConversation(BuildContext context, AppUser currentUser) async {
    final messagingProvider = Provider.of<MessagingProvider>(
      context,
      listen: false,
    );
    final blockReportProvider = Provider.of<BlockReportProvider>(
      context,
      listen: false,
    );

    try {
      // Check if user is blocked
      final isBlocked = await blockReportProvider.isUserBlocked(
        currentUser.uid,
        widget.user.uid,
      );

      if (isBlocked) {
        if (context.mounted) {
          CustomNotificationBanner.show(
            context,
            title: 'Cannot Message',
            message: 'You have blocked this user',
            icon: Icons.block,
          );
        }
        return;
      }
      final conversationId = await messagingProvider.getOrCreateConversation(
        currentUserId: currentUser.uid,
        currentUserName: currentUser.displayName ?? 'Unknown',
        otherUserId: widget.user.uid,
        otherUserName: widget.user.displayName ?? 'Unknown',
      );

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MessageThreadScreen(
              conversationId: conversationId,
              otherUserName: widget.user.displayName ?? 'Unknown',
              otherUserId: widget.user.uid,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start conversation: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _acceptFriendRequest(
    BuildContext context,
    AppUser currentUser,
  ) async {
    final friendsProvider = Provider.of<FriendsProvider>(
      context,
      listen: false,
    );

    try {
      debugPrint(
        '🔍 Looking for friend request from ${widget.user.displayName}...',
      );

      // Find the request they sent to you
      final snapshot = await FirebaseFirestore.instance
          .collection('friendRequests')
          .where('senderId', isEqualTo: widget.user.uid)
          .where('receiverId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint('❌ No pending request found');
        if (context.mounted) {
          CustomNotificationBanner.show(
            context,
            title: 'Request Not Found',
            message: 'This friend request no longer exists',
            icon: Icons.info_outline,
          );
        }
        return;
      }

      final requestId = snapshot.docs.first.id;
      debugPrint('✅ Found request: $requestId - Accepting...');

      await friendsProvider.acceptFriendRequest(requestId, currentUser.uid);

      debugPrint('🎉 Successfully accepted friend request!');

      if (context.mounted) {
        setState(() {}); // Trigger rebuild
        CustomNotificationBanner.show(
          context,
          title: 'Friends!',
          message: 'You and ${widget.user.displayName} are now friends',
          icon: Icons.celebration,
        );
      }
    } catch (e) {
      debugPrint('❌ Error accepting friend request: $e');
      if (context.mounted) {
        String errorMsg = e
            .toString()
            .replaceAll('Exception: ', '')
            .replaceAll('Failed to accept friend request: ', '');

        CustomNotificationBanner.show(
          context,
          title: 'Error',
          message: errorMsg.contains('permission')
              ? 'Permission error - try refreshing the app'
              : 'Failed to accept: $errorMsg',
          icon: Icons.error_outline,
        );
      }
    }
  }

  void _cancelFriendRequest(BuildContext context, AppUser currentUser) async {
    try {
      debugPrint('🔍 Looking for friend request to cancel...');

      final snapshot = await FirebaseFirestore.instance
          .collection('friendRequests')
          .where('senderId', isEqualTo: currentUser.uid)
          .where('receiverId', isEqualTo: widget.user.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint('❌ No request found to cancel');
        if (context.mounted) {
          CustomNotificationBanner.show(
            context,
            title: 'Request Not Found',
            message: 'Friend request no longer exists',
            icon: Icons.info_outline,
          );
        }
        return;
      }

      debugPrint('🗑️ Deleting ${snapshot.docs.length} request(s)...');

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
        debugPrint('✅ Deleted request: ${doc.id}');
      }

      if (context.mounted) {
        setState(() {}); // Trigger rebuild
        CustomNotificationBanner.show(
          context,
          title: 'Request Cancelled',
          message: 'Friend request cancelled',
          icon: Icons.cancel,
        );
      }
    } catch (e) {
      debugPrint('❌ Error canceling request: $e');
      if (context.mounted) {
        String errorMsg = e
            .toString()
            .replaceAll('Exception: ', '')
            .replaceAll('Failed to cancel: ', '');

        CustomNotificationBanner.show(
          context,
          title: 'Error',
          message: errorMsg.contains('permission')
              ? 'Permission error - rules updated, try again'
              : 'Failed to cancel: $errorMsg',
          icon: Icons.error_outline,
        );
      }
    }
  }

  void _sendFriendRequest(BuildContext context, AppUser currentUser) async {
    final friendsProvider = Provider.of<FriendsProvider>(
      context,
      listen: false,
    );

    try {
      await friendsProvider.sendFriendRequest(
        senderId: currentUser.uid,
        senderName: currentUser.displayName ?? 'Unknown',
        receiverId: widget.user.uid,
      );

      if (context.mounted) {
        setState(() {}); // Trigger rebuild
        CustomNotificationBanner.show(
          context,
          title: 'Request Sent',
          message: 'Friend request sent to ${widget.user.displayName}',
          icon: Icons.person_add,
        );
      }
    } catch (e) {
      if (context.mounted) {
        // Extract clean error message
        String errorMsg = e.toString().replaceAll('Exception: ', '');
        if (errorMsg.contains('Failed to send friend request:')) {
          errorMsg = errorMsg.replaceAll(
            'Failed to send friend request: Exception: ',
            '',
          );
        }

        CustomNotificationBanner.show(
          context,
          title: 'Request Failed',
          message: errorMsg,
          icon: Icons.error_outline,
        );
      }
    }
  }

  void _showFriendOptions(BuildContext context, AppUser currentUser) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.grey900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.person_remove,
                color: AppTheme.errorRed,
              ),
              title: const Text('Unfriend'),
              subtitle: Text('Remove ${widget.user.displayName} from friends'),
              onTap: () {
                Navigator.pop(context);
                _confirmUnfriend(context, currentUser);
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: AppTheme.errorRed),
              title: const Text('Block User'),
              subtitle: Text('Block ${widget.user.displayName}'),
              onTap: () {
                Navigator.pop(context);
                final blockReportProvider = Provider.of<BlockReportProvider>(
                  context,
                  listen: false,
                );
                _showBlockConfirmation(
                  context,
                  currentUser,
                  blockReportProvider,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmUnfriend(BuildContext context, AppUser currentUser) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkGrey,
        title: const Text('Unfriend'),
        content: Text(
          'Remove ${widget.user.displayName} from your friends list?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _unfriend(context, currentUser);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Unfriend'),
          ),
        ],
      ),
    );
  }

  Future<void> _unfriend(BuildContext context, AppUser currentUser) async {
    final friendsProvider = Provider.of<FriendsProvider>(
      context,
      listen: false,
    );

    try {
      await friendsProvider.removeFriend(currentUser.uid, widget.user.uid);

      if (context.mounted) {
        setState(() {}); // Trigger rebuild
        CustomNotificationBanner.show(
          context,
          title: 'Unfriended',
          message: 'You are no longer friends with ${widget.user.displayName}',
          icon: Icons.person_remove,
        );
      }
    } catch (e) {
      if (context.mounted) {
        CustomNotificationBanner.show(
          context,
          title: 'Error',
          message:
              'Failed to unfriend: ${e.toString().replaceAll('Exception: ', '')}',
          icon: Icons.error_outline,
        );
      }
    }
  }

  void _showBlockConfirmation(
    BuildContext context,
    AppUser currentUser,
    BlockReportProvider blockReportProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkGrey,
        title: const Text('Block User'),
        content: Text(
          'Are you sure you want to block ${widget.user.displayName}? This will remove any existing friendship and prevent further interactions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await blockReportProvider.blockUser(
                  currentUser.uid,
                  widget.user.uid,
                );
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close profile
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User blocked successfully'),
                      backgroundColor: AppTheme.successGreen,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to block user: $e'),
                      backgroundColor: AppTheme.errorRed,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(
    BuildContext context,
    AppUser currentUser,
    BlockReportProvider blockReportProvider,
  ) {
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
                  'Report ${widget.user.displayName} for:',
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
                try {
                  await blockReportProvider.reportUser(
                    reporterId: currentUser.uid,
                    reportedId: widget.user.uid,
                    reason: selectedReason,
                    description: descriptionController.text.trim(),
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Report submitted successfully'),
                        backgroundColor: AppTheme.successGreen,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to submit report: $e'),
                        backgroundColor: AppTheme.errorRed,
                      ),
                    );
                  }
                }
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

  String _getReasonLabel(ReportReason reason) {
    switch (reason) {
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.harassment:
        return 'Harassment';
      case ReportReason.inappropriate:
        return 'Inappropriate Content';
      case ReportReason.impersonation:
        return 'Impersonation';
      case ReportReason.other:
        return 'Other';
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}
