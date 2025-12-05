import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../dialogs/tenor_gif_picker.dart';

/// Simplified message input for lobbies
/// ONLY supports: Text, Emoji, GIFs
/// No images, voice notes, or documents
class LobbyMessageInput extends StatefulWidget {
  final Function(String content, String messageType) onSendMessage;
  final bool canSendMessage;
  final Duration? cooldownRemaining;

  const LobbyMessageInput({
    super.key,
    required this.onSendMessage,
    required this.canSendMessage,
    this.cooldownRemaining,
  });

  @override
  State<LobbyMessageInput> createState() => _LobbyMessageInputState();
}

class _LobbyMessageInputState extends State<LobbyMessageInput> {
  final TextEditingController _controller = TextEditingController();
  bool _showEmojiPicker = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendTextMessage() {
    if (_controller.text.trim().isEmpty) return;
    if (!widget.canSendMessage) return;

    widget.onSendMessage(_controller.text.trim(), 'text');
    _controller.clear();
  }

  Future<void> _pickGif() async {
    final gifUrl = await showDialog<String>(
      context: context,
      builder: (context) => const TenorGifPicker(),
    );

    if (gifUrl != null && widget.canSendMessage) {
      widget.onSendMessage(gifUrl, 'gif');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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

                  // GIF picker button
                  IconButton(
                    icon: Icon(
                      Icons.gif_box,
                      color: AppTheme.infoBlue,
                      size: 28,
                    ),
                    onPressed: _pickGif,
                    tooltip: 'GIF',
                  ),

                  // Text input
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Message everyone...',
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
                          borderSide:
                              BorderSide(color: AppTheme.primaryPurple, width: 2),
                        ),
                        filled: true,
                        fillColor: AppTheme.grey900,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _sendTextMessage(),
                      onChanged: (_) => setState(() {}),
                      maxLines: null,
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Send button
                  IconButton(
                    icon: Icon(
                      Icons.send,
                      color: widget.canSendMessage && _controller.text.trim().isNotEmpty
                          ? AppTheme.primaryPurple
                          : AppTheme.grey600,
                    ),
                    onPressed: widget.canSendMessage && _controller.text.trim().isNotEmpty
                        ? _sendTextMessage
                        : null,
                    tooltip: _buildTooltip(),
                  ),
                ],
              ),
              // Emoji picker
              if (_showEmojiPicker)
                SizedBox(
                  height: 250,
                  child: EmojiPicker(
                    config: const Config(
                      height: 250,
                      checkPlatformCompatibility: false,
                      viewOrderConfig: ViewOrderConfig(),
                      skinToneConfig: SkinToneConfig(),
                      categoryViewConfig: CategoryViewConfig(),
                      bottomActionBarConfig: BottomActionBarConfig(),
                    ),
                    onEmojiSelected: (category, emoji) {
                      _controller.text += emoji.emoji;
                      setState(() {});
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
    if (!widget.canSendMessage) {
      final seconds = widget.cooldownRemaining?.inSeconds ?? 0;
      return 'Wait ${seconds}s';
    }
    if (_controller.text.trim().isEmpty) {
      return 'Type a message';
    }
    return 'Send message';
  }
}
