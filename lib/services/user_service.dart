import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:locomo_app/models/user_profile.dart';

class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user document reference
  DocumentReference _userDoc(String userId) => _firestore.collection('users').doc(userId);

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Get user profile from Firestore
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _userDoc(userId).get();
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('❌ Failed to get user profile: $e');
      return null;
    }
  }

  // Update specific user profile fields
  Future<bool> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _userDoc(userId).update(data);
      return true;
    } catch (e) {
      print('❌ Failed to update user profile: $e');
      return false;
    }
  }

  // Upload profile image
  Future<String?> uploadProfileImage(String userId, File imageFile) async {
    try {
      final ref = _storage.ref().child('profile_images/$userId/profile.jpg');
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() => null);
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Update profile with image URL
      await _userDoc(userId).update({'profileImageUrl': downloadUrl});
      
      return downloadUrl;
    } catch (e) {
      print('❌ Failed to upload profile image: $e');
      return null;
    }
  }

  // Get saved routes for user
  Future<List<Map<String, dynamic>>> getSavedRoutes(String userId) async {
    try {
      final snapshot = await _userDoc(userId).collection('savedRoutes').get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('❌ Failed to get saved routes: $e');
      return [];
    }
  }

  // Save a route
  Future<bool> saveRoute(String userId, Map<String, dynamic> routeData) async {
    try {
      final routeId = routeData['id'] ?? _firestore.collection('temp').doc().id;
      routeData['id'] = routeId;
      routeData['savedAt'] = FieldValue.serverTimestamp();
      
      await _userDoc(userId).collection('savedRoutes').doc(routeId).set(routeData);
      return true;
    } catch (e) {
      print('❌ Failed to save route: $e');
      return false;
    }
  }

  // Delete a saved route
  Future<bool> deleteRoute(String userId, String routeId) async {
    try {
      await _userDoc(userId).collection('savedRoutes').doc(routeId).delete();
      return true;
    } catch (e) {
      print('❌ Failed to delete route: $e');
      return false;
    }
  }

  // Update user appearance setting
  Future<bool> updateAppearance(String userId, String appearance) async {
    return updateUserProfile(userId, {'appearance': appearance});
  }

  // Update user language
  Future<bool> updateLanguage(String userId, String language) async {
    return updateUserProfile(userId, {'language': language});
  }

  // Update user country
  Future<bool> updateCountry(String userId, String country) async {
    return updateUserProfile(userId, {'country': country});
  }

  // Update default search date
  Future<bool> updateDefaultSearchDate(String userId, DateTime date) async {
    return updateUserProfile(userId, {'defaultSearchDate': Timestamp.fromDate(date)});
  }
}