import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/presence_model.dart';

/// Manages user presence and typing indicators
class PresenceProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Timer? _heartbeatTimer;
  final Map<String, UserPresence> _presenceCache = {};
  final Map<String, StreamSubscription> _presenceListeners = {};
  final Map<String, Set<String>> _typingUsers = {}; // conversationId -> userIds

  /// Initialize presence tracking for the current user
  Future<void> initializePresence(
    String userId, {
    String? currentActivity,
  }) async {
    try {
      // Set initial online status
      await updatePresence(
        userId,
        PresenceStatus.online,
        currentActivity: currentActivity,
      );

      // Set up heartbeat to keep presence updated
      _heartbeatTimer?.cancel();
      _heartbeatTimer = Timer.periodic(
        const Duration(minutes: 1),
        (_) => _sendHeartbeat(userId),
      );

      // Set up disconnect listener
      await _setupDisconnectHandler(userId);
    } catch (e) {
      debugPrint('❌ Error initializing presence: $e');
    }
  }

  /// Send heartbeat to keep online status
  Future<void> _sendHeartbeat(String userId) async {
    try {
      await _db.collection('presence').doc(userId).update({
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('⚠️ Heartbeat failed: $e');
    }
  }

  /// Set up handler to mark user offline on disconnect
  Future<void> _setupDisconnectHandler(String userId) async {
    try {
      // Note: Firestore doesn't have native disconnect handlers like Realtime DB
      // We rely on lastSeen timestamp + heartbeat to determine offline status
      // In a production app, you'd use Firebase Realtime Database for this
    } catch (e) {
      debugPrint('❌ Error setting up disconnect handler: $e');
    }
  }

  /// Update user presence status
  Future<void> updatePresence(
    String userId,
    PresenceStatus status, {
    String? currentActivity,
  }) async {
    try {
      final presence = UserPresence(
        userId: userId,
        status: status,
        lastSeen: DateTime.now(),
        currentActivity: currentActivity,
      );

      await _db
          .collection('presence')
          .doc(userId)
          .set(presence.toMap(), SetOptions(merge: true));

      _presenceCache[userId] = presence;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error updating presence: $e');
    }
  }

  /// Listen to a user's presence
  void listenToPresence(String userId) {
    if (_presenceListeners.containsKey(userId)) return;

    _presenceListeners[userId] = _db
        .collection('presence')
        .doc(userId)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            final presence = UserPresence.fromMap(snapshot.data()!, userId);
            _presenceCache[userId] = presence;
            notifyListeners();
          }
        });
  }

  /// Stop listening to a user's presence
  void stopListeningToPresence(String userId) {
    _presenceListeners[userId]?.cancel();
    _presenceListeners.remove(userId);
  }

  /// Get cached presence for a user
  UserPresence? getPresence(String userId) {
    return _presenceCache[userId];
  }

  /// Update typing indicator
  Future<void> setTyping(
    String userId,
    String conversationId,
    bool isTyping,
  ) async {
    try {
      if (isTyping) {
        await _db
            .collection('conversations')
            .doc(conversationId)
            .collection('typing')
            .doc(userId)
            .set({'userId': userId, 'timestamp': FieldValue.serverTimestamp()});
      } else {
        await _db
            .collection('conversations')
            .doc(conversationId)
            .collection('typing')
            .doc(userId)
            .delete();
      }
    } catch (e) {
      debugPrint('❌ Error updating typing indicator: $e');
    }
  }

  /// Listen to typing indicators in a conversation
  StreamSubscription listenToTyping(
    String conversationId,
    void Function(List<String> typingUserIds) onTypingChanged,
  ) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('typing')
        .snapshots()
        .listen((snapshot) {
          // Filter out stale typing indicators (older than 5 seconds)
          final now = DateTime.now();
          final typingUsers = snapshot.docs
              .where((doc) {
                final timestamp = doc.data()['timestamp'];
                if (timestamp == null) return false;
                final typingTime = (timestamp as Timestamp).toDate();
                return now.difference(typingTime).inSeconds < 5;
              })
              .map((doc) => doc.data()['userId'] as String)
              .toList();

          _typingUsers[conversationId] = typingUsers.toSet();
          onTypingChanged(typingUsers);
        });
  }

  /// Get list of users typing in a conversation
  List<String> getTypingUsers(String conversationId) {
    return _typingUsers[conversationId]?.toList() ?? [];
  }

  /// Mark user as offline
  Future<void> markOffline(String userId) async {
    await updatePresence(userId, PresenceStatus.offline);
    _heartbeatTimer?.cancel();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    for (final listener in _presenceListeners.values) {
      listener.cancel();
    }
    super.dispose();
  }
}
