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

      // Update conversation metadata
      final updateData = <String, dynamic>{
        'lastMessage': content,
        'lastMessageSenderId': senderId,
        'lastMessageTime': now,
        'unreadCount.$senderId': 0,
        'updatedAt': now,
      };

      // Increment unread count for other participants
      for (var participantId in participants) {
        if (participantId != senderId) {
          updateData['unreadCount.$participantId'] = FieldValue.increment(1);
        }
      }

      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .update(updateData);
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
      final unreadMessages = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .where('readBy', whereNotIn: [userId])
          .get();

      final batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([userId]),
        });
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
}
