import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  User? user;
  AppUser? appUser;
  bool isLoading = false;
  String? errorMessage;
  String? successMessage;

  AuthProvider() {
    _auth.authStateChanges().listen((u) async {
      user = u;
      if (u != null) {
        try {
          final doc = await _db.collection('users').doc(u.uid).get();
          if (doc.exists) {
            appUser = AppUser.fromMap(doc.data()!, u.uid);
          } else {
            // Create user document if it doesn't exist (for sign-in race condition)
            final newUser = AppUser(
              uid: u.uid,
              email: u.email ?? '',
              role: UserRole.worker,
            );
            await _db.collection('users').doc(u.uid).set(newUser.toMap());
            appUser = newUser;
          }
        } catch (e) {
          // Create a default appUser to allow app to continue
          appUser = AppUser(
            uid: u.uid,
            email: u.email ?? '',
            role: UserRole.worker,
          );
        }
      } else {
        appUser = null;
      }
      notifyListeners();
    });
  }

  Future<void> signIn(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      errorMessage = _getErrorMessage(e.code);
      isLoading = false;
      notifyListeners();
      throw Exception(errorMessage);
    } catch (e) {
      errorMessage = 'An error occurred. Please try again.';
      isLoading = false;
      notifyListeners();
      throw Exception(errorMessage);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp(
    String email,
    String password, {
    UserRole role = UserRole.worker,
    String? displayName,
    String? username,
    String? country,
    String? countryCode,
    String? phoneNumber,
    String? bio,
  }) async {
    isLoading = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final newUser = AppUser(
        uid: credential.user!.uid,
        email: email,
        role: role,
        displayName: displayName,
        username: username,
        country: country,
        countryCode: countryCode,
        phoneNumber: phoneNumber,
        bio: bio,
        createdAt: DateTime.now(),
      );
      await _db
          .collection('users')
          .doc(credential.user!.uid)
          .set(newUser.toMap());

      // Send email verification
      try {
        await credential.user!.sendEmailVerification();
        debugPrint('✅ Email verification sent to: $email');
      } catch (e) {
        debugPrint('⚠️ Email verification failed: $e');
        // Continue even if email fails - user can still use app
      }

      // Persist login by default
      await _auth.setPersistence(Persistence.LOCAL);
    } on FirebaseAuthException catch (e) {
      errorMessage = _getErrorMessage(e.code);
      isLoading = false;
      notifyListeners();
      throw Exception(errorMessage);
    } catch (e) {
      errorMessage = 'An error occurred. Please try again.';
      isLoading = false;
      notifyListeners();
      throw Exception(errorMessage);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> switchRole() async {
    if (appUser == null) return;

    final newRole = isAdmin ? UserRole.worker : UserRole.admin;
    final newRoleString = isAdmin ? 'agent' : 'admin';

    await _db.collection('users').doc(appUser!.uid).update({
      'role': newRoleString,
    });

    // Update local user object
    appUser = appUser!.copyWith(role: newRole);
    notifyListeners();
  }

  Future<void> updateUserProfile({
    String? displayName,
    String? username,
    String? photoURL,
    String? country,
    String? countryCode,
    String? phoneNumber,
    String? bio,
  }) async {
    if (appUser == null) return;

    try {
      final updatedUser = appUser!.copyWith(
        displayName: displayName,
        username: username,
        photoURL: photoURL,
        country: country,
        countryCode: countryCode,
        phoneNumber: phoneNumber,
        bio: bio,
      );

      await _db.collection('users').doc(appUser!.uid).update({
        if (displayName != null) 'displayName': displayName,
        if (username != null) 'username': username,
        if (photoURL != null) 'photoURL': photoURL,
        if (country != null) 'country': country,
        if (countryCode != null) 'countryCode': countryCode,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (bio != null) 'bio': bio,
      });

      appUser = updatedUser;
      notifyListeners();
    } catch (e) {
      errorMessage = 'Failed to update profile';
      notifyListeners();
    }
  }

  Future<String?> getEmailByUsername(String username) async {
    try {
      final querySnapshot = await _db
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data()['email'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    isLoading = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();
    try {
      await _auth.sendPasswordResetEmail(email: email);
      successMessage = 'Password reset email sent to $email.';
    } on FirebaseAuthException catch (e) {
      errorMessage = _getErrorMessage(e.code);
    } catch (e) {
      errorMessage = 'An error occurred. Please try again.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  bool get isAdmin => appUser?.role == UserRole.admin;

  /// Delete user account and all associated data
  Future<void> deleteAccount(String password) async {
    if (user == null) {
      throw Exception('No user logged in');
    }

    try {
      // Re-authenticate user before deletion
      final credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: password,
      );
      await user!.reauthenticateWithCredential(credential);

      // Delete user data from Firestore
      final uid = user!.uid;

      // Delete user document
      await _db.collection('users').doc(uid).delete();

      // Delete user's missions
      final missionsSnapshot = await _db
          .collection('missions')
          .where('createdBy', isEqualTo: uid)
          .get();
      for (var doc in missionsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete user's messages
      final messagesSnapshot = await _db
          .collection('lobby_messages')
          .where('senderId', isEqualTo: uid)
          .get();
      for (var doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete user's notifications
      final notificationsSnapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .get();
      for (var doc in notificationsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Finally, delete Firebase Auth account
      await user!.delete();

      debugPrint('✅ Account deleted successfully');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception('Incorrect password');
      } else if (e.code == 'requires-recent-login') {
        throw Exception(
          'Please log out and log in again before deleting your account',
        );
      }
      throw Exception(e.message ?? 'Failed to delete account');
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  /// Stream all users with their online status
  Stream<List<Map<String, dynamic>>> streamOnlineUsers() {
    return _db.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'uid': doc.id,
          'displayName': data['displayName'] ?? data['email'] ?? 'Unknown',
          'role': data['role'] ?? 'worker',
          'isOnline': data['isOnline'] ?? false,
          'lastSeen': data['lastSeen'],
        };
      }).toList();
    });
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered. Try logging in instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'user-not-found':
        return 'No account found. Try signing up instead.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid login credentials. Please check and try again.';
      case 'missing-email':
        return 'Please enter your email to continue.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
