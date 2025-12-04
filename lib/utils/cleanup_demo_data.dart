import 'package:flutter/foundation.dart' show debugPrint;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Script to clean up demo data from Firestore
/// Run this once to remove all test/demo activities from the mission feed
class DemoDataCleanup {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Demo user IDs that were used for testing
  static const demoUserIds = [
    'user1',
    'user2',
    'user3',
    'user4',
    'user5',
    'user6',
    'user7',
    'user8',
    'user9',
    'user10',
  ];

  /// Demo user names to identify demo data
  static const demoUserNames = [
    'Sarah Chen',
    'Marcus Johnson',
    'Elena Rodriguez',
    'David Kim',
    'Amara Williams',
    'Alex Turner',
    'Priya Patel',
    'James Brown',
    'Lily Zhang',
    'Omar Hassan',
  ];

  /// Delete all demo activities from Firestore
  static Future<int> cleanupDemoActivities() async {
    int deletedCount = 0;

    try {
      // Query all activities
      final snapshot = await _firestore.collection('mission_activities').get();

      if (snapshot.docs.isEmpty) {
        debugPrint('✅ No activities found - database is clean');
        return 0;
      }

      // Filter for demo activities
      final demoActivities = snapshot.docs.where((doc) {
        final data = doc.data();
        final userId = data['userId'] as String?;
        final userName = data['userName'] as String?;

        // Check if userId or userName matches demo data
        return (userId != null && demoUserIds.contains(userId)) ||
            (userName != null && demoUserNames.contains(userName));
      }).toList();

      if (demoActivities.isEmpty) {
        debugPrint('✅ No demo activities found - database is clean');
        return 0;
      }

      debugPrint(
        '🗑️ Found ${demoActivities.length} demo activities to delete',
      );

      // Delete in batches (Firestore limit is 500 operations per batch)
      const batchSize = 500;
      for (var i = 0; i < demoActivities.length; i += batchSize) {
        final batch = _firestore.batch();
        final end = (i + batchSize < demoActivities.length)
            ? i + batchSize
            : demoActivities.length;

        for (var j = i; j < end; j++) {
          batch.delete(demoActivities[j].reference);
        }

        await batch.commit();
        deletedCount += (end - i);
        debugPrint('🗑️ Deleted batch: $deletedCount/${demoActivities.length}');
      }

      debugPrint('✅ Successfully deleted $deletedCount demo activities');
      return deletedCount;
    } catch (e) {
      debugPrint('❌ Error cleaning up demo data: $e');
      rethrow;
    }
  }

  /// Delete ALL activities (use with caution!)
  static Future<int> deleteAllActivities() async {
    try {
      final snapshot = await _firestore.collection('mission_activities').get();

      if (snapshot.docs.isEmpty) {
        debugPrint('✅ No activities found');
        return 0;
      }

      debugPrint('⚠️ Deleting ALL ${snapshot.docs.length} activities...');

      const batchSize = 500;
      int deletedCount = 0;

      for (var i = 0; i < snapshot.docs.length; i += batchSize) {
        final batch = _firestore.batch();
        final end = (i + batchSize < snapshot.docs.length)
            ? i + batchSize
            : snapshot.docs.length;

        for (var j = i; j < end; j++) {
          batch.delete(snapshot.docs[j].reference);
        }

        await batch.commit();
        deletedCount += (end - i);
        debugPrint('🗑️ Deleted: $deletedCount/${snapshot.docs.length}');
      }

      debugPrint('✅ Deleted all $deletedCount activities');
      return deletedCount;
    } catch (e) {
      debugPrint('❌ Error deleting activities: $e');
      rethrow;
    }
  }
}
