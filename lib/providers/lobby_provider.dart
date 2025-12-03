import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lobby_message_model.dart';

class LobbyProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<LobbyMessage> _messages = [];
  bool isLoading = false;
  String? errorMessage;

  List<LobbyMessage> get messages => _messages;

  // Stream lobby messages
  Stream<List<LobbyMessage>> streamLobbyMessages() {
    return _db
        .collection('lobby')
        .orderBy('createdAt', descending: false)
        .limit(100)
        .snapshots()
        .handleError((error) {
          print('❌ Lobby stream error: $error');
          errorMessage = error.toString();
          notifyListeners();
        })
        .map((snapshot) {
          try {
            print('📨 Processing ${snapshot.docs.length} lobby messages');
            _messages = snapshot.docs
                .map((doc) {
                  try {
                    final msg = LobbyMessage.fromFirestore(doc);
                    print(
                      '✅ Parsed message ${doc.id}: ${msg.content.substring(0, msg.content.length > 20 ? 20 : msg.content.length)}...',
                    );
                    return msg;
                  } catch (e) {
                    print('❌ Error parsing message ${doc.id}: $e');
                    print('   Data: ${doc.data()}');
                    return null;
                  }
                })
                .whereType<LobbyMessage>()
                .toList();
            print('✅ Returned ${_messages.length} valid messages');
            return _messages;
          } catch (e) {
            print('❌ Error mapping snapshot: $e');
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
      print('❌ Error toggling reaction: $e');
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
        print('🗑️ Cleaned up ${oldMessages.docs.length} old lobby messages');
      }
    } catch (e) {
      print('❌ Error cleaning up old messages: $e');
    }
  }
}
