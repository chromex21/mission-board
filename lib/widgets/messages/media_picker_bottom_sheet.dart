import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/theme/app_theme.dart';
import '../../config/api_config.dart';

// API key moved to config file for security
final String _tenorApiKey = ApiConfig.tenorApiKey;

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
  final TextEditingController _gifSearchController = TextEditingController();
  List<Map<String, dynamic>> _gifResults = [];
  bool _isLoadingGifs = false;
  bool _hasLoadedFirstGif = false;

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
    _loadTrendingGifs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    _gifSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadTrendingGifs() async {
    setState(() {
      _isLoadingGifs = true;
      _hasLoadedFirstGif = false;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://tenor.googleapis.com/v2/featured?key=$_tenorApiKey&limit=20&media_filter=gif,tinygif,nanogif,mediumgif',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Trending GIFs response: ${data.keys}');
        if (data['results'] != null) {
          final results = List<Map<String, dynamic>>.from(data['results']);
          debugPrint('Got ${results.length} trending GIFs');
          if (results.isNotEmpty) {
            debugPrint('First GIF keys: ${results.first.keys}');
            if (results.first['media_formats'] != null) {
              final mf = results.first['media_formats'] as Map;
              debugPrint('ALL TRENDING FORMATS AVAILABLE: ${mf.keys}');
              mf.forEach((format, data) {
                if (data is Map && data['url'] != null) {
                  debugPrint('  $format: ${data['url']}');
                }
              });
            }
          }
          setState(() {
            _gifResults = results;
            _isLoadingGifs = false;
          });
        } else {
          debugPrint('No results in trending response');
          setState(() => _isLoadingGifs = false);
        }
      } else {
        debugPrint('Trending API error: ${response.statusCode}');
        setState(() => _isLoadingGifs = false);
      }
    } catch (e) {
      debugPrint('Error loading trending GIFs: $e');
      setState(() => _isLoadingGifs = false);
    }
  }

  Future<void> _searchGifs(String query) async {
    if (query.trim().isEmpty) {
      _loadTrendingGifs();
      return;
    }

    setState(() {
      _isLoadingGifs = true;
      _hasLoadedFirstGif = false;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://tenor.googleapis.com/v2/search?q=${Uri.encodeComponent(query)}&key=$_tenorApiKey&limit=20&media_filter=gif,tinygif,nanogif,mediumgif',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Search GIFs response for "$query": ${data.keys}');
        if (data['results'] != null) {
          final results = List<Map<String, dynamic>>.from(data['results']);
          debugPrint('Got ${results.length} search results');
          if (results.isNotEmpty) {
            debugPrint('First result keys: ${results.first.keys}');
            if (results.first['media_formats'] != null) {
              final mf = results.first['media_formats'] as Map;
              debugPrint('ALL SEARCH FORMATS AVAILABLE: ${mf.keys}');
              mf.forEach((format, data) {
                if (data is Map && data['url'] != null) {
                  debugPrint('  $format: ${data['url']}');
                }
              });
            }
          }
          setState(() {
            _gifResults = results;
            _isLoadingGifs = false;
          });
        } else {
          debugPrint('No results for search query: $query');
          setState(() {
            _gifResults = [];
            _isLoadingGifs = false;
          });
        }
      } else {
        debugPrint(
          'Search API error: ${response.statusCode} - ${response.body}',
        );
        setState(() => _isLoadingGifs = false);
      }
    } catch (e) {
      debugPrint('Error searching GIFs: $e');
      setState(() => _isLoadingGifs = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching GIFs: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
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
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _gifSearchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search GIFs...',
              hintStyle: TextStyle(color: AppTheme.grey400),
              prefixIcon: Icon(Icons.search, color: AppTheme.grey400),
              suffixIcon: _gifSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: AppTheme.grey400),
                      onPressed: () {
                        _gifSearchController.clear();
                        setState(() => _gifResults = []);
                      },
                    )
                  : null,
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
                borderSide: BorderSide(color: AppTheme.primaryPurple, width: 2),
              ),
              isDense: true,
            ),
            onChanged: (value) {
              if (value.length >= 2) {
                _searchGifs(value);
              } else if (value.isEmpty) {
                _loadTrendingGifs();
              }
            },
          ),
        ),

        // Results or categories
        Expanded(
          child: Stack(
            children: [
              // Always build content so images can load
              if (_gifResults.isEmpty)
                _buildGifCategories()
              else
                _buildGifResults(),

              // Overlay loading indicator
              if (_isLoadingGifs ||
                  (_gifResults.isNotEmpty && !_hasLoadedFirstGif))
                Container(
                  color: AppTheme.grey900,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: AppTheme.primaryPurple,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading GIFs...',
                          style: TextStyle(
                            color: AppTheme.grey400,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGifCategories() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: _gifCategories.length,
      itemBuilder: (context, index) {
        final category = _gifCategories[index];
        return InkWell(
          onTap: () {
            _gifSearchController.text = category;
            _searchGifs(category);
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
                const Icon(Icons.gif_box, size: 32, color: Colors.white70),
                const SizedBox(height: 4),
                Text(
                  category,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGifResults() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: _gifResults.length,
      itemBuilder: (context, index) {
        final gif = _gifResults[index];

        // Tenor API v2 uses 'media_formats'
        final mediaFormats = gif['media_formats'] as Map<String, dynamic>?;

        // Try to get smallest/fastest loading format for preview
        final nanogif = mediaFormats?['nanogif'] as Map<String, dynamic>?;
        final tinygif = mediaFormats?['tinygif'] as Map<String, dynamic>?;
        final mediumgif = mediaFormats?['mediumgif'] as Map<String, dynamic>?;
        final gifFormat = mediaFormats?['gif'] as Map<String, dynamic>?;

        // Use smallest available for preview (faster loading)
        final previewUrl =
            nanogif?['url'] as String? ??
            tinygif?['url'] as String? ??
            mediumgif?['url'] as String? ??
            gifFormat?['url'] as String?;

        // Use full size for sending
        final fullUrl = gifFormat?['url'] as String? ?? previewUrl;

        // Skip if URL is missing
        if (previewUrl == null || fullUrl == null) {
          return const SizedBox.shrink();
        }

        return InkWell(
          onTap: () {
            widget.onMediaSelected(fullUrl, MediaType.gif);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              previewUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  // Mark that we've loaded at least one GIF
                  if (!_hasLoadedFirstGif) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() => _hasLoadedFirstGif = true);
                      }
                    });
                  }
                  return child;
                }
                return Container(
                  color: AppTheme.grey800,
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
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppTheme.grey800,
                child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.white54),
                ),
              ),
            ),
          ),
        );
      },
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
