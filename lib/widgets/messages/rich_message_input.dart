import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/messaging_provider.dart';
import '../../models/conversation_model.dart';

class RichMessageInput extends StatefulWidget {
  final String conversationId;
  final String recipientId;

  const RichMessageInput({
    super.key,
    required this.conversationId,
    required this.recipientId,
  });

  @override
  State<RichMessageInput> createState() => _RichMessageInputState();
}

class _RichMessageInputState extends State<RichMessageInput> {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _showEmojiPicker = false;
  bool _isUploading = false;

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
      );

      _messageController.clear();
      setState(() => _showEmojiPicker = false);
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
        await _uploadAndSendFile(image.path, MessageType.image);
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

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final filePath = kIsWeb ? null : file.path;

        if (filePath != null) {
          await _uploadAndSendFile(
            filePath,
            MessageType.file,
            fileName: file.name,
          );
        } else if (file.bytes != null) {
          // Web upload using bytes
          await _uploadAndSendFileWeb(file.bytes!, file.name, MessageType.file);
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

  Future<void> _uploadAndSendFile(
    String filePath,
    MessageType type, {
    String? fileName,
  }) async {
    setState(() => _isUploading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messagingProvider = Provider.of<MessagingProvider>(
      context,
      listen: false,
    );

    try {
      final file = File(filePath);
      final name = fileName ?? file.path.split('/').last;
      final storageRef = FirebaseStorage.instance.ref().child(
        'messages/${widget.conversationId}/${DateTime.now().millisecondsSinceEpoch}_$name',
      );

      final uploadTask = await storageRef.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      await messagingProvider.sendMessage(
        conversationId: widget.conversationId,
        senderId: authProvider.appUser!.uid,
        senderName: authProvider.appUser!.displayName ?? 'Unknown',
        content: downloadUrl,
        participants: [authProvider.appUser!.uid, widget.recipientId],
        type: type,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${type.name.toUpperCase()} sent successfully'),
            backgroundColor: AppTheme.successGreen,
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
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _uploadAndSendFileWeb(
    List<int> bytes,
    String fileName,
    MessageType type,
  ) async {
    setState(() => _isUploading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messagingProvider = Provider.of<MessagingProvider>(
      context,
      listen: false,
    );

    try {
      final storageRef = FirebaseStorage.instance.ref().child(
        'messages/${widget.conversationId}/${DateTime.now().millisecondsSinceEpoch}_$fileName',
      );

      final uploadTask = await storageRef.putData(Uint8List.fromList(bytes));
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      await messagingProvider.sendMessage(
        conversationId: widget.conversationId,
        senderId: authProvider.appUser!.uid,
        senderName: authProvider.appUser!.displayName ?? 'Unknown',
        content: downloadUrl,
        participants: [authProvider.appUser!.uid, widget.recipientId],
        type: type,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${type.name.toUpperCase()} sent successfully'),
            backgroundColor: AppTheme.successGreen,
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
        setState(() => _isUploading = false);
      }
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.grey900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image, color: AppTheme.infoBlue),
                title: const Text('Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.attach_file,
                  color: AppTheme.primaryPurple,
                ),
                title: const Text('File'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile();
                },
              ),
            ],
          ),
        ),
      ),
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

        // Message input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.grey900,
            border: Border(top: BorderSide(color: AppTheme.grey700)),
          ),
          child: _isUploading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('Uploading...'),
                      ],
                    ),
                  ),
                )
              : Row(
                  children: [
                    // Attachment button
                    IconButton(
                      onPressed: _showAttachmentOptions,
                      icon: const Icon(Icons.add_circle_outline),
                      color: AppTheme.grey400,
                    ),

                    // Emoji button
                    IconButton(
                      onPressed: () {
                        setState(() => _showEmojiPicker = !_showEmojiPicker);
                      },
                      icon: Icon(
                        _showEmojiPicker
                            ? Icons.keyboard
                            : Icons.emoji_emotions_outlined,
                      ),
                      color: _showEmojiPicker
                          ? AppTheme.primaryPurple
                          : AppTheme.grey400,
                    ),

                    const SizedBox(width: 8),

                    // Text input
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: AppTheme.grey400),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: AppTheme.grey800,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendTextMessage(),
                        onTap: () {
                          if (_showEmojiPicker) {
                            setState(() => _showEmojiPicker = false);
                          }
                        },
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Send button
                    IconButton(
                      onPressed: _sendTextMessage,
                      icon: const Icon(Icons.send),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.primaryPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
