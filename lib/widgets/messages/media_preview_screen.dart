import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/theme/app_theme.dart';

class MediaPreviewScreen extends StatefulWidget {
  final dynamic imageFile; // File or Uint8List
  final String fileName;
  final bool isWeb;

  const MediaPreviewScreen({
    super.key,
    required this.imageFile,
    required this.fileName,
    this.isWeb = false,
  });

  @override
  State<MediaPreviewScreen> createState() => _MediaPreviewScreenState();
}

class _MediaPreviewScreenState extends State<MediaPreviewScreen> {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  bool _showTextEditor = false;
  String? _overlayText;
  Offset _textPosition = const Offset(50, 50);
  Color _textColor = Colors.white;
  double _textSize = 24;

  @override
  void dispose() {
    _captionController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Widget _buildImagePreview() {
    if (widget.isWeb && widget.imageFile is Uint8List) {
      return Image.memory(widget.imageFile as Uint8List, fit: BoxFit.contain);
    } else if (widget.imageFile is File) {
      return Image.file(widget.imageFile as File, fit: BoxFit.contain);
    } else if (widget.imageFile is String) {
      return Image.network(widget.imageFile as String, fit: BoxFit.contain);
    } else {
      return const Center(child: Text('Invalid image format'));
    }
  }

  void _addTextOverlay() {
    setState(() {
      _showTextEditor = true;
    });
  }

  void _confirmTextOverlay() {
    setState(() {
      _overlayText = _textController.text;
      _showTextEditor = false;
      _textController.clear();
    });
  }

  void _sendMedia() {
    Navigator.pop(context, {
      'caption': _captionController.text.trim(),
      'overlayText': _overlayText,
      'textPosition': _textPosition,
      'textColor': _textColor,
      'textSize': _textSize,
      'confirmed': true,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.fileName,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_fields, color: Colors.white),
            tooltip: 'Add text',
            onPressed: _addTextOverlay,
          ),
          IconButton(
            icon: const Icon(Icons.crop, color: Colors.white),
            tooltip: 'Crop (coming soon)',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Crop feature coming soon!'),
                  backgroundColor: AppTheme.infoBlue,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.white),
            tooltip: 'Filters (coming soon)',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Filters coming soon!'),
                  backgroundColor: AppTheme.infoBlue,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Image preview area
          Expanded(
            child: Stack(
              children: [
                // Main image
                Center(child: _buildImagePreview()),

                // Text overlay
                if (_overlayText != null && _overlayText!.isNotEmpty)
                  Positioned(
                    left: _textPosition.dx,
                    top: _textPosition.dy,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          _textPosition = Offset(
                            _textPosition.dx + details.delta.dx,
                            _textPosition.dy + details.delta.dy,
                          );
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _overlayText!,
                              style: TextStyle(
                                color: _textColor,
                                fontSize: _textSize,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    blurRadius: 4,
                                    color: Colors.black.withOpacity(0.7),
                                    offset: const Offset(2, 2),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              color: Colors.white,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setState(() => _overlayText = null);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Text editor overlay
                if (_showTextEditor)
                  Container(
                    color: Colors.black87,
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Add text to image',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: TextField(
                              controller: _textController,
                              autofocus: true,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Type your text...',
                                hintStyle: TextStyle(color: Colors.white54),
                                filled: true,
                                fillColor: Colors.white12,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Color picker
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildColorButton(Colors.white),
                              _buildColorButton(Colors.black),
                              _buildColorButton(Colors.red),
                              _buildColorButton(Colors.blue),
                              _buildColorButton(Colors.green),
                              _buildColorButton(Colors.yellow),
                              _buildColorButton(Colors.purple),
                              _buildColorButton(Colors.orange),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Text size slider
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.text_fields,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                Expanded(
                                  child: Slider(
                                    value: _textSize,
                                    min: 12,
                                    max: 48,
                                    divisions: 18,
                                    activeColor: AppTheme.primaryPurple,
                                    onChanged: (value) {
                                      setState(() => _textSize = value);
                                    },
                                  ),
                                ),
                                const Icon(
                                  Icons.text_fields,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _showTextEditor = false;
                                    _textController.clear();
                                  });
                                },
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: _confirmTextOverlay,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryPurple,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Add Text'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Caption input and send button
          Container(
            color: Colors.black,
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _captionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Add a caption...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white12,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FloatingActionButton(
                    onPressed: _sendMedia,
                    backgroundColor: AppTheme.primaryPurple,
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    final isSelected = _textColor == color;
    return GestureDetector(
      onTap: () => setState(() => _textColor = color),
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppTheme.primaryPurple : Colors.white,
            width: isSelected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}
