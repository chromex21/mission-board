import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReleaseNotesService {
  static const String _releasesCollection = 'release_notes';

  /// Get all release notes ordered by date
  static Stream<List<ReleaseNote>> getReleaseNotes() {
    return FirebaseFirestore.instance
        .collection(_releasesCollection)
        .orderBy('buildNumber', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ReleaseNote.fromFirestore(doc))
              .toList();
        });
  }

  /// Get release notes for specific version
  static Future<ReleaseNote?> getReleaseNote(int buildNumber) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(_releasesCollection)
          .doc(buildNumber.toString())
          .get();

      if (doc.exists) {
        return ReleaseNote.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting release note: $e');
      return null;
    }
  }

  /// Show release notes dialog
  static Future<void> showReleaseNotesDialog(
    BuildContext context,
    ReleaseNote releaseNote,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Text('📝 Release Notes'),
            const Spacer(),
            Text(
              'v${releaseNote.version}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                releaseNote.releaseDate,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              if (releaseNote.features.isNotEmpty) ...[
                const Text(
                  '✨ New Features:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...releaseNote.features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• '),
                        Expanded(child: Text(feature)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (releaseNote.improvements.isNotEmpty) ...[
                const Text(
                  '🔧 Improvements:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...releaseNote.improvements.map(
                  (improvement) => Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• '),
                        Expanded(child: Text(improvement)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (releaseNote.bugFixes.isNotEmpty) ...[
                const Text(
                  '🐛 Bug Fixes:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...releaseNote.bugFixes.map(
                  (fix) => Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• '),
                        Expanded(child: Text(fix)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Create system notification for new release
  static Future<void> notifyNewRelease(
    String userId,
    ReleaseNote releaseNote,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'type': 'release',
        'title': '🎉 New Version Available!',
        'body':
            'Version ${releaseNote.version} is now available with new features and improvements.',
        'data': {
          'version': releaseNote.version,
          'buildNumber': releaseNote.buildNumber,
        },
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error creating release notification: $e');
    }
  }

  /// Notify all users about new release
  static Future<void> notifyAllUsers(ReleaseNote releaseNote) async {
    try {
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      final batch = FirebaseFirestore.instance.batch();

      for (var userDoc in usersSnapshot.docs) {
        final notificationRef = FirebaseFirestore.instance
            .collection('notifications')
            .doc();

        batch.set(notificationRef, {
          'userId': userDoc.id,
          'type': 'release',
          'title': '🎉 New Version Available!',
          'body':
              'Version ${releaseNote.version} is now available with new features and improvements.',
          'data': {
            'version': releaseNote.version,
            'buildNumber': releaseNote.buildNumber,
          },
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugPrint('Notified ${usersSnapshot.docs.length} users about release');
    } catch (e) {
      debugPrint('Error notifying users: $e');
    }
  }
}

class ReleaseNote {
  final String version;
  final int buildNumber;
  final String releaseDate;
  final List<String> features;
  final List<String> improvements;
  final List<String> bugFixes;
  final bool critical;

  ReleaseNote({
    required this.version,
    required this.buildNumber,
    required this.releaseDate,
    this.features = const [],
    this.improvements = const [],
    this.bugFixes = const [],
    this.critical = false,
  });

  factory ReleaseNote.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReleaseNote(
      version: data['version'] as String,
      buildNumber: data['buildNumber'] as int,
      releaseDate: data['releaseDate'] as String,
      features: List<String>.from(data['features'] ?? []),
      improvements: List<String>.from(data['improvements'] ?? []),
      bugFixes: List<String>.from(data['bugFixes'] ?? []),
      critical: data['critical'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'version': version,
      'buildNumber': buildNumber,
      'releaseDate': releaseDate,
      'features': features,
      'improvements': improvements,
      'bugFixes': bugFixes,
      'critical': critical,
    };
  }
}
