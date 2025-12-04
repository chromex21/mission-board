import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/conversation_model.dart';

/// Simple local cache for messages using SharedPreferences
/// For production, consider using Hive or sqflite for better performance
class MessageCacheProvider extends ChangeNotifier {
  static const String _cachePrefix = 'msg_cache_';
  static const int _maxCachedMessages = 100; // Per conversation

  final Map<String, List<Message>> _cache = {};
  SharedPreferences? _prefs;

  /// Initialize cache
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      debugPrint('✅ Message cache initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize message cache: $e');
    }
  }

  /// Cache messages for a conversation
  Future<void> cacheMessages(
    String conversationId,
    List<Message> messages,
  ) async {
    try {
      _cache[conversationId] = messages;

      // Limit cache size
      final messagesToCache = messages.take(_maxCachedMessages).toList();

      // Serialize to JSON
      final jsonList = messagesToCache.map((msg) => msg.toMap()).toList();
      final jsonString = jsonEncode(jsonList);

      // Save to SharedPreferences
      await _prefs?.setString('$_cachePrefix$conversationId', jsonString);

      debugPrint(
        '📦 Cached ${messagesToCache.length} messages for $conversationId',
      );
    } catch (e) {
      debugPrint('❌ Failed to cache messages: $e');
    }
  }

  /// Get cached messages for a conversation
  List<Message>? getCachedMessages(String conversationId) {
    // Return from memory cache if available
    if (_cache.containsKey(conversationId)) {
      return _cache[conversationId];
    }

    // Try to load from SharedPreferences
    try {
      final jsonString = _prefs?.getString('$_cachePrefix$conversationId');
      if (jsonString == null) return null;

      final jsonList = jsonDecode(jsonString) as List;
      final messages = jsonList
          .map(
            (json) =>
                Message.fromMap(json as Map<String, dynamic>, json['id'] ?? ''),
          )
          .toList();

      _cache[conversationId] = messages;
      debugPrint(
        '📦 Loaded ${messages.length} cached messages for $conversationId',
      );
      return messages;
    } catch (e) {
      debugPrint('❌ Failed to load cached messages: $e');
      return null;
    }
  }

  /// Add a single message to cache (optimistic updates)
  Future<void> addMessageToCache(String conversationId, Message message) async {
    final cached =
        _cache[conversationId] ?? getCachedMessages(conversationId) ?? [];
    cached.insert(0, message); // Add to beginning (newest first)

    await cacheMessages(conversationId, cached);
  }

  /// Update message status in cache
  Future<void> updateMessageStatus(
    String conversationId,
    String messageId,
    MessageStatus status,
  ) async {
    final cached = _cache[conversationId] ?? getCachedMessages(conversationId);
    if (cached == null) return;

    final index = cached.indexWhere((msg) => msg.id == messageId);
    if (index == -1) return;

    // Create updated message (immutable)
    final updatedMessage = Message(
      id: cached[index].id,
      conversationId: cached[index].conversationId,
      senderId: cached[index].senderId,
      senderName: cached[index].senderName,
      content: cached[index].content,
      type: cached[index].type,
      timestamp: cached[index].timestamp,
      isRead: cached[index].isRead,
      readBy: cached[index].readBy,
      status: status,
      deliveredAt: status == MessageStatus.delivered
          ? DateTime.now()
          : cached[index].deliveredAt,
      readAt: status == MessageStatus.read
          ? DateTime.now()
          : cached[index].readAt,
      reactions: cached[index].reactions,
      replyTo: cached[index].replyTo,
      attachmentUrl: cached[index].attachmentUrl,
      metadata: cached[index].metadata,
    );

    cached[index] = updatedMessage;
    await cacheMessages(conversationId, cached);
    notifyListeners();
  }

  /// Clear cache for a conversation
  Future<void> clearCache(String conversationId) async {
    _cache.remove(conversationId);
    await _prefs?.remove('$_cachePrefix$conversationId');
    debugPrint('🗑️ Cleared cache for $conversationId');
  }

  /// Clear all caches
  Future<void> clearAllCaches() async {
    _cache.clear();
    final keys =
        _prefs?.getKeys().where((k) => k.startsWith(_cachePrefix)) ?? [];
    for (final key in keys) {
      await _prefs?.remove(key);
    }
    debugPrint('🗑️ Cleared all message caches');
  }
}
