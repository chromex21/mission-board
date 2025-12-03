import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DemoDataHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Populate 5 demo users for leaderboard
  static Future<void> populateDemoLeaderboard() async {
    final demoUsers = [
      {
        'uid': 'demo_user_1',
        'displayName': 'Sarah Chen',
        'email': 'sarah.chen@demo.com',
        'totalPoints': 4850,
        'level': 12,
        'completedMissions': 48,
        'achievements': ['first_mission', 'speed_demon', 'team_player', 'top_performer'],
        'role': 'worker',
        'createdAt': DateTime.now().subtract(Duration(days: 90)),
      },
      {
        'uid': 'demo_user_2',
        'displayName': 'Marcus Johnson',
        'email': 'marcus.j@demo.com',
        'totalPoints': 4320,
        'level': 11,
        'completedMissions': 42,
        'achievements': ['first_mission', 'consistent', 'team_player'],
        'role': 'worker',
        'createdAt': DateTime.now().subtract(Duration(days: 75)),
      },
      {
        'uid': 'demo_user_3',
        'displayName': 'Elena Rodriguez',
        'email': 'elena.r@demo.com',
        'totalPoints': 3890,
        'level': 10,
        'completedMissions': 38,
        'achievements': ['first_mission', 'quality_master', 'fast_learner'],
        'role': 'worker',
        'createdAt': DateTime.now().subtract(Duration(days: 60)),
      },
      {
        'uid': 'demo_user_4',
        'displayName': 'David Kim',
        'email': 'david.kim@demo.com',
        'totalPoints': 3560,
        'level': 9,
        'completedMissions': 35,
        'achievements': ['first_mission', 'team_player'],
        'role': 'worker',
        'createdAt': DateTime.now().subtract(Duration(days: 50)),
      },
      {
        'uid': 'demo_user_5',
        'displayName': 'Amara Williams',
        'email': 'amara.w@demo.com',
        'totalPoints': 3210,
        'level': 9,
        'completedMissions': 32,
        'achievements': ['first_mission', 'dedicated', 'rising_star'],
        'role': 'worker',
        'createdAt': DateTime.now().subtract(Duration(days: 45)),
      },
    ];

    try {
      final batch = _firestore.batch();

      for (var userData in demoUsers) {
        final userRef = _firestore.collection('users').doc(userData['uid'] as String);
        
        batch.set(userRef, {
          'displayName': userData['displayName'],
          'email': userData['email'],
          'totalPoints': userData['totalPoints'],
          'level': userData['level'],
          'completedMissions': userData['completedMissions'],
          'achievements': userData['achievements'],
          'role': userData['role'],
          'photoURL': null,
          'bio': 'Demo user for testing',
          'createdAt': Timestamp.fromDate(userData['createdAt'] as DateTime),
          'updatedAt': Timestamp.now(),
        });
      }

      await batch.commit();
      if (kDebugMode) print('✅ Demo leaderboard users populated!');
    } catch (e) {
      if (kDebugMode) print('❌ Error populating leaderboard: $e');
      rethrow;
    }
  }
}
