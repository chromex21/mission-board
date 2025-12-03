import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/lobby_message_model.dart';
import '../../core/theme/app_theme.dart';
import 'voice_note_player.dart';

class MessageBubble extends StatelessWidget {
  final LobbyMessage message;
  final bool isOwnMessage;
  final VoidCallback? onDelete;
  final Function(String emoji)? onReaction;
  final VoidCallback? onReply;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isOwnMessage,
    this.onDelete,
    this.onReaction,
    this.onReply,
  });

  void _showMessageActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.grey900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick reactions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 12,
                children: ['❤️', '👍', '😂', '😮', '😢', '🙏'].map((emoji) {
                  return InkWell(
                    onTap: () {
                      onReaction?.call(emoji);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.grey800,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(emoji, style: TextStyle(fontSize: 24)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 32),
            if (onReply != null)
              ListTile(
                leading: Icon(Icons.reply, color: AppTheme.primaryPurple),
                title: const Text(
                  'Reply',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  onReply?.call();
                  Navigator.pop(context);
                },
              ),
            if (isOwnMessage && onDelete != null)
              ListTile(
                leading: Icon(Icons.delete, color: AppTheme.errorRed),
                title: Text(
                  'Delete',
                  style: TextStyle(color: AppTheme.errorRed),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onDelete?.call();
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: isOwnMessage
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isOwnMessage) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: message.userPhotoUrl != null
                  ? NetworkImage(message.userPhotoUrl!)
                  : null,
              child: message.userPhotoUrl == null
                  ? Text(message.userName[0].toUpperCase())
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageActions(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isOwnMessage
                      ? AppTheme.primaryPurple
                      : AppTheme.grey800,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isOwnMessage)
                      Text(
                        message.userName,
                        style: const TextStyle(
                          color: Color(0xFFE91E63),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: 4),

                    // Reply-to preview
                    if (message.replyToId != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border(
                            left: BorderSide(
                              color: AppTheme.primaryPurple,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.replyToUserName ?? 'Unknown',
                              style: TextStyle(
                                color: AppTheme.primaryPurple,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              message.replyToContent ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    _buildMessageContent(),
                    const SizedBox(height: 4),

                    // Reactions
                    if (message.reactions != null &&
                        message.reactions!.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: message.reactions!.entries.map((entry) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(entry.key, style: TextStyle(fontSize: 12)),
                                const SizedBox(width: 2),
                                Text(
                                  '${entry.value.length}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 4),
                    Text(
                      DateFormat('HH:mm').format(message.createdAt),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isOwnMessage) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundImage: message.userPhotoUrl != null
                  ? NetworkImage(message.userPhotoUrl!)
                  : null,
              child: message.userPhotoUrl == null
                  ? Text(message.userName[0].toUpperCase())
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (message.messageType) {
      case 'image':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.content.isNotEmpty) ...[
              Text(
                message.content,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
            ],
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                message.mediaUrl!,
                width: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 200,
                  height: 150,
                  color: Colors.grey[800],
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.white54),
                  ),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 200,
                    height: 150,
                    color: Colors.grey[800],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );

      case 'gif':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.content.isNotEmpty) ...[
              Text(
                message.content,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
            ],
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                message.mediaUrl!,
                width: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 200,
                  height: 150,
                  color: Colors.grey[800],
                  child: const Center(
                    child: Icon(Icons.gif_box, color: Colors.white54),
                  ),
                ),
              ),
            ),
          ],
        );

      case 'sticker':
        return Text(
          message.content, // Sticker emoji
          style: const TextStyle(fontSize: 48),
        );

      case 'voice':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VoiceNotePlayer(
              audioUrl: message.mediaUrl!,
              duration: message.voiceDuration ?? 0,
              isOwnMessage: isOwnMessage,
            ),
            if (message.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message.content,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ],
        );

      case 'text':
      default:
        return Text(
          message.content,
          style: const TextStyle(color: Colors.white),
        );
    }
  }
}
