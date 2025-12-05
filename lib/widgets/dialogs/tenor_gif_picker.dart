import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/theme/app_theme.dart';
import '../../config/api_config.dart';

/// Simplified GIF picker dialog using Tenor API
/// For lobby messages (text + emoji + GIF only)
class TenorGifPicker extends StatefulWidget {
  const TenorGifPicker({super.key});

  @override
  State<TenorGifPicker> createState() => _TenorGifPickerState();
}

class _TenorGifPickerState extends State<TenorGifPicker> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _gifResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTrendingGifs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTrendingGifs() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse(
          'https://tenor.googleapis.com/v2/featured?key=${ApiConfig.tenorApiKey}&limit=30&media_filter=gif',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null) {
          setState(() {
            _gifResults = List<Map<String, dynamic>>.from(data['results']);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchGifs(String query) async {
    if (query.trim().isEmpty) {
      _loadTrendingGifs();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse(
          'https://tenor.googleapis.com/v2/search?q=${Uri.encodeComponent(query)}&key=${ApiConfig.tenorApiKey}&limit=30&media_filter=gif',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null) {
          setState(() {
            _gifResults = List<Map<String, dynamic>>.from(data['results']);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String? _getGifUrl(Map<String, dynamic> gif) {
    try {
      final mediaFormats = gif['media_formats'] as Map?;
      if (mediaFormats == null) return null;

      // Try to get the best format for web
      if (mediaFormats['mediumgif'] != null) {
        return mediaFormats['mediumgif']['url'];
      }
      if (mediaFormats['gif'] != null) {
        return mediaFormats['gif']['url'];
      }
      if (mediaFormats['tinygif'] != null) {
        return mediaFormats['tinygif']['url'];
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.grey900,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.gif_box, color: AppTheme.infoBlue, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Choose a GIF',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search bar
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search GIFs...',
                hintStyle: TextStyle(color: AppTheme.grey400),
                prefixIcon: Icon(Icons.search, color: AppTheme.grey400),
                filled: true,
                fillColor: AppTheme.grey800,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: _searchGifs,
            ),
            const SizedBox(height: 16),

            // GIF grid
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _gifResults.isEmpty
                      ? Center(
                          child: Text(
                            'No GIFs found',
                            style: TextStyle(color: AppTheme.grey400),
                          ),
                        )
                      : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _gifResults.length,
                          itemBuilder: (context, index) {
                            final gif = _gifResults[index];
                            final gifUrl = _getGifUrl(gif);

                            if (gifUrl == null) return const SizedBox.shrink();

                            return GestureDetector(
                              onTap: () => Navigator.pop(context, gifUrl),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  gifUrl,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return Container(
                                      color: AppTheme.grey800,
                                      child: const Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: AppTheme.grey800,
                                      child: Icon(
                                        Icons.broken_image,
                                        color: AppTheme.grey600,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
            ),

            // Footer with Tenor attribution
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Powered by',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.grey400,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Tenor',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
