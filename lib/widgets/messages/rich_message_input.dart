import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/messaging_provider.dart';
import '../../models/conversation_model.dart';
import 'media_picker_bottom_sheet.dart';
import 'media_preview_screen.dart';
import 'voice_note_recorder.dart';

class RichMessageInput extends StatefulWidget {
  final String conversationId;
  final String recipientId;
  final Message? replyingTo;
  final VoidCallback? onReplyCleared;

  const RichMessageInput({
    super.key,
    required this.conversationId,
    required this.recipientId,
    this.replyingTo,
    this.onReplyCleared,
  });

  @override
  State<RichMessageInput> createState() => _RichMessageInputState();
}

class _RichMessageInputState extends State<RichMessageInput> {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _showEmojiPicker = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendTextMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messagingProvider = Provider.of<MessagingProvider>(
      context,
      listen: false,
    );
    final currentUser = authProvider.appUser!;

    try {
      await messagingProvider.sendMessage(
        conversationId: widget.conversationId,
        senderId: currentUser.uid,
        senderName: currentUser.displayName ?? 'Unknown',
        content: text,
        participants: [currentUser.uid, widget.recipientId],
        type: MessageType.text,
        replyTo: _buildReplyPayload(),
      );

      _messageController.clear();
      setState(() => _showEmojiPicker = false);
      widget.onReplyCleared?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        // Show preview with editor
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MediaPreviewScreen(
              imageFile: File(image.path),
              fileName: image.name,
            ),
          ),
        );

        if (result != null && result['confirmed'] == true) {
          await _uploadAndSendFile(
            image.path,
            MessageType.image,
            caption: result['caption'],
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _recordVoiceNote() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => VoiceNoteRecorder(
        onRecordComplete: (filePath, duration) async {
          if (mounted) {
            Navigator.pop(dialogContext);
            await _uploadAndSendFile(
              filePath,
              MessageType.voice,
              fileName:
                  'voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a',
            );
          }
        },
        onCancel: () {
          if (mounted) {
            Navigator.pop(dialogContext);
          }
        },
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final filePath = file.path;

        if (filePath != null) {
          await _uploadAndSendFile(
            filePath,
            MessageType.file,
            fileName: file.name,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickGif() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MediaPickerBottomSheet(
        onMediaSelected: (url, type) async {
          final nav = Navigator.of(context);
          await _sendGif(url);
          if (mounted) nav.pop();
        },
      ),
    );
  }

  Future<void> _sendGif(String gifUrl) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messagingProvider = Provider.of<MessagingProvider>(
      context,
      listen: false,
    );
    final currentUser = authProvider.appUser!;

    try {
      await messagingProvider.sendMessage(
        conversationId: widget.conversationId,
        senderId: currentUser.uid,
        senderName: currentUser.displayName ?? 'Unknown',
        content: gifUrl,
        participants: [currentUser.uid, widget.recipientId],
        type: MessageType.gif,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GIF sent successfully'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send GIF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadAndSendFile(
    String filePath,
    MessageType type, {
    String? fileName,
    String? caption,
  }) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Preparing...';
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messagingProvider = Provider.of<MessagingProvider>(
      context,
      listen: false,
    );

    try {
      final file = File(filePath);
      final name = fileName ?? p.basename(file.path);
      final storageRef = FirebaseStorage.instance.ref().child(
        'messages/${widget.conversationId}/${DateTime.now().millisecondsSinceEpoch}_$name',
      );

      setState(() => _uploadStatus = 'Uploading...');

      // Upload with progress tracking
      String? contentType;
      if (type == MessageType.image) {
        contentType = 'image/jpeg';
      } else if (type == MessageType.gif) {
        contentType = 'image/gif';
      } else if (type == MessageType.file) {
        contentType = 'application/octet-stream';
      }

      final uploadTask = storageRef.putFile(
        file,
        SettableMetadata(contentType: contentType),
      );

      uploadTask.snapshotEvents.listen((taskSnapshot) {
        if (mounted) {
          setState(() {
            _uploadProgress =
                taskSnapshot.bytesTransferred / taskSnapshot.totalBytes;
          });
        }
      });

      await uploadTask;
      setState(() => _uploadStatus = 'Getting URL...');

      // Get the actual storage path from the reference
      final storagePath = storageRef.fullPath;

      setState(() => _uploadStatus = 'Sending message...');

      // Send message with caption if provided
      final messageContent = caption != null && caption.isNotEmpty
          ? '$storagePath|caption:$caption'
          : storagePath;

      debugPrint('[_uploadAndSendFile] Storing storage path: $storagePath');

      await messagingProvider.sendMessage(
        conversationId: widget.conversationId,
        senderId: authProvider.appUser!.uid,
        senderName: authProvider.appUser!.displayName ?? 'Unknown',
        content: messageContent,
        participants: [authProvider.appUser!.uid, widget.recipientId],
        type: type,
        replyTo: _buildReplyPayload(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${type.name.toUpperCase()} sent successfully'),
            backgroundColor: AppTheme.successGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload ${type.name}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
          _uploadStatus = '';
        });
        widget.onReplyCleared?.call();
      }
    }
  }

  MessageReply? _buildReplyPayload() {
    final source = widget.replyingTo;
    if (source == null) return null;

    return MessageReply(
      messageId: source.id,
      senderId: source.senderId,
      senderName: source.senderName,
      content: source.content,
      type: source.type,
    );
  }

  void _onEmojiSelected(Emoji emoji) {
    _messageController.text += emoji.emoji;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Emoji picker
        if (_showEmojiPicker)
          SizedBox(
            height: 250,
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) => _onEmojiSelected(emoji),
              config: Config(
                emojiViewConfig: EmojiViewConfig(
                  backgroundColor: AppTheme.grey900,
                  columns: 7,
                  emojiSizeMax: 32,
                  verticalSpacing: 0,
                  horizontalSpacing: 0,
                ),
              ),
            ),
          ),

        // Upload progress indicator
        if (_isUploading)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.grey900,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryPurple,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _uploadStatus,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: AppTheme.grey400,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: _uploadProgress,
                    backgroundColor: AppTheme.grey800,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryPurple,
                    ),
                    minHeight: 3,
                  ),
                ),
              ],
            ),
          ),

        // Message input bar - Modern WhatsApp style
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.grey900,
            border: Border(top: BorderSide(color: AppTheme.grey700)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Voice note button
                Tooltip(
                  message: 'Voice note',
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: IconButton(
                      onPressed: _recordVoiceNote,
                      icon: const Icon(Icons.mic),
                      color: AppTheme.errorRed,
                      iconSize: 22,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),

                // Attachment button (now includes photos)
                Tooltip(
                  message: 'Attach photo, file, or GIF',
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: IconButton(
                      onPressed: _showAttachmentMenu,
                      icon: const Icon(Icons.attach_file),
                      color: AppTheme.infoBlue,
                      iconSize: 22,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),

                // Message input field
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.grey800,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        // Emoji button
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: IconButton(
                            onPressed: () {
                              setState(
                                () => _showEmojiPicker = !_showEmojiPicker,
                              );
                            },
                            icon: Icon(
                              _showEmojiPicker
                                  ? Icons.keyboard
                                  : Icons.emoji_emotions_outlined,
                            ),
                            color: _showEmojiPicker
                                ? AppTheme.primaryPurple
                                : AppTheme.grey400,
                            iconSize: 20,
                            padding: EdgeInsets.zero,
                          ),
                        ),

                        // Text input
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Message...',
                              hintStyle: TextStyle(color: AppTheme.grey400),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 10,
                              ),
                            ),
                            maxLines: null,
                            minLines: 1,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendTextMessage(),
                            onTap: () {
                              if (_showEmojiPicker) {
                                setState(() => _showEmojiPicker = false);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Send button
                Tooltip(
                  message: 'Send message',
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: IconButton(
                      onPressed: _sendTextMessage,
                      icon: const Icon(Icons.send),
                      color: AppTheme.primaryPurple,
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.grey900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle indicator
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.grey600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.image,
                    color: AppTheme.primaryPurple,
                  ),
                  title: const Text('Photo'),
                  subtitle: const Text('Pick from gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.gif_box,
                    color: AppTheme.successGreen,
                  ),
                  title: const Text('GIF'),
                  subtitle: const Text('Search GIF library'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickGif();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.attach_file,
                    color: AppTheme.infoBlue,
                  ),
                  title: const Text('Document'),
                  subtitle: const Text('PDF, Word, Excel, etc.'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickFile();
                  },
                ),
                const Divider(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    '💡 Quick Tip: Click the voice button next to the menu for instant voice notes',
                    style: TextStyle(
                      color: AppTheme.grey400,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
