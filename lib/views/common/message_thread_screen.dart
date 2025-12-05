import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../providers/auth_provider.dart';
import '../../providers/messaging_provider.dart';
import '../../providers/presence_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/conversation_model.dart';
import '../../models/presence_model.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/messages/rich_message_input.dart';
import '../../widgets/messages/message_reactions.dart';

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
  bool _showScrollButton = false;
  Message? _replyingTo;
  final TextEditingController _editController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      final showButton = _scrollController.offset > 200;
      if (showButton != _showScrollButton) {
        setState(() => _showScrollButton = showButton);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
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
            : _buildAppBarTitle(isDark),
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder<List<Message>>(
                  stream: messagingProvider.streamMessages(
                    widget.conversationId,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
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
                    return Stack(
                      children: [
                        _buildMessagesBody(messages, currentUser.uid),
                        if (_showScrollButton)
                          Positioned(
                            right: 16,
                            bottom: 16,
                            child: FloatingActionButton.small(
                              onPressed: _scrollToBottom,
                              backgroundColor: AppTheme.primaryPurple,
                              child: const Icon(Icons.arrow_downward, size: 20),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),

              // Reply preview
              if (_replyingTo != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkGrey : AppTheme.grey200,
                    border: Border(
                      top: BorderSide(color: AppTheme.primaryPurple, width: 2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.reply,
                                  size: 16,
                                  color: AppTheme.primaryPurple,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Replying to ${_replyingTo!.senderId == currentUser.uid ? 'yourself' : widget.otherUserName}',
                                  style: TextStyle(
                                    color: AppTheme.primaryPurple,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _replyingTo!.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white70
                                    : AppTheme.grey600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => setState(() => _replyingTo = null),
                        color: AppTheme.grey400,
                      ),
                    ],
                  ),
                ),

              RichMessageInput(
                conversationId: widget.conversationId,
                recipientId: widget.otherUserId,
                replyingTo: _replyingTo,
                onReplyCleared: () => setState(() => _replyingTo = null),
              ),
            ],
          ),
        ),
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

        // Check if we need a date separator
        final showDateSeparator =
            index == messages.length - 1 ||
            !_isSameDay(message.timestamp, messages[index + 1].timestamp);

        return Column(
          children: [
            if (showDateSeparator) _buildDateSeparator(message.timestamp),
            _buildMessageBubble(message, isMe, currentUserId),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    String label;
    if (messageDate == today) {
      label = 'Today';
    } else if (messageDate == yesterday) {
      label = 'Yesterday';
    } else {
      label = DateFormat('MMM d, y').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: AppTheme.grey700, thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.grey400,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: AppTheme.grey700, thickness: 1)),
        ],
      ),
    );
  }

  /// Extracts the URL from message content, handling caption format
  String _extractUrl(String content) {
    // First, strip caption if present (format: "url|caption:text")
    final urlPart = content.contains('|caption:')
        ? content.split('|caption:').first
        : content;

    // Now we have either:
    // 1. A storage path: "messages/conversationId/timestamp_filename"
    // 2. An HTTPS URL: "https://firebasestorage..."
    // 3. Old format with colon: "gs://path:https://url"

    // Handle old storage:url format
    if (urlPart.contains(':https://')) {
      final url = urlPart.split(':').skip(1).join(':');
      debugPrint('[_extractUrl] old storage:url format → $url');
      return url;
    }

    debugPrint('[_extractUrl] plain URL/path → $urlPart');
    return urlPart;
  }

  /// Extracts the caption from message content if present
  String? _extractCaption(String content) {
    // Caption is stored as "url|caption:text" format
    // Just extract the caption part directly
    if (content.contains('|caption:')) {
      final parts = content.split('|caption:');
      if (parts.length > 1) {
        return parts[1];
      }
    }
    return null;
  }

  /// Download or open a file on Android (via system)
  void _downloadFile(String url) {
    // On Android, Firebase Storage paths are loaded via SDK
    debugPrint('[_downloadFile] File download requested: $url');
    // In a real implementation, would use url_launcher or a download manager
  }

  /// Build image widget that loads from Firebase Storage with authentication
  /// Uses the storage path from message content to load with proper auth
  String? _toStoragePath(String url) {
    // Convert an HTTPS download URL into a storage path so we can generate a fresh token
    if (!url.startsWith('https://firebasestorage')) return null;
    try {
      final uri = Uri.parse(url);
      final oIndex = uri.pathSegments.indexOf('o');
      if (oIndex != -1 && uri.pathSegments.length > oIndex + 1) {
        final encodedPath = uri.pathSegments[oIndex + 1];
        return Uri.decodeComponent(encodedPath);
      }
    } catch (_) {
      // If parsing fails, fall back to treating it as a direct URL
    }
    return null;
  }

  Widget _buildAuthenticatedImage(String url) {
    debugPrint('[_buildAuthenticatedImage] Loading: $url');

    // Prefer treating any legacy HTTPS URL as a storage path to get a fresh token
    final storagePath = _toStoragePath(url);
    final targetPath =
        storagePath ?? url; // if no conversion, assume it's already a path

    debugPrint('[_buildAuthenticatedImage] Using storage path: $targetPath');
    debugPrint(
      '[_buildAuthenticatedImage] Detected storage path, loading with FirebaseStorage SDK',
    );
    debugPrint(
      '[_buildAuthenticatedImage] Attempting to get download URL for authenticated access',
    );

    return FutureBuilder<String>(
      future: FirebaseStorage.instance.ref(targetPath).getDownloadURL(),
      builder: (context, urlSnapshot) {
        if (urlSnapshot.hasError) {
          debugPrint(
            '[_buildAuthenticatedImage] Failed to get download URL for $targetPath: ${urlSnapshot.error}',
          );
          // Fallback: try getData() if getDownloadURL fails
          debugPrint(
            '[_buildAuthenticatedImage] Falling back to getData() method',
          );
          return FutureBuilder<Uint8List?>(
            future: FirebaseStorage.instance
                .ref(targetPath)
                .getData(50 * 1024 * 1024),
            builder: (context, dataSnapshot) {
              if (dataSnapshot.hasData && dataSnapshot.data != null) {
                debugPrint(
                  '[_buildAuthenticatedImage] Successfully loaded image via getData() from path: $targetPath',
                );
                return Image.memory(
                  dataSnapshot.data!,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                );
              } else if (dataSnapshot.hasError) {
                debugPrint(
                  '[_buildAuthenticatedImage] Failed getData() from Firebase Storage path $targetPath: ${dataSnapshot.error}',
                );
                return Container(
                  height: 200,
                  color: AppTheme.grey700,
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  ),
                );
              }
              debugPrint(
                '[_buildAuthenticatedImage] Loading via getData() from path: $url',
              );
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            },
          );
        }

        if (urlSnapshot.hasData) {
          debugPrint(
            '[_buildAuthenticatedImage] Got download URL: ${urlSnapshot.data}',
          );
          debugPrint(
            '[_buildAuthenticatedImage] Loading authenticated image from download URL',
          );
          return Image.network(
            urlSnapshot.data!,
            fit: BoxFit.cover,
            gaplessPlayback: true,
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
              debugPrint(
                '[_buildAuthenticatedImage] Failed to load from authenticated download URL: $error',
              );
              return Container(
                height: 200,
                color: AppTheme.grey700,
                child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey),
                ),
              );
            },
          );
        }

        debugPrint(
          '[_buildAuthenticatedImage] Waiting for download URL from path: $url',
        );
        return const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  /// Show image in full-screen viewer with download option
  void _showImageViewer(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(ctx).size.width * 0.9,
                  maxHeight: MediaQuery.of(ctx).size.height * 0.8,
                ),
                color: Colors.black,
                child: _buildAuthenticatedImage(imageUrl),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _downloadFile(imageUrl),
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe, String currentUserId) {
    final isSelected = _selectedMessageIds.contains(message.id);
    final isRead = message.readBy.contains(widget.otherUserId);
    final isDelivered =
        message.status == MessageStatus.delivered ||
        message.status == MessageStatus.read;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () {
          if (!_isSelectionMode) {
            _showMessageOptions(context, message, isMe);
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
              padding:
                  (message.type == MessageType.image ||
                      message.type == MessageType.gif)
                  ? const EdgeInsets.all(4)
                  : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
                minWidth: 80,
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
                  if (message.replyTo != null)
                    ReplyReferenceWidget(reply: message.replyTo!),
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
                    Text(message.content, style: const TextStyle(fontSize: 14)),
                  if (message.type == MessageType.image ||
                      message.type == MessageType.gif)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            final imageUrl = _extractUrl(message.content);
                            _showImageViewer(context, imageUrl);
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _buildAuthenticatedImage(
                              _extractUrl(message.content),
                            ),
                          ),
                        ),
                        if (_extractCaption(message.content) != null) ...[
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              _extractCaption(message.content)!,
                              style: TextStyle(
                                fontSize: 12,
                                color: isMe ? Colors.white70 : AppTheme.grey400,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  if (message.type == MessageType.file)
                    GestureDetector(
                      onTap: () async {
                        final url = _extractUrl(message.content);
                        // On web, trigger download by opening in new tab
                        // On mobile, would use url_launcher
                        try {
                          // On Android, download file via system
                          _downloadFile(url);
                        } catch (e) {
                          debugPrint('Error opening file: $e');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[700] : AppTheme.grey700,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.download, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Download file',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (message.type == MessageType.voice)
                    Row(
                      children: [
                        const Icon(Icons.mic, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Voice message',
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat.jm().format(message.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe ? Colors.white70 : AppTheme.grey400,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: isRead
                              ? AppTheme.infoBlue
                              : (isDelivered
                                    ? Colors.white70
                                    : AppTheme.grey400),
                        ),
                      ],
                    ],
                  ),
                  if (message.reactions.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    MessageReactionWidget(
                      reactions: message.reactions,
                      currentUserId: currentUserId,
                      onReactionTap: (emoji) => _addReaction(message, emoji),
                      onAddReaction: () =>
                          _showReactionPicker(context, message),
                    ),
                  ],
                ],
              ),
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
                  child: const Icon(Icons.check, size: 16, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(BuildContext context, Message message, bool isMe) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _replyingTo = message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_reaction_outlined),
              title: const Text('React'),
              onTap: () {
                Navigator.pop(context);
                _showReactionPicker(context, message);
              },
            ),
            if (isMe) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _editController.text = message.content;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(message);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.forward),
              title: const Text('Forward'),
              onTap: () {
                Navigator.pop(context);
                _forwardMessage(message);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReactionPicker(BuildContext context, Message message) {
    final emojis = [
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

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'React to message',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: emojis
                    .map(
                      (emoji) => GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _addReaction(message, emoji);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.darkGrey,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addReaction(Message message, String emoji) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.appUser == null) return;

    try {
      await Provider.of<MessagingProvider>(context, listen: false).addReaction(
        conversationId: widget.conversationId,
        messageId: message.id,
        emoji: emoji,
        userId: authProvider.appUser!.uid,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add reaction: $e')));
      }
    }
  }

  void _deleteMessage(Message message) async {
    try {
      await Provider.of<MessagingProvider>(
        context,
        listen: false,
      ).deleteMessage(widget.conversationId, message.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete message: $e')));
      }
    }
  }

  void _forwardMessage(Message message) {
    // TODO: Implement forward UI with contact selector
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Forward feature coming soon')),
    );
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
    messagingProvider.streamMessages(widget.conversationId).first.then((
      messages,
    ) {
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
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
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
        await messagingProvider.deleteMessage(widget.conversationId, messageId);
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

  Widget _buildAppBarTitle(bool isDark) {
    return Consumer<PresenceProvider>(
      builder: (context, presenceProvider, _) {
        final presence = presenceProvider.getPresence(widget.otherUserId);
        final isOnline = presence?.status == PresenceStatus.online;
        final typingUsers = presenceProvider.getTypingUsers(
          widget.conversationId,
        );
        final isTyping = typingUsers.contains(widget.otherUserId);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  widget.otherUserName,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppTheme.lightText,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isOnline) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.successGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
            if (isTyping)
              Text(
                'typing...',
                style: TextStyle(
                  color: AppTheme.primaryPurple,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              )
            else if (presence != null)
              Text(
                presence.getStatusText(),
                style: TextStyle(
                  color: isDark ? AppTheme.grey400 : AppTheme.grey600,
                  fontSize: 11,
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _editController.dispose();
    super.dispose();
  }
}
