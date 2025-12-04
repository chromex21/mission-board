import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/messaging_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/conversation_model.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/messages/rich_message_input.dart';

class MessageThreadScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserName;
  final String otherUserId;

  const MessageThreadScreen({
    super.key,
    required this.conversationId,
    required this.otherUserName,
    required this.otherUserId,
  });

  @override
  State<MessageThreadScreen> createState() => _MessageThreadScreenState();
}

class _MessageThreadScreenState extends State<MessageThreadScreen> {
  final ScrollController _scrollController = ScrollController();
  final Set<String> _selectedMessageIds = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
  }

  void _markMessagesAsRead() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messagingProvider = Provider.of<MessagingProvider>(
      context,
      listen: false,
    );

    if (authProvider.user != null) {
      messagingProvider.markMessagesAsRead(
        conversationId: widget.conversationId,
        userId: authProvider.user!.uid,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final messagingProvider = Provider.of<MessagingProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentUser = authProvider.user;
    final isDark = themeProvider.isDarkMode;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view messages')),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkGrey : AppTheme.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.grey900 : Colors.white,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : AppTheme.lightText,
        ),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _cancelSelection,
              )
            : null,
        title: _isSelectionMode
            ? Text(
                '${_selectedMessageIds.length} selected',
                style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.lightText,
                ),
              )
            : Text(
                widget.otherUserName,
                style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.lightText,
                ),
              ),
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: () => _selectAllMessages(context),
                  tooltip: 'Select All',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppTheme.errorRed),
                  onPressed: _selectedMessageIds.isEmpty
                      ? null
                      : () => _confirmDeleteSelected(context),
                  tooltip: 'Delete Selected',
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: messagingProvider.streamMessages(widget.conversationId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Loading messages...',
                          style: TextStyle(color: AppTheme.grey400),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppTheme.errorRed,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error Loading Messages',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.grey400,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Could not load conversation',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.grey600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data ?? [];
                return _buildMessagesBody(messages, currentUser.uid);
              },
            ),
          ),

          RichMessageInput(
            conversationId: widget.conversationId,
            recipientId: widget.otherUserId,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesBody(List<Message> messages, String currentUserId) {
    if (messages.isEmpty) {
      return Center(
        child: Text(
          'No messages yet. Say hi!',
          style: TextStyle(color: AppTheme.grey400),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.senderId == currentUserId;
        return _buildMessageBubble(message, isMe);
      },
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    final isSelected = _selectedMessageIds.contains(message.id);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () {
          if (!_isSelectionMode) {
            _enterSelectionMode(message.id);
          } else {
            _toggleMessageSelection(message.id);
          }
        },
        onTap: () {
          if (_isSelectionMode) {
            _toggleMessageSelection(message.id);
          }
        },
        child: Stack(
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: message.type == MessageType.image ||
                      message.type == MessageType.gif
                  ? const EdgeInsets.all(4)
                  : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.infoBlue.withValues(alpha: 0.5)
                    : (isMe ? AppTheme.primaryPurple : AppTheme.grey800),
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomRight: isMe ? const Radius.circular(4) : null,
                  bottomLeft: !isMe ? const Radius.circular(4) : null,
                ),
                border: isSelected
                    ? Border.all(color: AppTheme.infoBlue, width: 2)
                    : null,
              ),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMe && message.type == MessageType.text)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    message.senderName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryPurple,
                    ),
                  ),
                ),

              if (message.type == MessageType.text)
                Text(message.content, style: const TextStyle(fontSize: 14))
              else if (message.type == MessageType.image ||
                  message.type == MessageType.gif)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    message.content,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return SizedBox(
                        height: 200,
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
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: AppTheme.grey700,
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                )
              else if (message.type == MessageType.file)
                Row(
                  children: [
                    const Icon(Icons.insert_drive_file, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'File attachment',
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 4),
              Text(
                DateFormat.jm().format(message.timestamp),
                style: TextStyle(
                  fontSize: 10,
                  color: isMe ? Colors.white70 : AppTheme.grey400,
                ),
              ),
            ],
          ),
            if (isSelected)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.infoBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _enterSelectionMode(String messageId) {
    setState(() {
      _isSelectionMode = true;
      _selectedMessageIds.add(messageId);
    });
  }

  void _toggleMessageSelection(String messageId) {
    setState(() {
      if (_selectedMessageIds.contains(messageId)) {
        _selectedMessageIds.remove(messageId);
        if (_selectedMessageIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedMessageIds.add(messageId);
      }
    });
  }

  void _cancelSelection() {
    setState(() {
      _isSelectionMode = false;
      _selectedMessageIds.clear();
    });
  }

  void _selectAllMessages(BuildContext context) {
    final messagingProvider = Provider.of<MessagingProvider>(
      context,
      listen: false,
    );
    
    // Get all message IDs from the current stream
    messagingProvider
        .streamMessages(widget.conversationId)
        .first
        .then((messages) {
      setState(() {
        _selectedMessageIds.clear();
        _selectedMessageIds.addAll(messages.map((m) => m.id));
      });
    });
  }

  void _confirmDeleteSelected(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.grey900,
        title: const Text('Delete Messages'),
        content: Text(
          'Are you sure you want to delete ${_selectedMessageIds.length} message(s)? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSelectedMessages();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelectedMessages() async {
    final messagingProvider = Provider.of<MessagingProvider>(
      context,
      listen: false,
    );

    final count = _selectedMessageIds.length;
    final messageIds = List<String>.from(_selectedMessageIds);

    try {
      // Delete all selected messages
      for (final messageId in messageIds) {
        await messagingProvider.deleteMessage(
          widget.conversationId,
          messageId,
        );
      }

      if (mounted) {
        setState(() {
          _isSelectionMode = false;
          _selectedMessageIds.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count message(s) deleted'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete messages: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
