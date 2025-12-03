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
}
