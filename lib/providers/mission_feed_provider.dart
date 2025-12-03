import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/mission_activity_model.dart';

class MissionFeedProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<MissionActivity> _activities = [];
  bool _isLoading = false;
  String? _error;

  List<MissionActivity> get activities => _activities;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Listen to activity feed in real-time
  void listenToActivities({int limit = 50}) {
    _isLoading = true;
    notifyListeners();

    _firestore
        .collection('mission_activities')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .listen(
          (snapshot) {
            _activities = snapshot.docs
                .map((doc) => MissionActivity.fromFirestore(doc))
                .toList();
            _isLoading = false;
            _error = null;
            notifyListeners();
          },
          onError: (error) {
            _error = error.toString();
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  // Post a new activity to the feed
  Future<void> postActivity(MissionActivity activity) async {
    try {
      await _firestore.collection('mission_activities').add(activity.toMap());
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Toggle like on an activity
  Future<void> toggleLike(String activityId, String userId) async {
    try {
      final activityRef = _firestore
          .collection('mission_activities')
          .doc(activityId);
      final doc = await activityRef.get();
      final likedBy = List<String>.from(doc.data()?['likedBy'] ?? []);

      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
      } else {
        likedBy.add(userId);
      }

      await activityRef.update({'likedBy': likedBy});
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Load more activities (pagination)
  Future<void> loadMoreActivities() async {
    if (_activities.isEmpty) return;

    try {
      final lastActivity = _activities.last;
      final snapshot = await _firestore
          .collection('mission_activities')
          .orderBy('timestamp', descending: true)
          .startAfter([Timestamp.fromDate(lastActivity.timestamp)])
          .limit(20)
          .get();

      final newActivities = snapshot.docs
          .map((doc) => MissionActivity.fromFirestore(doc))
          .toList();
      _activities.addAll(newActivities);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Populate dummy data for testing (TEMPORARY)
  Future<void> populateDummyData() async {
    final dummyUsers = [
      {
        'id': 'user1',
        'name': 'Sarah Chen',
        'photo': 'https://i.pravatar.cc/150?img=1',
      },
      {
        'id': 'user2',
        'name': 'Marcus Johnson',
        'photo': 'https://i.pravatar.cc/150?img=13',
      },
      {
        'id': 'user3',
        'name': 'Elena Rodriguez',
        'photo': 'https://i.pravatar.cc/150?img=5',
      },
      {
        'id': 'user4',
        'name': 'David Kim',
        'photo': 'https://i.pravatar.cc/150?img=14',
      },
      {
        'id': 'user5',
        'name': 'Amara Williams',
        'photo': 'https://i.pravatar.cc/150?img=9',
      },
      {
        'id': 'user6',
        'name': 'Alex Turner',
        'photo': 'https://i.pravatar.cc/150?img=12',
      },
      {
        'id': 'user7',
        'name': 'Priya Patel',
        'photo': 'https://i.pravatar.cc/150?img=10',
      },
      {
        'id': 'user8',
        'name': 'James Brown',
        'photo': 'https://i.pravatar.cc/150?img=15',
      },
      {
        'id': 'user9',
        'name': 'Lily Zhang',
        'photo': 'https://i.pravatar.cc/150?img=20',
      },
      {
        'id': 'user10',
        'name': 'Omar Hassan',
        'photo': 'https://i.pravatar.cc/150?img=33',
      },
    ];

    final missionTitles = [
      'Complete Product Survey',
      'Review Beta Features',
      'Customer Feedback Call',
      'Code Review Task',
      'Design Mockup Review',
      'Write Blog Post',
      'Social Media Campaign',
      'Market Research',
      'Team Collaboration',
      'Quality Assurance Testing',
    ];

    try {
      final now = DateTime.now();
      final batch = _firestore.batch();

      for (int i = 0; i < 15; i++) {
        final user = dummyUsers[i % 10];
        final timestamp = now.subtract(Duration(hours: i * 2, minutes: i * 15));

        // Mix different activity types
        MissionActivity activity;
        switch (i % 4) {
          case 0:
            activity = MissionActivity.missionCompleted(
              userId: user['id']!,
              userName: user['name']!,
              userAvatar: user['photo']!,
              missionTitle: missionTitles[i % 10],
              reward: (50 + (i * 25)) % 500 + 50,
              difficulty: (i % 5) + 1,
            );
            break;
          case 1:
            activity = MissionActivity.paymentReceived(
              userId: user['id']!,
              userName: user['name']!,
              userAvatar: user['photo']!,
              amount: (100 + (i * 50)) % 1000 + 100,
              missionTitle: missionTitles[i % 10],
            );
            break;
          case 2:
            activity = MissionActivity.levelUp(
              userId: user['id']!,
              userName: user['name']!,
              userAvatar: user['photo']!,
              newLevel: (i % 10) + 1,
              totalXP: (i + 1) * 500,
            );
            break;
          default:
            activity = MissionActivity.milestoneReached(
              userId: user['id']!,
              userName: user['name']!,
              userAvatar: user['photo']!,
              milestone: '${(i + 1) * 10} Missions',
              count: (i + 1) * 10,
            );
        }

        // Override timestamp
        activity = MissionActivity(
          id: '',
          userId: activity.userId,
          userName: activity.userName,
          userAvatar: activity.userAvatar,
          type: activity.type,
          timestamp: timestamp,
          data: activity.data,
          likedBy: [],
          commentCount: 0,
        );

        final docRef = _firestore.collection('mission_activities').doc();
        batch.set(docRef, activity.toMap());
      }

      await batch.commit();
      debugPrint('✅ Dummy data populated successfully!');
    } catch (e) {
      debugPrint('❌ Error populating dummy data: $e');
      _error = e.toString();
      notifyListeners();
    }
  }
}
