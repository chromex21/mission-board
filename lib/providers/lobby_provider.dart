import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lobby_message_model.dart';
import '../models/lobby_model.dart';

class LobbyProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<LobbyMessage> _messages = [];
  bool isLoading = false;
  String? errorMessage;

  // Rate limiting
  DateTime? _lastMessageTime;
  static const Duration _messageInterval = Duration(seconds: 2);

  List<LobbyMessage> get messages => _messages;

  bool get canSendMessage {
    if (_lastMessageTime == null) return true;
    final diff = DateTime.now().difference(_lastMessageTime!);
    return diff >= _messageInterval;
  }

  Duration? get timeUntilNextMessage {
    if (canSendMessage) return null;
    final diff = DateTime.now().difference(_lastMessageTime!);
    return _messageInterval - diff;
  }

  // Stream lobby messages
  Stream<List<LobbyMessage>> streamLobbyMessages() {
    return _db
        .collection('lobby')
        .orderBy('createdAt', descending: false)
        .limit(100)
        .snapshots()
        .handleError((error) {
          debugPrint('❌ Lobby stream error: $error');
          errorMessage = error.toString();
          notifyListeners();
        })
        .map((snapshot) {
          try {
            debugPrint('📨 Processing ${snapshot.docs.length} lobby messages');
            _messages = snapshot.docs
                .map((doc) {
                  try {
                    final msg = LobbyMessage.fromFirestore(doc);
                    debugPrint(
                      '✅ Parsed message ${doc.id}: ${msg.content.substring(0, msg.content.length > 20 ? 20 : msg.content.length)}...',
                    );
                    return msg;
                  } catch (e) {
                    debugPrint('❌ Error parsing message ${doc.id}: $e');
                    debugPrint('   Data: ${doc.data()}');
                    return null;
                  }
                })
                .whereType<LobbyMessage>()
                .toList();
            debugPrint('✅ Returned ${_messages.length} valid messages');
            return _messages;
          } catch (e) {
            debugPrint('❌ Error mapping snapshot: $e');
            return <LobbyMessage>[];
          }
        });
  }

  // Send message to lobby
  Future<LobbyMessage?> sendMessage({
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required String content,
    String? missionId,
    String? missionTitle,
    String messageType = 'text',
    String? mediaUrl,
    int? voiceDuration,
    String? replyToId,
    String? replyToContent,
    String? replyToUserName,
  }) async {
    try {
      final mentions = LobbyMessage.extractMentions(content);

      final message = LobbyMessage(
        id: '',
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        content: content,
        mentions: mentions,
        missionId: missionId,
        missionTitle: missionTitle,
        createdAt: DateTime.now(),
        messageType: messageType,
        mediaUrl: mediaUrl,
        voiceDuration: voiceDuration,
        replyToId: replyToId,
        replyToContent: replyToContent,
        replyToUserName: replyToUserName,
      );

      final docRef = await _db
          .collection('lobby')
          .add(message.toMap(useServerTimestamp: false));
      return LobbyMessage(
        id: docRef.id,
        userId: message.userId,
        userName: message.userName,
        userPhotoUrl: message.userPhotoUrl,
        content: message.content,
        mentions: message.mentions,
        missionId: message.missionId,
        missionTitle: message.missionTitle,
        createdAt: DateTime.now(), // Optimistic local time
        messageType: message.messageType,
        mediaUrl: message.mediaUrl,
        voiceDuration: message.voiceDuration,
        replyToId: message.replyToId,
        replyToContent: message.replyToContent,
        replyToUserName: message.replyToUserName,
      );
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Delete message (only own messages)
  Future<void> deleteMessage(String messageId, String userId) async {
    try {
      final doc = await _db.collection('lobby').doc(messageId).get();
      if (doc.exists && doc.data()?['userId'] == userId) {
        await doc.reference.delete();
      }
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Add or remove reaction from a message
  Future<void> toggleReaction(
    String messageId,
    String userId,
    String emoji,
  ) async {
    try {
      final docRef = _db.collection('lobby').doc(messageId);
      final doc = await docRef.get();

      if (!doc.exists) return;

      final data = doc.data();
      Map<String, dynamic> reactions = Map<String, dynamic>.from(
        data?['reactions'] ?? {},
      );

      if (reactions.containsKey(emoji)) {
        List<String> users = List<String>.from(reactions[emoji] ?? []);
        if (users.contains(userId)) {
          users.remove(userId);
          if (users.isEmpty) {
            reactions.remove(emoji);
          } else {
            reactions[emoji] = users;
          }
        } else {
          users.add(userId);
          reactions[emoji] = users;
        }
      } else {
        reactions[emoji] = [userId];
      }

      await docRef.update({'reactions': reactions});
    } catch (e) {
      debugPrint('❌ Error toggling reaction: $e');
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Clean up old messages (older than 12 hours)
  Future<void> cleanupOldMessages() async {
    try {
      final cutoffTime = DateTime.now().subtract(const Duration(hours: 12));
      final cutoffTimestamp = Timestamp.fromDate(cutoffTime);

      final oldMessages = await _db
          .collection('lobby')
          .where('createdAt', isLessThan: cutoffTimestamp)
          .get();

      // Delete old messages in batch
      final batch = _db.batch();
      for (var doc in oldMessages.docs) {
        batch.delete(doc.reference);
      }

      if (oldMessages.docs.isNotEmpty) {
        await batch.commit();
        debugPrint(
          '🗑️ Cleaned up ${oldMessages.docs.length} old lobby messages',
        );
      }
    } catch (e) {
      debugPrint('❌ Error cleaning up old messages: $e');
    }
  }

  // Send system message (join/leave/welcome etc.)
  Future<void> sendSystemMessage({
    required String lobbyId,
    required String content,
    required String systemType,
    Map<String, dynamic>? systemData,
  }) async {
    try {
      final message = LobbyMessage(
        id: '',
        userId: 'system',
        userName: 'System',
        content: content,
        createdAt: DateTime.now(),
        messageType: 'system',
        systemType: systemType,
        systemData: systemData,
      );

      await _db
          .collection('lobbies')
          .doc(lobbyId)
          .collection('messages')
          .add(message.toMap(useServerTimestamp: false));
    } catch (e) {
      debugPrint('❌ Error sending system message: $e');
    }
  }

  // Stream all lobbies
  Stream<List<Lobby>> streamLobbies() {
    return _db
        .collection('lobbies')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                try {
                  return Lobby.fromFirestore(doc);
                } catch (e) {
                  debugPrint('❌ Error parsing lobby ${doc.id}: $e');
                  return null;
                }
              })
              .whereType<Lobby>()
              .toList();
        });
  }

  // Get lobby by ID
  Future<Lobby?> getLobby(String lobbyId) async {
    try {
      final doc = await _db.collection('lobbies').doc(lobbyId).get();
      if (doc.exists) {
        return Lobby.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting lobby: $e');
      return null;
    }
  }

  // Join lobby (create user presence)
  Future<void> joinLobby({
    required String lobbyId,
    required String userId,
    required String displayName,
    String? photoURL,
    required LobbyRank rank,
  }) async {
    try {
      final lobbyUser = LobbyUser(
        uid: userId,
        displayName: displayName,
        photoURL: photoURL,
        rank: rank,
        joinedAt: DateTime.now(),
        lastSeen: DateTime.now(),
      );

      // Update user presence
      await _db
          .collection('lobbies')
          .doc(lobbyId)
          .collection('users')
          .doc(userId)
          .set(lobbyUser.toMap());

      // Update online count
      await _db.collection('lobbies').doc(lobbyId).update({
        'onlineCount': FieldValue.increment(1),
      });

      // Send join system message
      await sendSystemMessage(
        lobbyId: lobbyId,
        content: '$displayName joined the lobby',
        systemType: 'join',
        systemData: {'userId': userId, 'displayName': displayName},
      );
    } catch (e) {
      debugPrint('❌ Error joining lobby: $e');
    }
  }

  // Leave lobby
  Future<void> leaveLobby({
    required String lobbyId,
    required String userId,
    required String displayName,
  }) async {
    try {
      // Remove user presence
      await _db
          .collection('lobbies')
          .doc(lobbyId)
          .collection('users')
          .doc(userId)
          .delete();

      // Update online count
      await _db.collection('lobbies').doc(lobbyId).update({
        'onlineCount': FieldValue.increment(-1),
      });

      // Send leave system message
      await sendSystemMessage(
        lobbyId: lobbyId,
        content: '$displayName left the lobby',
        systemType: 'leave',
        systemData: {'userId': userId, 'displayName': displayName},
      );
    } catch (e) {
      debugPrint('❌ Error leaving lobby: $e');
    }
  }

  // Stream lobby messages for specific lobby
  Stream<List<LobbyMessage>> streamLobbyMessagesForLobby(String lobbyId) {
    return _db
        .collection('lobbies')
        .doc(lobbyId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .limit(200)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                try {
                  return LobbyMessage.fromFirestore(doc);
                } catch (e) {
                  debugPrint('❌ Error parsing message ${doc.id}: $e');
                  return null;
                }
              })
              .whereType<LobbyMessage>()
              .toList();
        });
  }

  // Stream online users in lobby
  Stream<List<LobbyUser>> streamLobbyUsers(String lobbyId) {
    return _db
        .collection('lobbies')
        .doc(lobbyId)
        .collection('users')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                try {
                  return LobbyUser.fromMap(doc.data());
                } catch (e) {
                  debugPrint('❌ Error parsing lobby user ${doc.id}: $e');
                  return null;
                }
              })
              .whereType<LobbyUser>()
              .where((user) => user.isOnline)
              .toList();
        });
  }

  // Send message with rate limiting
  Future<LobbyMessage?> sendMessageToLobby({
    required String lobbyId,
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required String content,
    String? userRank,
    String messageType = 'text',
    String? mediaUrl,
    int? voiceDuration,
  }) async {
    // Check rate limit
    if (!canSendMessage) {
      errorMessage =
          'Please wait ${timeUntilNextMessage?.inSeconds}s before sending another message';
      notifyListeners();
      return null;
    }

    try {
      _lastMessageTime = DateTime.now();

      final mentions = LobbyMessage.extractMentions(content);

      final message = LobbyMessage(
        id: '',
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        content: content,
        mentions: mentions,
        createdAt: DateTime.now(),
        messageType: messageType,
        mediaUrl: mediaUrl,
        voiceDuration: voiceDuration,
        userRank: userRank,
      );

      final docRef = await _db
          .collection('lobbies')
          .doc(lobbyId)
          .collection('messages')
          .add(message.toMap(useServerTimestamp: false));

      return message.copyWith(id: docRef.id);
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Update user last seen
  Future<void> updateUserPresence({
    required String lobbyId,
    required String userId,
  }) async {
    try {
      await _db
          .collection('lobbies')
          .doc(lobbyId)
          .collection('users')
          .doc(userId)
          .update({'lastSeen': FieldValue.serverTimestamp()});
    } catch (e) {
      debugPrint('❌ Error updating presence: $e');
    }
  }
}

extension on LobbyMessage {
  LobbyMessage copyWith({String? id}) {
    return LobbyMessage(
      id: id ?? this.id,
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      content: content,
      mentions: mentions,
      missionId: missionId,
      missionTitle: missionTitle,
      createdAt: createdAt,
      messageType: messageType,
      mediaUrl: mediaUrl,
      voiceDuration: voiceDuration,
      reactions: reactions,
      replyToId: replyToId,
      replyToContent: replyToContent,
      replyToUserName: replyToUserName,
      systemType: systemType,
      systemData: systemData,
      userRank: userRank,
    );
  }
}
