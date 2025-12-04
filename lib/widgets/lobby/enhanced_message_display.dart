import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../models/lobby_message_model.dart';
import '../../core/theme/app_theme.dart';

/// Enhanced message display for all media types
/// - Text with mention highlighting
/// - Images with proper rendering
/// - GIFs
/// - Voice notes
/// - Documents with download support
/// - System messages
class EnhancedMessageDisplay extends StatelessWidget {
  final LobbyMessage message;
  final bool isOwnMessage;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Function(String emoji)? onReaction;

  const EnhancedMessageDisplay({
    super.key,
    required this.message,
    required this.isOwnMessage,
    this.onTap,
    this.onLongPress,
    this.onReaction,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isSystemMessage) {
      return _buildSystemMessage();
    }

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isOwnMessage
              ? AppTheme.primaryPurple.withValues(alpha: 0.05)
              : Colors.transparent,
          border: Border(
            left: isOwnMessage
                ? BorderSide(color: AppTheme.primaryPurple, width: 2)
                : BorderSide.none,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: timestamp, rank, username
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.grey600,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 12),
                if (message.userRank != null)
                  _buildRankBadge(message.userRank!),
                Text(
                  '[${message.userName}]',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _getUserColor(message.userId),
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // Message content (text or media)
            _buildMessageContent(context),

            // Reactions
            if (message.reactions != null && message.reactions!.isNotEmpty) ...[
              const SizedBox(height: 4),
              _buildCompactReactions(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    switch (message.messageType) {
      case 'image':
        return _buildImageDisplay();

      case 'gif':
        return _buildGifDisplay();

      case 'voice':
        return _buildVoiceNoteDisplay();

      case 'document':
        return _buildDocumentDisplay();

      case 'text':
      default:
        return _buildTextContent();
    }
  }

  Widget _buildImageDisplay() {
    // Check if it's a network URL or local file path
    final isNetworkUrl = message.content.startsWith('http');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 300),
            decoration: BoxDecoration(
              color: AppTheme.grey700,
              borderRadius: BorderRadius.circular(8),
            ),
            child: isNetworkUrl
                ? CachedNetworkImage(
                    imageUrl: message.content,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppTheme.grey700,
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppTheme.grey700,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image,
                              color: AppTheme.errorRed, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            'Failed to load image',
                            style: TextStyle(
                              color: AppTheme.errorRed,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Image.network(
                    message.content,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppTheme.grey700,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image,
                                color: AppTheme.errorRed, size: 32),
                            const SizedBox(height: 8),
                            const Text(
                              'Failed to load image',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildGifDisplay() {
    final isNetworkUrl = message.content.startsWith('http');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.gif_box, color: AppTheme.infoBlue, size: 20),
        const SizedBox(height: 8),
        if (isNetworkUrl)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 300, maxHeight: 250),
              child: CachedNetworkImage(
                imageUrl: message.content,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppTheme.grey700,
                  child: const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
          )
        else
          Text(
            'GIF: ${message.content}',
            style: const TextStyle(fontSize: 13, color: Colors.white),
          ),
      ],
    );
  }

  Widget _buildVoiceNoteDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.grey900,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.grey700),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.play_circle_filled,
              color: AppTheme.primaryPurple, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Voice message',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.grey200,
                ),
              ),
              Text(
                '${message.voiceDuration ?? 0} sec',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.grey400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentDisplay() {
    final fileName = message.content;
    final fileExtension = fileName.split('.').last.toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.grey900,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.grey700),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getDocumentIcon(fileExtension),
            color: AppTheme.infoBlue,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  fileExtension,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.grey400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.download,
            color: AppTheme.primaryPurple,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildTextContent() {
    final parts = message.content.split(' ');
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 13,
          color: Colors.white,
          height: 1.4,
        ),
        children: parts.map((part) {
          // Highlight mentions
          if (part.startsWith('@')) {
            return TextSpan(
              text: '$part ',
              style: TextStyle(
                color: AppTheme.successGreen,
                fontWeight: FontWeight.w600,
              ),
            );
          }
          // Highlight URLs
          if (part.startsWith('http')) {
            return TextSpan(
              text: '$part ',
              style: TextStyle(
                color: AppTheme.infoBlue,
                decoration: TextDecoration.underline,
              ),
            );
          }
          return TextSpan(text: '$part ');
        }).toList(),
      ),
    );
  }

  Widget _buildSystemMessage() {
    final systemType = message.systemType ?? 'unknown';
    final icon = _getSystemIcon(systemType);
    final color = _getSystemColor(systemType);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message.content,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontStyle: FontStyle.italic,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildCompactReactions() {
    final reactions = message.reactions!;
    if (reactions.isEmpty) return const SizedBox.shrink();

    final firstReaction = reactions.entries.first;
    final totalReactions =
        reactions.values.fold<int>(0, (sum, users) => sum + users.length);

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.grey800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.grey700),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(firstReaction.key, style: const TextStyle(fontSize: 12)),
          if (totalReactions > 1) ...[
            const SizedBox(width: 4),
            Text(
              totalReactions.toString(),
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.grey400,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRankBadge(String rank) {
    final emoji = _getRankEmoji(rank);
    return Container(
      margin: const EdgeInsets.only(right: 4),
      child: Text(emoji, style: const TextStyle(fontSize: 12)),
    );
  }

  String _getRankEmoji(String rank) {
    switch (rank) {
      case 'admin':
        return '👑';
      case 'mod':
        return '🛡️';
      case 'og':
        return '⭐';
      case 'member':
        return '✅';
      case 'guest':
      default:
        return '👋';
    }
  }

  Color _getUserColor(String userId) {
    final hash = userId.hashCode;
    final colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.cyan,
      Colors.deepPurple,
      Colors.amber,
      Colors.lime,
      Colors.pink,
      Colors.teal,
    ];
    return colors[hash.abs() % colors.length];
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else {
      return DateFormat('HH:mm').format(dateTime);
    }
  }

  IconData _getDocumentIcon(String extension) {
    switch (extension) {
      case 'PDF':
        return Icons.picture_as_pdf;
      case 'DOCX':
      case 'DOC':
        return Icons.description;
      case 'XLSX':
      case 'XLS':
        return Icons.table_chart;
      case 'PPTX':
      case 'PPT':
        return Icons.slideshow;
      case 'ZIP':
      case 'RAR':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  IconData _getSystemIcon(String systemType) {
    switch (systemType) {
      case 'join':
        return Icons.login;
      case 'leave':
        return Icons.logout;
      case 'welcome':
        return Icons.waving_hand;
      case 'pin':
        return Icons.push_pin;
      default:
        return Icons.info;
    }
  }

  Color _getSystemColor(String systemType) {
    switch (systemType) {
      case 'join':
        return AppTheme.successGreen;
      case 'leave':
        return AppTheme.warningOrange;
      case 'welcome':
        return AppTheme.infoBlue;
      default:
        return AppTheme.grey400;
    }
  }
}
