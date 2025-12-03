import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/messaging_provider.dart';
import '../../models/conversation_model.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/layout/app_layout.dart';
import '../../utils/responsive_helper.dart';
import 'message_thread_screen.dart';

class MessagesScreen extends StatefulWidget {
  final Function(String)? onNavigate;

  const MessagesScreen({super.key, this.onNavigate});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final messagingProvider = Provider.of<MessagingProvider>(context);
    final currentUser = authProvider.user;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view messages')),
      );
    }

    return AppLayout(
      currentRoute: '/messages',
      title: 'Messages',
      onNavigate: widget.onNavigate ?? (route) {},
      child: ResponsiveContent(
        maxWidth: AppSizing.maxContentWidth(context),
        child: StreamBuilder<List<Conversation>>(
          stream: messagingProvider.streamConversations(currentUser.uid),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              final errorMsg = snapshot.error.toString();
              final isIndexError =
                  errorMsg.contains('index') ||
                  errorMsg.contains('FAILED_PRECONDITION');

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isIndexError
                            ? Icons.hourglass_empty
                            : Icons.error_outline,
                        size: 64,
                        color: isIndexError
                            ? AppTheme.warningOrange
                            : Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isIndexError
                            ? 'Setting up messages...'
                            : 'Error loading messages',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isIndexError
                              ? AppTheme.warningOrange
                              : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isIndexError
                            ? 'The database is building an index for messages.\nThis usually takes 2-5 minutes.\nPlease check back shortly!'
                            : errorMsg,
                        style: TextStyle(fontSize: 14, color: AppTheme.grey400),
                        textAlign: TextAlign.center,
                      ),
                      if (isIndexError) ...[
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {}); // Trigger rebuild to retry
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryPurple,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }

            final conversations = snapshot.data ?? [];

            if (conversations.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryPurple.withValues(alpha: 0.2),
                              AppTheme.infoBlue.withValues(alpha: 0.2),
                            ],
                          ),
                        ),
                        child: Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: AppTheme.primaryPurple,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No Messages Yet',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your direct messages will appear here',
                        style: TextStyle(fontSize: 16, color: AppTheme.grey400),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
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
                                  Icons.info_outline,
                                  size: 20,
                                  color: AppTheme.infoBlue,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'How to start a conversation',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.infoBlue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildTipItem('1', 'Go to Leaderboard or Teams'),
                            _buildTipItem('2', 'Click on a user\'s profile'),
                            _buildTipItem('3', 'Click "Send Message"'),
                            const SizedBox(height: 12),
                            Text(
                              'Chat privately with teammates about missions!',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.grey400,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: AppPadding.page(context),
              itemCount: conversations.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: AppTheme.grey700),
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                final otherParticipantId = conversation.participants.firstWhere(
                  (id) => id != currentUser.uid,
                );
                final otherParticipant =
                    conversation.participantDetails[otherParticipantId]
                        as Map<String, dynamic>?;
                final unreadCount =
                    conversation.unreadCount[currentUser.uid] ?? 0;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryPurple.withValues(
                      alpha: 0.2,
                    ),
                    child: Text(
                      (otherParticipant?['name'] ?? '?')[0].toUpperCase(),
                      style: TextStyle(
                        color: AppTheme.primaryPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          otherParticipant?['name'] ?? 'Unknown User',
                          style: TextStyle(
                            fontWeight: unreadCount > 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryPurple,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    conversation.lastMessage ?? 'No messages yet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: unreadCount > 0
                          ? AppTheme.grey200
                          : AppTheme.grey400,
                    ),
                  ),
                  trailing: conversation.lastMessageTime != null
                      ? Text(
                          _formatTime(conversation.lastMessageTime!),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.grey400,
                          ),
                        )
                      : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MessageThreadScreen(
                          conversationId: conversation.id,
                          otherUserName:
                              otherParticipant?['name'] ?? 'Unknown User',
                          otherUserId: otherParticipant?['id'] ?? '',
                        ),
                      ),
                    );
                  },
                  tileColor: AppTheme.grey900,
                  hoverColor: AppTheme.grey800,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildTipItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.primaryPurple.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryPurple,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: AppTheme.grey200),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return DateFormat.jm().format(time); // 3:45 PM
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat.E().format(time); // Mon, Tue, etc.
    } else {
      return DateFormat.MMMd().format(time); // Jan 15
    }
  }
}
