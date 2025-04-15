import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Register user and save data to Firestore
  Future<Map<String, dynamic>> registerWithEmail(String email, String password, String fullName) async {
    User? user;
    bool firestoreSuccess = false;

    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      user = result.user;

      if (user != null) {
        try {
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email,
            'fullName': fullName,
            'createdAt': FieldValue.serverTimestamp(),
            'country': 'Ghana',
            'profileImageUrl': null,
            'authProvider': 'email',
          });
          await user.updateDisplayName(fullName);
          firestoreSuccess = true;
        } catch (e) {
          debugPrint('Firestore write failed: $e');
        }
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Auth error: ${e.message}');
      throw FirebaseAuthException(code: e.code, message: e.message);
    } catch (e) {
      debugPrint('Unexpected registration error: $e');
      throw Exception("Unexpected error: $e");
    }

    return {
      'user': user,
      'firestoreSuccess': firestoreSuccess,
    };
  }

  // Sign up only (without saving to Firestore)
  Future<UserCredential> signUpWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      debugPrint('Sign-up error: $e');
      rethrow;
    }
  }

  // Sign in using email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      debugPrint('Sign-in error: $e');
      rethrow;
    }
  }

  // Used after login to make sure user exists in Firestore
  Future<bool> ensureUserInFirestore(User user, String fullName) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'fullName': fullName.isNotEmpty ? fullName : user.displayName ?? 'User',
          'createdAt': FieldValue.serverTimestamp(),
          'country': 'Ghana',
          'profileImageUrl': null,
          'authProvider': 'email',
        });
      }

      return true;
    } catch (e) {
      debugPrint('Failed to ensure Firestore record: $e');
      return false;
    }
  }

  // Legacy sign in using email (returns User not UserCredential)
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return result.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') {
        throw Exception('No internet connection.');
      }
      throw e;
    } catch (e) {
      if (e.toString().contains('network') || e.toString().contains('socket') || e.toString().contains('timeout')) {
        throw Exception('No internet connection.');
      }
      throw e;
    }
  }

  // Google sign-in and Firestore sync
  Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      final user = result.user;

      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();

        if (!doc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email,
            'fullName': user.displayName ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'authProvider': 'google',
            'country': 'Ghana',
            'profileImageUrl': user.photoURL,
          });
        }
      }

      return user;
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      return null;
    }
  }

  // Update user display name
  Future<void> updateDisplayName(String displayName) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
      }
    } catch (e) {
      debugPrint('Update name failed: $e');
      rethrow;
    }
  }

  // Update user email
  Future<void> updateEmail(String email) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateEmail(email);
      }
    } catch (e) {
      debugPrint('Update email failed: $e');
      rethrow;
    }
  }

  // Update user password
  Future<void> updatePassword(String password) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(password);
      }
    } catch (e) {
      debugPrint('Update password failed: $e');
      rethrow;
    }
  }

  // Reset password via email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Reset email failed: $e');
      rethrow;
    }
  }

  // Basic password reset (used with boolean return)
  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') {
        throw Exception('No internet connection.');
      }
      throw e;
    } catch (e) {
      if (e.toString().contains('network') || e.toString().contains('timeout')) {
        throw Exception('No internet connection.');
      }
      throw e;
    }
  }

  // Update profile fields
  Future<bool> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
      return true;
    } catch (e) {
      debugPrint('Update profile failed: $e');
      return false;
    }
  }

  // Helper methods for profile fields
  Future<bool> updateCountry(String userId, String country) async {
    return updateUserProfile(userId, {'country': country});
  }

  Future<bool> updateLanguage(String userId, String language) async {
    return updateUserProfile(userId, {'language': language});
  }

  Future<bool> updateAppearance(String userId, String appearance) async {
    return updateUserProfile(userId, {'appearance': appearance});
  }

  Future<bool> updateDefaultSearchDate(String userId, DateTime defaultSearchDate) async {
    return updateUserProfile(userId, {'defaultSearchDate': Timestamp.fromDate(defaultSearchDate)});
  }

  // Delete user account and Firestore data
  Future<bool> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).delete();
        await user.delete();
      }
      return true;
    } catch (e) {
      debugPrint('Account delete failed: $e');
      return false;
    }
  }

  // Get the current signed-in user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Listen for auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign out of app and Google
  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }
}
