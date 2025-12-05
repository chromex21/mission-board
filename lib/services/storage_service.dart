import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

/// Service for uploading files to Firebase Storage
/// Handles images, voice notes, documents, and other media
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload an image file
  /// Returns the download URL
  Future<String?> uploadImage({
    required String filePath,
    required String userId,
    String folder = 'messages',
  }) async {
    try {
      final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('$folder/$userId/$fileName');

      UploadTask uploadTask;
      if (kIsWeb) {
        // For web, handle differently
        final bytes = await File(filePath).readAsBytes();
        uploadTask = ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        // For mobile/desktop
        uploadTask = ref.putFile(File(filePath));
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  /// Upload a voice note
  /// Returns the download URL
  Future<String?> uploadVoiceNote({
    required String filePath,
    required String userId,
    required int duration,
  }) async {
    try {
      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final ref = _storage.ref().child('voice_notes/$userId/$fileName');

      UploadTask uploadTask;
      if (kIsWeb) {
        final bytes = await File(filePath).readAsBytes();
        uploadTask = ref.putData(
          bytes,
          SettableMetadata(
            contentType: 'audio/mp4',
            customMetadata: {'duration': duration.toString()},
          ),
        );
      } else {
        uploadTask = ref.putFile(
          File(filePath),
          SettableMetadata(
            customMetadata: {'duration': duration.toString()},
          ),
        );
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading voice note: $e');
      return null;
    }
  }

  /// Upload a document
  /// Returns the download URL
  Future<String?> uploadDocument({
    required String filePath,
    required String userId,
    required String fileName,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage.ref().child('documents/$userId/${timestamp}_$fileName');

      UploadTask uploadTask;
      if (kIsWeb) {
        final bytes = await File(filePath).readAsBytes();
        uploadTask = ref.putData(bytes);
      } else {
        uploadTask = ref.putFile(File(filePath));
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading document: $e');
      return null;
    }
  }

  /// Upload user profile picture
  /// Returns the download URL
  Future<String?> uploadProfilePicture({
    required String filePath,
    required String userId,
  }) async {
    try {
      final ref = _storage.ref().child('profile_pictures/$userId.jpg');

      UploadTask uploadTask;
      if (kIsWeb) {
        final bytes = await File(filePath).readAsBytes();
        uploadTask = ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        uploadTask = ref.putFile(File(filePath));
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
      return null;
    }
  }

  /// Delete a file from Firebase Storage
  Future<bool> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting file: $e');
      return false;
    }
  }

  /// Get upload progress stream
  Stream<double> getUploadProgress(UploadTask task) {
    return task.snapshotEvents.map((snapshot) {
      return snapshot.bytesTransferred / snapshot.totalBytes;
    });
  }
}
