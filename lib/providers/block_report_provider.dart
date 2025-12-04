import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum ReportReason { spam, harassment, inappropriate, impersonation, other }

class BlockReportProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================================
  // BLOCK USER
  // ============================================================================

  /// Block a user
  Future<void> blockUser(String blockerId, String blockedId) async {
    try {
      // Add to blocked users collection
      await _firestore.collection('blockedUsers').add({
        'blockerId': blockerId,
        'blockedId': blockedId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Remove friend relationship if exists
      final friendships = await _firestore
          .collection('friends')
          .where('userId', isEqualTo: blockerId)
          .where('friendId', isEqualTo: blockedId)
          .get();

      for (var doc in friendships.docs) {
        await doc.reference.delete();
      }

      // Remove reverse friendship
      final reverseFriendships = await _firestore
          .collection('friends')
          .where('userId', isEqualTo: blockedId)
          .where('friendId', isEqualTo: blockerId)
          .get();

      for (var doc in reverseFriendships.docs) {
        await doc.reference.delete();
      }

      // Cancel pending friend requests
      final outgoingRequests = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: blockerId)
          .where('receiverId', isEqualTo: blockedId)
          .where('status', isEqualTo: 'pending')
          .get();

      for (var doc in outgoingRequests.docs) {
        await doc.reference.delete();
      }

      final incomingRequests = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: blockedId)
          .where('receiverId', isEqualTo: blockerId)
          .where('status', isEqualTo: 'pending')
          .get();

      for (var doc in incomingRequests.docs) {
        await doc.reference.delete();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error blocking user: $e');
      throw Exception('Failed to block user');
    }
  }

  /// Unblock a user
  Future<void> unblockUser(String blockerId, String blockedId) async {
    try {
      final blocks = await _firestore
          .collection('blockedUsers')
          .where('blockerId', isEqualTo: blockerId)
          .where('blockedId', isEqualTo: blockedId)
          .get();

      for (var doc in blocks.docs) {
        await doc.reference.delete();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error unblocking user: $e');
      throw Exception('Failed to unblock user');
    }
  }

  /// Check if a user is blocked
  Future<bool> isUserBlocked(String blockerId, String blockedId) async {
    try {
      final result = await _firestore
          .collection('blockedUsers')
          .where('blockerId', isEqualTo: blockerId)
          .where('blockedId', isEqualTo: blockedId)
          .limit(1)
          .get();

      return result.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking block status: $e');
      return false;
    }
  }

  /// Check if current user is blocked by another user
  Future<bool> isBlockedBy(String userId, String otherUserId) async {
    try {
      final result = await _firestore
          .collection('blockedUsers')
          .where('blockerId', isEqualTo: otherUserId)
          .where('blockedId', isEqualTo: userId)
          .limit(1)
          .get();

      return result.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking if blocked by user: $e');
      return false;
    }
  }

  /// Get list of blocked users
  Stream<List<Map<String, dynamic>>> streamBlockedUsers(String userId) {
    return _firestore
        .collection('blockedUsers')
        .where('blockerId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
          final blockedUsers = <Map<String, dynamic>>[];

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final blockedId = data['blockedId'] as String;

            // Get blocked user details
            final userDoc = await _firestore
                .collection('users')
                .doc(blockedId)
                .get();

            if (userDoc.exists) {
              blockedUsers.add({
                'blockId': doc.id,
                'userId': blockedId,
                'name':
                    userDoc.data()?['displayName'] ??
                    userDoc.data()?['username'] ??
                    'Unknown',
                'createdAt': data['createdAt'],
              });
            }
          }

          return blockedUsers;
        });
  }

  // ============================================================================
  // REPORT USER
  // ============================================================================

  /// Report a user
  Future<void> reportUser({
    required String reporterId,
    required String reportedId,
    required ReportReason reason,
    String? description,
    String? evidenceUrl,
  }) async {
    try {
      await _firestore.collection('reports').add({
        'reporterId': reporterId,
        'reportedId': reportedId,
        'reason': reason.toString().split('.').last,
        'description': description ?? '',
        'evidenceUrl': evidenceUrl,
        'status': 'pending', // pending, reviewed, resolved, dismissed
        'createdAt': FieldValue.serverTimestamp(),
        'reviewedAt': null,
        'reviewedBy': null,
        'resolutionNotes': null,
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error reporting user: $e');
      throw Exception('Failed to submit report');
    }
  }

  /// Get reports made by a user
  Stream<List<Map<String, dynamic>>> streamMyReports(String userId) {
    return _firestore
        .collection('reports')
        .where('reporterId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final reports = <Map<String, dynamic>>[];

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final reportedId = data['reportedId'] as String;

            // Get reported user details
            final userDoc = await _firestore
                .collection('users')
                .doc(reportedId)
                .get();

            reports.add({
              'reportId': doc.id,
              'reportedUserId': reportedId,
              'reportedUserName':
                  userDoc.data()?['displayName'] ??
                  userDoc.data()?['username'] ??
                  'Unknown',
              'reason': data['reason'],
              'description': data['description'],
              'status': data['status'],
              'createdAt': data['createdAt'],
            });
          }

          return reports;
        });
  }

  /// Get all reports (admin only)
  Stream<List<Map<String, dynamic>>> streamAllReports() {
    return _firestore
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final reports = <Map<String, dynamic>>[];

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final reporterId = data['reporterId'] as String;
            final reportedId = data['reportedId'] as String;

            // Get both user details
            final reporterDoc = await _firestore
                .collection('users')
                .doc(reporterId)
                .get();
            final reportedDoc = await _firestore
                .collection('users')
                .doc(reportedId)
                .get();

            reports.add({
              'reportId': doc.id,
              'reporterId': reporterId,
              'reporterName':
                  reporterDoc.data()?['displayName'] ??
                  reporterDoc.data()?['username'] ??
                  'Unknown',
              'reportedUserId': reportedId,
              'reportedUserName':
                  reportedDoc.data()?['displayName'] ??
                  reportedDoc.data()?['username'] ??
                  'Unknown',
              'reason': data['reason'],
              'description': data['description'],
              'status': data['status'],
              'createdAt': data['createdAt'],
              'reviewedAt': data['reviewedAt'],
              'resolutionNotes': data['resolutionNotes'],
            });
          }

          return reports;
        });
  }

  /// Update report status (admin only)
  Future<void> updateReportStatus({
    required String reportId,
    required String status,
    required String reviewerId,
    String? resolutionNotes,
  }) async {
    try {
      await _firestore.collection('reports').doc(reportId).update({
        'status': status,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': reviewerId,
        'resolutionNotes': resolutionNotes,
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating report status: $e');
      throw Exception('Failed to update report status');
    }
  }
}
