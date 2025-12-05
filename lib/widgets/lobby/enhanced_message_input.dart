import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'dart:io';
import '../../core/theme/app_theme.dart';

/// Enhanced message input with media support
/// - Text messages
/// - Image/GIF uploads
/// - Voice notes (record & send)
/// - Document sharing
/// - Emoji picker
class EnhancedMessageInput extends StatefulWidget {
  final Function(String content, String messageType, String? filePath)
  onSendMessage;
  final bool canSendMessage;
  final Duration? cooldownRemaining;

  const EnhancedMessageInput({
    super.key,
    required this.onSendMessage,
    required this.canSendMessage,
    this.cooldownRemaining,
  });

  @override
  State<EnhancedMessageInput> createState() => _EnhancedMessageInputState();
}

class _EnhancedMessageInputState extends State<EnhancedMessageInput> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _showEmojiPicker = false;
  String? _selectedImagePath;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (image != null) {
        setState(() => _selectedImagePath = image.path);
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _pickGif() async {
    // For now, open file picker to select GIF
    // In production, you'd integrate with Giphy API
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowedExtensions: ['gif'],
      );
      if (result != null) {
        setState(() => _selectedImagePath = result.files.single.path);
      }
    } catch (e) {
      _showError('Failed to pick GIF: $e');
    }
  }

  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        final fileName = result.files.single.name;
        if (widget.canSendMessage) {
          widget.onSendMessage(fileName, 'document', result.files.single.path);
        }
      }
    } catch (e) {
      _showError('Failed to pick document: $e');
    }
  }

  void _sendTextMessage() {
    if (_controller.text.isEmpty) return;
    if (!widget.canSendMessage) return;

    widget.onSendMessage(_controller.text, 'text', null);
    _controller.clear();
    setState(() => _selectedImagePath = null);
  }

  void _sendImageMessage() {
    if (_selectedImagePath == null) return;
    if (!widget.canSendMessage) return;

    widget.onSendMessage('Image shared', 'image', _selectedImagePath);
    setState(() => _selectedImagePath = null);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.errorRed),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Selected image preview
        if (_selectedImagePath != null)
          Container(
            height: 120,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.grey700),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                Image.file(
                  File(_selectedImagePath!),
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedImagePath = null),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.grey900.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Message input row
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.grey800,
            border: Border(top: BorderSide(color: AppTheme.grey700)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Emoji picker button
                  IconButton(
                    icon: const Text('😊', style: TextStyle(fontSize: 20)),
                    onPressed: () {
                      setState(() => _showEmojiPicker = !_showEmojiPicker);
                    },
                    tooltip: 'Emoji',
                  ),

                  // Image picker button
                  IconButton(
                    icon: Icon(
                      Icons.image,
                      color: _selectedImagePath != null
                          ? AppTheme.primaryPurple
                          : AppTheme.grey400,
                    ),
                    onPressed: _pickImage,
                    tooltip: 'Image',
                  ),

                  // GIF picker button
                  IconButton(
                    icon: Icon(Icons.gif_box, color: AppTheme.grey400),
                    onPressed: _pickGif,
                    tooltip: 'GIF',
                  ),

                  // Document picker button
                  IconButton(
                    icon: Icon(Icons.description, color: AppTheme.grey400),
                    onPressed: _pickDocument,
                    tooltip: 'Document',
                  ),

                  // Text input
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: _selectedImagePath != null
                            ? 'Add a caption...'
                            : 'Message everyone...',
                        hintStyle: TextStyle(color: AppTheme.grey400),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppTheme.grey700),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppTheme.grey700),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppTheme.primaryPurple,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: AppTheme.grey900,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _sendTextMessage(),
                      maxLines: null,
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Send button
                  if (_selectedImagePath == null)
                    IconButton(
                      icon: Icon(
                        Icons.send,
                        color:
                            widget.canSendMessage && _controller.text.isNotEmpty
                            ? AppTheme.primaryPurple
                            : AppTheme.grey600,
                      ),
                      onPressed:
                          widget.canSendMessage && _controller.text.isNotEmpty
                          ? _sendTextMessage
                          : null,
                      tooltip: _buildTooltip(),
                    )
                  else
                    IconButton(
                      icon: Icon(
                        Icons.check_circle,
                        color: widget.canSendMessage
                            ? AppTheme.successGreen
                            : AppTheme.grey600,
                      ),
                      onPressed: widget.canSendMessage
                          ? _sendImageMessage
                          : null,
                      tooltip: 'Send image',
                    ),
                ],
              ),
              // Emoji picker
              if (_showEmojiPicker)
                SizedBox(
                  height: 250,
                  child: EmojiPicker(
                    config: Config(
                      height: 250,
                      checkPlatformCompatibility: false,
                      viewOrderConfig: const ViewOrderConfig(),
                      skinToneConfig: const SkinToneConfig(),
                      categoryViewConfig: const CategoryViewConfig(),
                      bottomActionBarConfig: const BottomActionBarConfig(),
                    ),
                    onEmojiSelected: (category, emoji) {
                      _controller.text += emoji.emoji;
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _buildTooltip() {
    if (widget.canSendMessage) {
      return 'Send message';
    }
    final seconds = widget.cooldownRemaining?.inSeconds ?? 0;
    return 'Wait ${seconds}s';
  }
}
