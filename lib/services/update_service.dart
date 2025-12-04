import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'release_notes_service.dart';

class UpdateService {
  static const String _configCollection = 'app_config';
  static const String _versionDoc = 'version';

  /// Check if app update is available
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = int.parse(packageInfo.buildNumber);

      // Try GitHub Releases API first (more reliable)
      try {
        final response = await http.get(
          Uri.parse('https://api.github.com/repos/chromex21/mission-board/releases/latest'),
        );
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final remoteVersion = (data['tag_name'] as String).replaceAll('v', '');
          final releaseNotes = data['body'] as String? ?? 'Update available';
          final downloadUrl = data['assets']?.firstWhere(
            (asset) => asset['name'].toString().endsWith('.apk'),
            orElse: () => {'browser_download_url': ''},
          )['browser_download_url'] as String? ?? '';
          
          // Parse version to build number (1.3.1 = 131)
          final versionParts = remoteVersion.split('.');
          final remoteBuildNumber = int.tryParse(versionParts.join()) ?? 0;
          
          if (remoteBuildNumber > currentBuildNumber && downloadUrl.isNotEmpty) {
            return UpdateInfo(
              currentVersion: currentVersion,
              latestVersion: remoteVersion,
              downloadUrl: downloadUrl,
              releaseNotes: releaseNotes,
              forceUpdate: false,
            );
          }
        }
      } catch (e) {
        debugPrint('GitHub API failed, falling back to Firestore: $e');
      }

      // Fallback to Firestore
      final doc = await FirebaseFirestore.instance
          .collection(_configCollection)
          .doc(_versionDoc)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
      final remoteVersion = data['latestVersion'] as String;
      final remoteBuildNumber = data['buildNumber'] as int;
      final downloadUrl = data['downloadUrl'] as String;
      final releaseNotes = data['releaseNotes'] as String?;
      final forceUpdate = data['forceUpdate'] as bool? ?? false;

      // Compare versions
      if (remoteBuildNumber > currentBuildNumber) {
        return UpdateInfo(
          currentVersion: currentVersion,
          latestVersion: remoteVersion,
          downloadUrl: downloadUrl,
          releaseNotes: releaseNotes ?? 'Bug fixes and improvements',
          forceUpdate: forceUpdate,
        );
      }

      return null;
    } catch (e) {
      debugPrint('Error checking for update: $e');
      return null;
    }
  }

  /// Show update dialog to user
  static Future<void> showUpdateDialog(
    BuildContext context,
    UpdateInfo updateInfo,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: !updateInfo.forceUpdate,
      builder: (context) => AlertDialog(
        title: Text(
          updateInfo.forceUpdate ? '⚠️ Update Required' : '🎉 Update Available',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version ${updateInfo.latestVersion} is now available!',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Current version: ${updateInfo.currentVersion}'),
            const SizedBox(height: 16),
            Text(
              'What\'s new:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(updateInfo.releaseNotes),
          ],
        ),
        actions: [
          if (!updateInfo.forceUpdate)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Later'),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadAndInstall(updateInfo.downloadUrl);
            },
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  /// Download and install APK (Android only)
  static Future<void> _downloadAndInstall(String url) async {
    if (!Platform.isAndroid) {
      // For web/iOS, just open the URL
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    // On Android, use external browser to download APK
    // User will need to enable "Install from Unknown Sources"
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Check for updates on app start and create notification
  static Future<void> checkAndPromptUpdate(
    BuildContext context, {
    String? userId,
  }) async {
    final updateInfo = await checkForUpdate();
    if (updateInfo != null && context.mounted) {
      await showUpdateDialog(context, updateInfo);

      // Create in-app notification about update
      if (userId != null) {
        try {
          await FirebaseFirestore.instance.collection('notifications').add({
            'userId': userId,
            'type': 'update_available',
            'title': '🎉 Update Available',
            'body': 'Version ${updateInfo.latestVersion} is ready to download!',
            'data': {
              'version': updateInfo.latestVersion,
              'downloadUrl': updateInfo.downloadUrl,
            },
            'read': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          debugPrint('Error creating update notification: $e');
        }
      }
    }
  }

  /// Show release notes button in dialog
  static Future<void> showUpdateDialogWithReleaseNotes(
    BuildContext context,
    UpdateInfo updateInfo,
    int buildNumber,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: !updateInfo.forceUpdate,
      builder: (context) => AlertDialog(
        title: Text(
          updateInfo.forceUpdate ? '⚠️ Update Required' : '🎉 Update Available',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version ${updateInfo.latestVersion} is now available!',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Current version: ${updateInfo.currentVersion}'),
            const SizedBox(height: 16),
            Text(
              'What\'s new:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(updateInfo.releaseNotes),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () async {
                final releaseNote = await ReleaseNotesService.getReleaseNote(
                  buildNumber,
                );
                if (releaseNote != null && context.mounted) {
                  await ReleaseNotesService.showReleaseNotesDialog(
                    context,
                    releaseNote,
                  );
                }
              },
              icon: const Icon(Icons.article_outlined, size: 18),
              label: const Text('View Full Release Notes'),
            ),
          ],
        ),
        actions: [
          if (!updateInfo.forceUpdate)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Later'),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadAndInstall(updateInfo.downloadUrl);
            },
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }
}

class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;
  final bool forceUpdate;

  UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.forceUpdate,
  });
}
