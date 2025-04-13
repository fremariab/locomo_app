import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
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

    // Get current user
    _user = _authService.getCurrentUser();
    
    // Listen to auth state changes
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      _isLoading = false;
      notifyListeners();
    });
  }

  // Register with email and password
  Future<Map<String, dynamic>> register(String email, String password, String fullName) async {
    try {
      final result = await _authService.registerWithEmail(email, password, fullName);
      notifyListeners();
      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with email and password
  Future<User?> signIn(String email, String password) async {
    try {
      final user = await _authService.signInWithEmail(email, password);
      notifyListeners();
      return user;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      final user = await _authService.signInWithGoogle();
      notifyListeners();
      return user;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      return await _authService.resetPassword(email);
    } catch (e) {
      rethrow;
    }
  }

  // Delete account
  Future<bool> deleteAccount() async {
    try {
      final result = await _authService.deleteAccount();
      notifyListeners();
      return result;
    } catch (e) {
      rethrow;
    }
  }
}