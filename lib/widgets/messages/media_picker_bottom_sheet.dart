import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class MediaPickerBottomSheet extends StatefulWidget {
  final Function(String url, MediaType type) onMediaSelected;

  const MediaPickerBottomSheet({super.key, required this.onMediaSelected});

  @override
  State<MediaPickerBottomSheet> createState() => _MediaPickerBottomSheetState();
}

class _MediaPickerBottomSheetState extends State<MediaPickerBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _urlController = TextEditingController();

  // Popular GIF categories
  final List<String> _gifCategories = [
    'happy',
    'excited',
    'thumbs up',
    'dancing',
    'laughing',
    'crying',
    'angry',
    'confused',
    'shocked',
    'love',
    'clapping',
    'waving',
    'celebrating',
    'thinking',
    'sleeping',
  ];

  // Common sticker/emoji collections
  final List<String> _stickerEmojis = [
    '😀',
    '😂',
    '🤣',
    '😊',
    '😍',
    '🥰',
    '😘',
    '😎',
    '🤗',
    '🤔',
    '😴',
    '😪',
    '🥺',
    '😭',
    '😡',
    '🤬',
    '😱',
    '😨',
    '🤯',
    '😳',
    '🥳',
    '🤩',
    '😇',
    '🤠',
    '🥶',
    '🥵',
    '🤧',
    '🤮',
    '🤢',
    '🤑',
    '👍',
    '👎',
    '👏',
    '🙏',
    '💪',
    '🔥',
    '💯',
    '✨',
    '⭐',
    '❤️',
    '🎉',
    '🎊',
    '🎈',
    '🎁',
    '🏆',
    '🥇',
    '🎯',
    '🚀',
    '💡',
    '⚡',
    '😂😂😂',
    '🔥🔥🔥',
    '💯💯',
    '👏👏👏',
    '❤️❤️',
    '😍😍😍',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: AppTheme.grey900,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.grey600,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryPurple,
            unselectedLabelColor: AppTheme.grey400,
            indicatorColor: AppTheme.primaryPurple,
            tabs: const [
              Tab(icon: Icon(Icons.gif_box), text: 'GIFs'),
              Tab(icon: Icon(Icons.emoji_emotions), text: 'Stickers'),
              Tab(icon: Icon(Icons.link), text: 'URL'),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildGifTab(), _buildStickerTab(), _buildUrlTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGifTab() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          margin: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.warningOrange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.warningOrange.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.warning, color: AppTheme.warningOrange, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'GIF integration requires Tenor API key. Please configure in settings.',
                  style: TextStyle(color: AppTheme.warningOrange, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: _gifCategories.length,
            itemBuilder: (context, index) {
              final category = _gifCategories[index];
              return InkWell(
                onTap: () {
                  // TODO: Replace with actual Tenor API integration
                  // For now, this is a placeholder that won't show real GIFs
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'GIF feature requires Tenor API configuration',
                      ),
                      backgroundColor: AppTheme.warningOrange,
                    ),
                  );
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.grey800,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.grey700),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.gif_box,
                        size: 32,
                        color: Colors.white70,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStickerTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: _stickerEmojis.length,
      itemBuilder: (context, index) {
        final emoji = _stickerEmojis[index];
        return InkWell(
          onTap: () {
            widget.onMediaSelected(emoji, MediaType.sticker);
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.grey800,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUrlTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _urlController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Paste image or GIF URL...',
              hintStyle: TextStyle(color: AppTheme.grey400),
              filled: true,
              fillColor: AppTheme.grey800,
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
                borderSide: BorderSide(color: AppTheme.primaryPurple),
              ),
              prefixIcon: const Icon(Icons.link, color: Colors.white70),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final url = _urlController.text.trim();
                if (url.isNotEmpty &&
                    Uri.tryParse(url)?.hasAbsolutePath == true) {
                  final isGif = url.toLowerCase().endsWith('.gif');
                  widget.onMediaSelected(
                    url,
                    isGif ? MediaType.gif : MediaType.image,
                  );
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.send),
              label: const Text('Send'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Supported: JPEG, PNG, GIF\nExample: https://example.com/image.gif',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.grey400, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

enum MediaType { text, image, gif, sticker }
