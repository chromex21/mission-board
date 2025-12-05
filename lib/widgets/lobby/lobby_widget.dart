import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../providers/lobby_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/lobby_message_model.dart';
import '../messages/media_picker_bottom_sheet.dart';
import '../messages/message_bubble.dart';
import '../messages/voice_note_recorder.dart';

class LobbyWidget extends StatefulWidget {
  const LobbyWidget({super.key});

  @override
  State<LobbyWidget> createState() => _LobbyWidgetState();
}

class _LobbyWidgetState extends State<LobbyWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isRecordingVoice = false;
  LobbyMessage? _replyToMessage;

  @override
  void initState() {
    super.initState();
    // Clean up old messages when lobby is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lobbyProvider = Provider.of<LobbyProvider>(context, listen: false);
      lobbyProvider.cleanupOldMessages();
    });
  }

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
      replyToId: _replyToMessage?.id,
      replyToContent: _replyToMessage?.content,
      replyToUserName: _replyToMessage?.userName,
    );

    _messageController.clear();
    setState(() => _replyToMessage = null);
    _scrollToBottom();
  }

  void _sendMediaMessage(String url, MediaType type) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final lobbyProvider = Provider.of<LobbyProvider>(context, listen: false);

    if (authProvider.appUser == null) return;

    String messageType;
    String content;

    switch (type) {
      case MediaType.gif:
        messageType = 'gif';
        content = _messageController.text.trim();
        break;
      case MediaType.image:
        messageType = 'image';
        content = _messageController.text.trim();
        break;
      case MediaType.sticker:
        messageType = 'sticker';
        content = url; // Emoji is the content
        break;
      default:
        messageType = 'text';
        content = url;
    }

    lobbyProvider.sendMessage(
      userId: authProvider.appUser!.uid,
      userName:
          authProvider.appUser!.displayName ?? authProvider.appUser!.email,
      userPhotoUrl: authProvider.appUser!.photoURL,
      content: content,
      messageType: messageType,
      mediaUrl: type != MediaType.sticker ? url : null,
      replyToId: _replyToMessage?.id,
      replyToContent: _replyToMessage?.content,
      replyToUserName: _replyToMessage?.userName,
    );

    _messageController.clear();
    setState(() => _replyToMessage = null);
    _scrollToBottom();
  }

  Future<void> _sendVoiceMessage(String filePath, int duration) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final lobbyProvider = Provider.of<LobbyProvider>(context, listen: false);

    if (authProvider.appUser == null) return;

    try {
      setState(() => _isRecordingVoice = false);

      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child(
        'voice_notes/${authProvider.appUser!.uid}/${DateTime.now().millisecondsSinceEpoch}.m4a',
      );

      await storageRef.putFile(File(filePath));
      final downloadUrl = await storageRef.getDownloadURL();

      // Delete local file
      try {
        await File(filePath).delete();
      } catch (e) {
        debugPrint('Error deleting temp file: $e');
      }

      // Send message
      await lobbyProvider.sendMessage(
        userId: authProvider.appUser!.uid,
        userName:
            authProvider.appUser!.displayName ?? authProvider.appUser!.email,
        userPhotoUrl: authProvider.appUser!.photoURL,
        content: _messageController.text.trim(),
        messageType: 'voice',
        mediaUrl: downloadUrl,
        voiceDuration: duration,
        replyToId: _replyToMessage?.id,
        replyToContent: _replyToMessage?.content,
        replyToUserName: _replyToMessage?.userName,
      );

      _messageController.clear();
      setState(() => _replyToMessage = null);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending voice note: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: AppTheme.errorRed,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Error loading messages',
                          style: TextStyle(
                            color: AppTheme.grey400,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: TextStyle(
                            color: AppTheme.grey600,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
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

                    return MessageBubble(
                      message: message,
                      isOwnMessage: isCurrentUser,
                      onDelete: () {
                        lobbyProvider.deleteMessage(
                          message.id,
                          authProvider.appUser!.uid,
                        );
                      },
                      onReaction: (emoji) {
                        lobbyProvider.toggleReaction(
                          message.id,
                          authProvider.appUser!.uid,
                          emoji,
                        );
                      },
                      onReply: () {
                        setState(() {
                          _replyToMessage = message;
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Voice note recorder or normal input
          if (_isRecordingVoice)
            VoiceNoteRecorder(
              onRecordComplete: _sendVoiceMessage,
              onCancel: () {
                setState(() => _isRecordingVoice = false);
              },
            )
          else
            Column(
              children: [
                // Reply preview
                if (_replyToMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.grey800,
                      borderRadius: BorderRadius.circular(8),
                      border: Border(
                        left: BorderSide(
                          color: AppTheme.primaryPurple,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.reply,
                                    size: 14,
                                    color: AppTheme.primaryPurple,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Replying to ${_replyToMessage!.userName}',
                                    style: TextStyle(
                                      color: AppTheme.primaryPurple,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _replyToMessage!.content,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppTheme.grey400,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            size: 18,
                            color: AppTheme.grey400,
                          ),
                          onPressed: () {
                            setState(() => _replyToMessage = null);
                          },
                        ),
                      ],
                    ),
                  ),

                // Message input
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.grey800,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.grey700),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (context) => MediaPickerBottomSheet(
                              onMediaSelected: (url, type) {
                                _sendMediaMessage(url, type);
                              },
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.add_circle_outline,
                          color: AppTheme.grey400,
                        ),
                        tooltip: 'Add media',
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() => _isRecordingVoice = true);
                        },
                        icon: Icon(Icons.mic, color: AppTheme.grey400),
                        tooltip: 'Record voice note',
                      ),
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
        ],
      ),
    );
  }
}
