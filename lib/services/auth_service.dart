import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Register with email
  Future<Map<String, dynamic>> registerWithEmail(String email, String password, String fullName) async {
    User? user;
    bool firestoreSuccess = false;
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      user = result.user;
      if (user != null) {
        try {
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email,
            'fullName': fullName,
            'createdAt': FieldValue.serverTimestamp(),
            'country': 'Ghana', 
/*             'language': 'English',
            'appearance': 'Light', */
            'profileImageUrl': null,
            'authProvider': 'email',
          });
          await user.updateDisplayName(fullName);
          firestoreSuccess = true;
        } catch (e) {
          print(' Firestore error: $e');
        }
      }
    } on FirebaseAuthException catch (e) {
      print(' FirebaseAuthException: ${e.message}');
      throw FirebaseAuthException(code: e.code, message: e.message);
    } catch (e) {
      print(' Unexpected registration error: $e');
      throw Exception("Unexpected error: $e");
    }
    return {
      'user': user,
      'firestoreSuccess': firestoreSuccess,
    };
  }

  // Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print(' Sign up failed: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print(' Sign in failed: $e');
      rethrow;
    }
  }

  // Ensure user data exists in Firestore
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
/*           'language': 'English',
          'appearance': 'Light', */
          'profileImageUrl': null,
          'authProvider': 'email',
        });
      }
      return true;
    } catch (e) {
      print(' ensureUserInFirestore failed: $e');
      return false;
    }
  }

  // Sign in with email and password (for backward compatibility)
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('Login failed: $e');
      
      // Check for network-related errors in Firebase exceptions
      if (e.code == 'network-request-failed') {
        throw Exception('No internet connection. Please check your network and try again.');
      }
      
      // For other Firebase errors, throw the original exception
      throw e;
    } catch (e) {
      print('Login failed: $e');
      
      // Check if it's a network-related error
      if (e.toString().contains('network') || 
          e.toString().contains('connection') || 
          e.toString().contains('socket') ||
          e.toString().contains('timeout')) {
        throw Exception('No internet connection. Please check your network and try again.');
      }
      
      // For other errors, throw the original exception
      throw e;
    }
  }

  // Sign in with Google
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
/*             'language': 'English',
            'appearance': 'Light', */
            'profileImageUrl': user.photoURL,
          });
        }
      }
      return user;
    } catch (e) {
      print(' Google sign-in error: $e');
      return null;
    }
  }

  // Update display name
  Future<void> updateDisplayName(String displayName) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
      }
    } catch (e) {
      print(' Update display name failed: $e');
      rethrow;
    }
  }

  // Update email
  Future<void> updateEmail(String email) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updateEmail(email);
      }
    } catch (e) {
      print(' Update email failed: $e');
      rethrow;
    }
  }

  // Update password
  Future<void> updatePassword(String password) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(password);
      }
    } catch (e) {
      print(' Update password failed: $e');
      rethrow;
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print(' Send password reset email failed: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      print(' Password reset failed: $e');
      
      // Check for network-related errors in Firebase exceptions
      if (e.code == 'network-request-failed') {
        throw Exception('No internet connection. Please check your network and try again.');
      }
      
      // For other Firebase errors, throw the original exception
      throw e;
    } catch (e) {
      print(' Password reset failed: $e');
      
      // Check if it's a network-related error
      if (e.toString().contains('network') || 
          e.toString().contains('connection') || 
          e.toString().contains('socket') ||
          e.toString().contains('timeout')) {
        throw Exception('No internet connection. Please check your network and try again.');
      }
      
      // For other errors, throw the original exception
      throw e;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
      return true;
    } catch (e) {
      print(' Profile update failed: $e');
      return false;
    }
  }

  // Update user country
  Future<bool> updateCountry(String userId, String country) async {
    return updateUserProfile(userId, {'country': country});
  }

  // Update user language
  Future<bool> updateLanguage(String userId, String language) async {
    return updateUserProfile(userId, {'language': language});
  }

  // Update app appearance
  Future<bool> updateAppearance(String userId, String appearance) async {
    return updateUserProfile(userId, {'appearance': appearance});
  }

  // Update default search date
  Future<bool> updateDefaultSearchDate(String userId, DateTime defaultSearchDate) async {
    return updateUserProfile(userId, {'defaultSearchDate': Timestamp.fromDate(defaultSearchDate)});
  }

  // Delete user account
  Future<bool> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).delete();
        await user.delete();
      }
      return true;
    } catch (e) {
      print(' Account deletion failed: $e');
      return false;
    }
  }

 
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}