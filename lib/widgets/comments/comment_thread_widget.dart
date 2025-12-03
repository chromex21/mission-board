import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/comment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/comment_model.dart';
import '../../utils/notification_helper.dart';

class CommentThreadWidget extends StatefulWidget {
  final String missionId;
  final bool showInput;

  const CommentThreadWidget({
    super.key,
    required this.missionId,
    this.showInput = true,
  });

  @override
  State<CommentThreadWidget> createState() => _CommentThreadWidgetState();
}

class _CommentThreadWidgetState extends State<CommentThreadWidget> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentProvider = Provider.of<CommentProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Column(
      children: [
        // Comments list
        Expanded(
          child: StreamBuilder<List<Comment>>(
            stream: commentProvider.streamCommentsForMission(widget.missionId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading comments',
                    style: TextStyle(color: AppTheme.errorRed),
                  ),
                );
              }

              final comments = snapshot.data ?? [];

              if (comments.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 48,
                        color: AppTheme.grey600,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No comments yet',
                        style: TextStyle(color: AppTheme.grey600, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Start the conversation',
                        style: TextStyle(color: AppTheme.grey600, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }

              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _scrollToBottom(),
              );

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  final isOwn = comment.userId == authProvider.user?.uid;
                  return _CommentBubble(
                    comment: comment,
                    isOwn: isOwn,
                    onDelete: isOwn ? () => _deleteComment(comment.id) : null,
                    onEdit: isOwn ? () => _editComment(comment) : null,
                  );
                },
              );
            },
          ),
        ),

        // Comment input
        if (widget.showInput) _buildCommentInput(commentProvider, authProvider),
      ],
    );
  }

  Widget _buildCommentInput(
    CommentProvider commentProvider,
    AuthProvider authProvider,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.grey900,
        border: Border(top: BorderSide(color: AppTheme.grey700)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Write a comment...',
                hintStyle: TextStyle(color: AppTheme.grey600),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: AppTheme.grey700),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: AppTheme.grey700),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: AppTheme.primaryPurple),
                ),
                filled: true,
                fillColor: AppTheme.grey800,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              enabled: !_isSubmitting,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isSubmitting
                ? null
                : () => _submitComment(commentProvider, authProvider),
            icon: _isSubmitting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                        AppTheme.primaryPurple,
                      ),
                    ),
                  )
                : Icon(Icons.send, color: AppTheme.primaryPurple),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.grey800,
              shape: const CircleBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitComment(
    CommentProvider commentProvider,
    AuthProvider authProvider,
  ) async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      await commentProvider.addComment(
        missionId: widget.missionId,
        userId: authProvider.user?.uid ?? '',
        content: content,
      );

      _commentController.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        context.showError('Failed to send comment: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _deleteComment(String commentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<CommentProvider>(
                context,
                listen: false,
              ).deleteComment(commentId, widget.missionId);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _editComment(Comment comment) {
    final controller = TextEditingController(text: comment.content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Comment'),
        content: TextField(
          controller: controller,
          maxLines: null,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newContent = controller.text.trim();
              if (newContent.isNotEmpty) {
                Provider.of<CommentProvider>(
                  context,
                  listen: false,
                ).updateComment(commentId: comment.id, content: newContent);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _CommentBubble extends StatelessWidget {
  final Comment comment;
  final bool isOwn;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const _CommentBubble({
    required this.comment,
    required this.isOwn,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (comment.type == CommentType.system) {
      return _buildSystemMessage();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isOwn
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isOwn) ...[_buildAvatar(), const SizedBox(width: 8)],
          Flexible(
            child: Column(
              crossAxisAlignment: isOwn
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                _buildUserInfo(context),
                const SizedBox(height: 4),
                _buildMessageBubble(context),
                if (comment.linkPreviewUrl != null) ...[
                  const SizedBox(height: 8),
                  _buildLinkPreview(),
                ],
              ],
            ),
          ),
          if (isOwn) ...[const SizedBox(width: 8), _buildAvatar()],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(comment.userId)
          .get(),
      builder: (context, snapshot) {
        final data = snapshot.hasData
            ? snapshot.data!.data() as Map<String, dynamic>?
            : null;
        final email = data?['email'] ?? 'U';

        return CircleAvatar(
          radius: 16,
          backgroundColor: AppTheme.primaryPurple.withValues(alpha: 0.2),
          child: Text(
            email[0].toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.primaryPurple,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(comment.userId)
          .get(),
      builder: (context, snapshot) {
        final data = snapshot.hasData
            ? snapshot.data!.data() as Map<String, dynamic>?
            : null;
        final email = data?['email'] ?? 'Unknown';

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              email,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.grey400,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatTimestamp(comment.createdAt),
              style: TextStyle(fontSize: 11, color: AppTheme.grey600),
            ),
            if (comment.isEdited) ...[
              const SizedBox(width: 4),
              Text(
                '(edited)',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.grey600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildMessageBubble(BuildContext context) {
    return GestureDetector(
      onLongPress: isOwn ? () => _showOptions(context) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isOwn
              ? AppTheme.primaryPurple.withValues(alpha: 0.2)
              : AppTheme.grey800,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isOwn
                ? AppTheme.primaryPurple.withValues(alpha: 0.3)
                : AppTheme.grey700,
          ),
        ),
        child: Text(
          comment.content,
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
      ),
    );
  }

  Widget _buildLinkPreview() {
    return InkWell(
      onTap: () => _launchUrl(comment.linkPreviewUrl!),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.grey800,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.grey700),
        ),
        child: Row(
          children: [
            Icon(Icons.link, size: 20, color: AppTheme.infoBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (comment.linkPreviewTitle != null)
                    Text(
                      comment.linkPreviewTitle!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    comment.linkPreviewUrl!,
                    style: TextStyle(fontSize: 12, color: AppTheme.grey400),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new, size: 16, color: AppTheme.grey600),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Divider(color: AppTheme.grey700, thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              comment.content,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.grey600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          Expanded(child: Divider(color: AppTheme.grey700, thickness: 1)),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.grey900,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  onEdit!();
                },
              ),
            if (onDelete != null)
              ListTile(
                leading: Icon(Icons.delete, color: AppTheme.errorRed),
                title: Text(
                  'Delete',
                  style: TextStyle(color: AppTheme.errorRed),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onDelete!();
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
