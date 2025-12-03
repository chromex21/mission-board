import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/lobby_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/lobby_message_model.dart';

class LobbyWidget extends StatefulWidget {
  const LobbyWidget({super.key});

  @override
  State<LobbyWidget> createState() => _LobbyWidgetState();
}

class _LobbyWidgetState extends State<LobbyWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final lobbyProvider = Provider.of<LobbyProvider>(context, listen: false);

    if (authProvider.appUser == null) return;

    lobbyProvider.sendMessage(
      userId: authProvider.appUser!.uid,
      userName:
          authProvider.appUser!.displayName ?? authProvider.appUser!.email,
      userPhotoUrl: authProvider.appUser!.photoURL,
      content: content,
    );

    _messageController.clear(); // Scroll to bottom after sending
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lobbyProvider = Provider.of<LobbyProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Container(
      margin: const EdgeInsets.all(20),
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
              Icon(Icons.forum, size: 20, color: AppTheme.primaryPurple),
              const SizedBox(width: 8),
              const Text(
                'Lobby Chat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<List<LobbyMessage>>(
              stream: lobbyProvider.streamLobbyMessages(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading messages',
                      style: TextStyle(color: AppTheme.grey400),
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: AppTheme.grey600,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No messages yet. Start the conversation!',
                          style: TextStyle(
                            color: AppTheme.grey400,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isCurrentUser =
                        message.userId == authProvider.appUser?.uid;

                    return _MessageBubble(
                      message: message,
                      isCurrentUser: isCurrentUser,
                      onDelete: () {
                        lobbyProvider.deleteMessage(
                          message.id,
                          authProvider.appUser!.uid,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.grey800,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.grey700),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type a message... (@mention users)',
                      hintStyle: TextStyle(color: AppTheme.grey400),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: Icon(Icons.send, color: AppTheme.primaryPurple),
                  tooltip: 'Send message',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final LobbyMessage message;
  final bool isCurrentUser;
  final VoidCallback onDelete;

  const _MessageBubble({
    required this.message,
    required this.isCurrentUser,
    required this.onDelete,
  });

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primaryPurple,
            backgroundImage: message.userPhotoUrl != null
                ? NetworkImage(message.userPhotoUrl!)
                : null,
            child: message.userPhotoUrl == null
                ? Text(
                    message.userName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      message.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(message.createdAt),
                      style: TextStyle(color: AppTheme.grey400, fontSize: 11),
                    ),
                    if (isCurrentUser) ...[
                      const Spacer(),
                      IconButton(
                        onPressed: onDelete,
                        icon: Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: AppTheme.grey400,
                        ),
                        tooltip: 'Delete message',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                _buildMessageContent(),
                if (message.missionId != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.grey800,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.task_alt,
                          size: 12,
                          color: AppTheme.primaryPurple,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          message.missionTitle ?? 'Mission',
                          style: TextStyle(
                            color: AppTheme.primaryPurple,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent() {
    final spans = <TextSpan>[];
    final words = message.content.split(' ');

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      if (word.startsWith('@')) {
        spans.add(
          TextSpan(
            text: word,
            style: const TextStyle(
              color: AppTheme.primaryPurple,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      } else {
        spans.add(TextSpan(text: word));
      }

      if (i < words.length - 1) {
        spans.add(const TextSpan(text: ' '));
      }
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(color: AppTheme.grey200, fontSize: 13),
        children: spans,
      ),
    );
  }
}
