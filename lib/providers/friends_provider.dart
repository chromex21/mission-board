import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/friend_request_model.dart';

class FriendsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<FriendRequest> _pendingRequests = [];
  List<String> _friends = []; // List of friend UIDs
  Map<String, bool> _onlineStatus = {}; // {uid: isOnline}

  List<FriendRequest> get pendingRequests => _pendingRequests;
  List<String> get friends => _friends;
  Map<String, bool> get onlineStatus => _onlineStatus;

  int getPendingRequestCount() => _pendingRequests.length;
  bool isFriend(String userId) => _friends.contains(userId);
  bool isOnline(String userId) => _onlineStatus[userId] ?? false;

  /// Send friend request
  Future<void> sendFriendRequest({
    required String senderId,
    required String senderName,
    required String receiverId,
  }) async {
    try {
      // Check if they're already friends first
      final user = await _firestore.collection('users').doc(senderId).get();
      final friends = List<String>.from(user.data()?['friends'] ?? []);
      if (friends.contains(receiverId)) {
        throw Exception('You are already friends with this user');
      }

      // Check if request already exists (sent by you)
      final existing = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: senderId)
          .where('receiverId', isEqualTo: receiverId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception(
          'Friend request already sent. Check your pending requests.',
        );
      }

      // Check if they sent you a request (reverse) - if so, AUTO-ACCEPT IT
      final reverse = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: receiverId)
          .where('receiverId', isEqualTo: senderId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (reverse.docs.isNotEmpty) {
        // They already sent you a request - accept it instead of creating new one
        debugPrint(
          '🤝 Found existing request from other user - auto-accepting',
        );
        final requestId = reverse.docs.first.id;
        await acceptFriendRequest(requestId, senderId);
        return; // Don't create a new request
      }

      // Create friend request
      final requestDoc = await _firestore.collection('friendRequests').add({
        'senderId': senderId,
        'senderName': senderName,
        'receiverId': receiverId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'respondedAt': null,
      });
      debugPrint('✅ Created friend request: ${requestDoc.id}');

      // Create notification for receiver
      final notifDoc = await _firestore.collection('notifications').add({
        'userId': receiverId,
        'type': 'friendRequest',
        'title': 'New Friend Request',
        'message': '$senderName sent you a friend request',
        'actorId': senderId,
        'actorName': senderName,
        'actionId': requestDoc.id,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint(
        '✅ Created notification: ${notifDoc.id} for user: $receiverId',
      );
      debugPrint('   Message: $senderName sent you a friend request');
    } catch (e) {
      throw Exception('Failed to send friend request: $e');
    }
  }

  /// Accept friend request
  Future<void> acceptFriendRequest(
    String requestId,
    String currentUserId,
  ) async {
    try {
      final requestDoc = await _firestore
          .collection('friendRequests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) throw Exception('Request not found');

      final request = FriendRequest.fromMap(requestDoc.data()!, requestId);

      // Update request status
      await _firestore.collection('friendRequests').doc(requestId).update({
        'status': 'accepted',
        'respondedAt': FieldValue.serverTimestamp(),
      });

      // Add to both users' friends lists
      await _firestore.collection('users').doc(request.senderId).update({
        'friends': FieldValue.arrayUnion([request.receiverId]),
      });

      await _firestore.collection('users').doc(request.receiverId).update({
        'friends': FieldValue.arrayUnion([request.senderId]),
      });

      // Create notification for sender
      await _firestore.collection('notifications').add({
        'userId': request.senderId,
        'type': 'friendRequestAccepted',
        'title': 'Friend Request Accepted',
        'message': '${request.senderName} accepted your friend request',
        'actorId': request.receiverId,
        'actorName': null,
        'actionId': null,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to accept friend request: $e');
    }
  }

  /// Reject friend request
  Future<void> rejectFriendRequest(String requestId) async {
    try {
      await _firestore.collection('friendRequests').doc(requestId).update({
        'status': 'rejected',
        'respondedAt': FieldValue.serverTimestamp(),
      });

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to reject friend request: $e');
    }
  }

  /// Remove friend
  Future<void> removeFriend(String currentUserId, String friendId) async {
    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'friends': FieldValue.arrayRemove([friendId]),
      });

      await _firestore.collection('users').doc(friendId).update({
        'friends': FieldValue.arrayRemove([currentUserId]),
      });

      _friends.remove(friendId);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to remove friend: $e');
    }
  }

  /// Stream friend requests for current user
  Stream<List<FriendRequest>> streamFriendRequests(String userId) {
    return _firestore
        .collection('friendRequests')
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          _pendingRequests = snapshot.docs
              .map((doc) => FriendRequest.fromMap(doc.data(), doc.id))
              .toList();
          notifyListeners();
          return _pendingRequests;
        });
  }

  /// Stream friends list
  Stream<List<String>> streamFriends(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((
      snapshot,
    ) {
      final data = snapshot.data();
      _friends = List<String>.from(data?['friends'] ?? []);
      notifyListeners();
      return _friends;
    });
  }

  /// Check if there's ANY pending request between two users (either direction)
  Future<String?> getPendingRequestBetween(
    String userId,
    String otherUserId,
  ) async {
    try {
      // Check if userId sent to otherUserId
      final sent = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: userId)
          .where('receiverId', isEqualTo: otherUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (sent.docs.isNotEmpty) {
        return 'sent'; // You sent request
      }

      // Check if otherUserId sent to userId
      final received = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: otherUserId)
          .where('receiverId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (received.docs.isNotEmpty) {
        return 'received'; // You received request
      }

      return null; // No pending requests
    } catch (e) {
      debugPrint('Error checking pending requests: $e');
      return null;
    }
  }

  /// Update online status
  Future<void> setOnlineStatus(String userId, bool isOnline) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) print('Failed to update online status: $e');
    }
  }

  /// Stream online status for multiple users
  Stream<Map<String, bool>> streamOnlineStatus(List<String> userIds) {
    if (userIds.isEmpty) {
      return Stream.value({});
    }

    return _firestore
        .collection('users')
        .where(FieldPath.documentId, whereIn: userIds)
        .snapshots()
        .map((snapshot) {
          final status = <String, bool>{};
          for (var doc in snapshot.docs) {
            status[doc.id] = doc.data()['isOnline'] ?? false;
          }
          _onlineStatus = status;
          notifyListeners();
          return status;
        });
  }
}
