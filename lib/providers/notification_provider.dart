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
}
