import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/friend_request_model.dart';

class NotificationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<AppNotification> _notifications = [];
  int _unreadCount = 0;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  /// Stream notifications for user
  Stream<List<AppNotification>> streamNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          _notifications = snapshot.docs
              .map((doc) => AppNotification.fromMap(doc.data(), doc.id))
              .toList();

          _unreadCount = _notifications.where((n) => !n.isRead).length;
          notifyListeners();
          return _notifications;
        });
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      if (kDebugMode) print('Failed to mark notification as read: $e');
    }
  }

  /// Mark all as read
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final unreadDocs = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in unreadDocs.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      if (kDebugMode) print('Failed to mark all as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      if (kDebugMode) print('Failed to delete notification: $e');
    }
  }

  /// Clear all notifications
  Future<void> clearAll(String userId) async {
    try {
      final batch = _firestore.batch();
      final allDocs = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in allDocs.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      if (kDebugMode) print('Failed to clear notifications: $e');
    }
  }

  /// Populate dummy notifications (TEMPORARY)
  Future<void> populateDummyNotifications(String userId) async {
    final demoNotifications = [
      {
        'type': NotificationType.friendRequest,
        'title': 'New Friend Request',
        'message': 'Sarah Chen sent you a friend request',
        'actorName': 'Sarah Chen',
        'actorId': 'user1',
      },
      {
        'type': NotificationType.missionCompleted,
        'title': 'Mission Completed! 🎉',
        'message': 'You earned \$250 for completing "Customer Feedback Survey"',
        'actorName': null,
        'actorId': null,
      },
      {
        'type': NotificationType.newMessage,
        'title': 'New Message',
        'message': 'Marcus Johnson: "Hey! Are you available for that mission?"',
        'actorName': 'Marcus Johnson',
        'actorId': 'user2',
      },
      {
        'type': NotificationType.levelUp,
        'title': 'Level Up! ⭐',
        'message': 'Congratulations! You reached Level 5',
        'actorName': null,
        'actorId': null,
      },
    ];

    try {
      final now = DateTime.now();
      final batch = _firestore.batch();

      for (int i = 0; i < demoNotifications.length; i++) {
        final notif = demoNotifications[i];
        final docRef = _firestore.collection('notifications').doc();

        batch.set(docRef, {
          'userId': userId,
          'type': (notif['type'] as NotificationType).name,
          'title': notif['title'],
          'message': notif['message'],
          'actorName': notif['actorName'],
          'actorId': notif['actorId'],
          'actionId': null,
          'isRead': i >= 2, // First 2 are unread
          'createdAt': Timestamp.fromDate(now.subtract(Duration(hours: i * 4))),
        });
      }

      await batch.commit();
      if (kDebugMode) print('✅ Dummy notifications populated!');
    } catch (e) {
      if (kDebugMode) print('❌ Error populating notifications: $e');
    }
  }
}
