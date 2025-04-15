import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:locomo_app/services/auth_service.dart';
import 'package:locomo_app/services/user_service.dart';

// This class manages everything related to user authentication
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserProfileService _userService = UserProfileService();
  User? _user;
  bool _isLoading = true;

  // This runs automatically when the app starts to check if a user is already logged in
  AuthProvider() {
    _initialize();
  }

  // Quick access to user info
  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get userId => _user?.uid;

  // This checks if the user is signed in or not and keeps listening for changes
  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    _authService.authStateChanges.listen((User? user) {
      _user = user;
      _isLoading = false;
      notifyListeners();
    });
  }

  // Sign up with email, password, and name
  Future<User?> signUp(String email, String password, String displayName) async {
    try {
      final userCredential = await _authService.signUpWithEmailAndPassword(email, password);

      await _authService.updateDisplayName(displayName);

      // After signing up, also create a profile for the user in Firestore
      await _userService.createUserProfile(
        userCredential.user!.uid,
        email,
        displayName: displayName,
      );

      return userCredential.user;
    } catch (e) {
      rethrow;
    }
  }

  // Login using email and password
  Future<User?> signIn(String email, String password) async {
    try {
      final userCredential = await _authService.signInWithEmailAndPassword(email, password);
      return userCredential.user;
    } catch (e) {
      rethrow;
    }
  }

  // Log out the current user
  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Let user request a password reset email
  Future<void> resetPassword(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  // Update the name that shows on the user's profile
  Future<void> updateUserDisplayName(String displayName) async {
    try {
      await _authService.updateDisplayName(displayName);

      if (_user != null) {
        await _userService.updateUserProfile(_user!.uid, {
          'fullName': displayName,
        });
      }

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Update the user's email address
  Future<void> updateUserEmail(String email) async {
    try {
      await _authService.updateEmail(email);

      if (_user != null) {
        await _userService.updateUserProfile(_user!.uid, {
          'email': email,
        });
      }

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Change the user's password
  Future<void> updateUserPassword(String password) async {
    try {
      await _authService.updatePassword(password);
    } catch (e) {
      rethrow;
    }
  }

  // Completely delete a user account (auth + their data)
  Future<void> deleteAccount() async {
    try {
      if (_user != null) {
        // In production, you'd want to make sure Firestore user data gets deleted from a backend function too
        await _authService.deleteAccount();
      }
    } catch (e) {
      rethrow;
    }
  }
}
