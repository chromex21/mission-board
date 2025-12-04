import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:mission_board/models/conversation_model.dart';

class MessagingProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Conversation> _conversations = [];
  final Map<String, int> _totalUnreadCount = <String, int>{};

  List<Conversation> get conversations => _conversations;
  int getTotalUnreadCount(String userId) => _totalUnreadCount[userId] ?? 0;

  /// Get or create a conversation between two users
  Future<String> getOrCreateConversation({
    required String currentUserId,
    required String otherUserId,
    required String currentUserName,
    required String otherUserName,
  }) async {
    try {
      // Check if conversation exists
      final existingQuery = await _firestore
          .collection('conversations')
          .where('participants', arrayContains: currentUserId)
          .get();

      for (var doc in existingQuery.docs) {
        final participants = List<String>.from(doc.data()['participants']);
        if (participants.contains(otherUserId)) {
          return doc.id;
        }
      }

      // Create new conversation
      final now = Timestamp.fromDate(DateTime.now());
      final newConv = await _firestore.collection('conversations').add({
        'participants': [currentUserId, otherUserId],
        'participantDetails': {
          currentUserId: {'name': currentUserName},
          otherUserId: {'name': otherUserName},
        },
        'lastMessage': null,
        'lastMessageSenderId': null,
        'lastMessageTime': null,
        'unreadCount': {currentUserId: 0, otherUserId: 0},
        'createdAt': now,
        'updatedAt': now,
      });

      return newConv.id;
    } catch (e) {
      throw Exception('Failed to create conversation: $e');
    }
  }

  /// Send a message
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String content,
    required List<String> participants,
    MessageType type = MessageType.text,
  }) async {
    try {
      // Add message to subcollection
      final now = Timestamp.fromDate(DateTime.now());
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .add({
            'conversationId': conversationId,
            'senderId': senderId,
            'senderName': senderName,
            'content': content,
            'type': type.name,
            'timestamp': now,
            'isRead': false,
            'readBy': [senderId], // Sender has "read" their own message
          });

      // Get current conversation to access unread counts
      final conversationDoc = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .get();

      if (!conversationDoc.exists) {
        throw Exception('Conversation not found');
      }

      final conversationData = conversationDoc.data()!;
      final currentUnreadCount = Map<String, dynamic>.from(
        conversationData['unreadCount'] ?? {},
      );

      // Update unread counts
      currentUnreadCount[senderId] = 0;
      for (var participantId in participants) {
        if (participantId != senderId) {
          currentUnreadCount[participantId] =
              (currentUnreadCount[participantId] ?? 0) + 1;
        }
      }

      // Update conversation with all changes at once
      await _firestore.collection('conversations').doc(conversationId).update({
        'lastMessage': content,
        'lastMessageSenderId': senderId,
        'lastMessageTime': now,
        'unreadCount': currentUnreadCount,
        'updatedAt': now,
      });

      // Create notifications for recipients
      for (var participantId in participants) {
        if (participantId != senderId) {
          await _firestore.collection('notifications').add({
            'userId': participantId,
            'type': 'newMessage',
            'title': 'New Message',
            'message':
                '$senderName: ${type == MessageType.text ? content : type.name}',
            'actorName': senderName,
            'actorId': senderId,
            'actionId': conversationId,
            'isRead': false,
            'createdAt': now,
          });
        }
      }
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead({
    required String conversationId,
    required String userId,
  }) async {
    try {
      // Update conversation unread count
      await _firestore.collection('conversations').doc(conversationId).update({
        'unreadCount.$userId': 0,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Update messages in batch
      // Note: Cannot combine isNotEqualTo with whereNotIn, so we filter in memory
      final allMessages = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .get();

      final batch = _firestore.batch();
      for (var doc in allMessages.docs) {
        final data = doc.data();
        final senderId = data['senderId'] as String?;
        final readBy = (data['readBy'] as List<dynamic>?) ?? [];

        // Only mark as read if: sent by someone else AND not already read by user
        if (senderId != userId && !readBy.contains(userId)) {
          batch.update(doc.reference, {
            'readBy': FieldValue.arrayUnion([userId]),
          });
        }
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  /// Stream conversations for a user
  Stream<List<Conversation>> streamConversations(String userId) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          _conversations = snapshot.docs
              .map((doc) {
                try {
                  return Conversation.fromMap(doc.data(), doc.id);
                } catch (e) {
                  return null;
                }
              })
              .whereType<Conversation>()
              .toList();

          // Sort manually by last message time
          _conversations.sort((a, b) {
            final aTime = a.lastMessageTime ?? DateTime(2000);
            final bTime = b.lastMessageTime ?? DateTime(2000);
            return bTime.compareTo(aTime);
          });

          // Calculate total unread
          int totalUnread = 0;
          for (var conv in _conversations) {
            totalUnread += conv.unreadCount[userId] ?? 0;
          }
          _totalUnreadCount[userId] = totalUnread;

          notifyListeners();
          return _conversations;
        });
  }

  /// Stream messages for a conversation
  Stream<List<Message>> streamMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Message.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  /// Delete a single message
  Future<void> deleteMessage(String conversationId, String messageId) async {
    try {
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  /// Delete conversation
  Future<void> deleteConversation(String conversationId) async {
    try {
      // Delete all messages
      final messages = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .get();

      final batch = _firestore.batch();
      for (var doc in messages.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Delete conversation
      await _firestore.collection('conversations').doc(conversationId).delete();
    } catch (e) {
      throw Exception('Failed to delete conversation: $e');
    }
  }

  // Production: remove demo message population

  /// Add reaction to message
  Future<void> addReaction({
    required String conversationId,
    required String messageId,
    required String emoji,
    required String userId,
  }) async {
    try {
      final now = Timestamp.fromDate(DateTime.now());

      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .update({
            'reactions': FieldValue.arrayUnion([
              {'emoji': emoji, 'userId': userId, 'timestamp': now},
            ]),
          });
    } catch (e) {
      throw Exception('Failed to add reaction: $e');
    }
  }

  /// Remove reaction from message
  Future<void> removeReaction({
    required String conversationId,
    required String messageId,
    required String emoji,
    required String userId,
  }) async {
    try {
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .update({
            'reactions': FieldValue.arrayRemove([
              {'emoji': emoji, 'userId': userId},
            ]),
          });
    } catch (e) {
      throw Exception('Failed to remove reaction: $e');
    }
  }

  // Production: remove local (offline) demo support
}
