import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:locomo_app/services/auth_service.dart';
import 'package:locomo_app/services/user_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserProfileService _userService = UserProfileService();
  User? _user;
  bool _isLoading = true;

  AuthProvider() {
    _initialize();
  }

  // Getters
  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get userId => _user?.uid;

  // Initialize auth state
  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    // Listen to auth state changes
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      _isLoading = false;
      notifyListeners();
    });
  }

  // Sign up with email and password
  Future<User?> signUp(String email, String password, String displayName) async {
    try {
      final userCredential = await _authService.signUpWithEmailAndPassword(email, password);
      
      // Update display name
      await _authService.updateDisplayName(displayName);
      
      // Create user profile in Firestore
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

  // Sign in with email and password
  Future<User?> signIn(String email, String password) async {
    try {
      final userCredential = await _authService.signInWithEmailAndPassword(email, password);
      return userCredential.user;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Send password reset email
  Future<void> resetPassword(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  // Update user profile
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

  // Update user email
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

  // Update user password
  Future<void> updateUserPassword(String password) async {
    try {
      await _authService.updatePassword(password);
    } catch (e) {
      rethrow;
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    try {
      if (_user != null) {
        // Delete user data from Firestore
        // Note: This should be handled with Firebase Cloud Functions in production
        // to ensure data is deleted even if client operation fails
        
        // Delete the auth account
        await _authService.deleteAccount();
      }
    } catch (e) {
      rethrow;
    }
  }
}