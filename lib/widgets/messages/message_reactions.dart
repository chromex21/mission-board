import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/conversation_model.dart';

/// Message reaction picker and display
class MessageReactionWidget extends StatelessWidget {
  final List<MessageReaction> reactions;
  final String currentUserId;
  final Function(String emoji) onReactionTap;
  final VoidCallback onAddReaction;

  const MessageReactionWidget({
    super.key,
    required this.reactions,
    required this.currentUserId,
    required this.onReactionTap,
    required this.onAddReaction,
  });

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();

    // Group reactions by emoji
    final Map<String, List<MessageReaction>> groupedReactions = {};
    for (final reaction in reactions) {
      groupedReactions.putIfAbsent(reaction.emoji, () => []).add(reaction);
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        ...groupedReactions.entries.map((entry) {
          final emoji = entry.key;
          final reactionList = entry.value;
          final count = reactionList.length;
          final hasUserReacted = reactionList.any(
            (r) => r.userId == currentUserId,
          );

          return GestureDetector(
            onTap: () => onReactionTap(emoji),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: hasUserReacted
                    ? AppTheme.primaryPurple.withValues(alpha: 0.3)
                    : AppTheme.grey800,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasUserReacted
                      ? AppTheme.primaryPurple
                      : AppTheme.grey700,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 14)),
                  if (count > 1) ...[
                    const SizedBox(width: 4),
                    Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: hasUserReacted
                            ? AppTheme.primaryPurple
                            : AppTheme.grey400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
        // Add reaction button
        GestureDetector(
          onTap: onAddReaction,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.grey800,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.grey700),
            ),
            child: Icon(
              Icons.add_reaction_outlined,
              size: 16,
              color: AppTheme.grey400,
            ),
          ),
        ),
      ],
    );
  }
}

/// Reaction picker bottom sheet
class ReactionPicker extends StatelessWidget {
  final Function(String emoji) onReactionSelected;

  static const commonReactions = [
    '👍',
    '❤️',
    '😂',
    '😮',
    '😢',
    '😡',
    '🎉',
    '🔥',
    '👏',
    '🙏',
    '💯',
    '✨',
    '💪',
    '🚀',
    '✅',
    '❌',
  ];

  const ReactionPicker({super.key, required this.onReactionSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.grey900,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'React',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.white,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 8,
            shrinkWrap: true,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: commonReactions.map((emoji) {
              return GestureDetector(
                onTap: () {
                  onReactionSelected(emoji);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.grey800,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 28)),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Reply preview widget (shown when composing a reply)
class ReplyPreviewWidget extends StatelessWidget {
  final MessageReply reply;
  final VoidCallback onCancelReply;

  const ReplyPreviewWidget({
    super.key,
    required this.reply,
    required this.onCancelReply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.grey800,
        border: Border(
          left: BorderSide(color: AppTheme.primaryPurple, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reply.senderName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryPurple,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reply.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: AppTheme.grey400),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: AppTheme.grey400),
            onPressed: onCancelReply,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

/// Reply reference widget (shown in message bubble)
class ReplyReferenceWidget extends StatelessWidget {
  final MessageReply reply;
  final VoidCallback? onTap;

  const ReplyReferenceWidget({super.key, required this.reply, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.grey900.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(color: AppTheme.primaryPurple, width: 2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reply.senderName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryPurple,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              reply.content,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: AppTheme.grey400),
            ),
          ],
        ),
      ),
    );
  }
}
