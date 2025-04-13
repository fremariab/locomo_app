import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:locomo_app/models/user_profile.dart';

class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get user profile from Firestore
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(userId).get();
      
      if (docSnapshot.exists) {
        return UserProfile.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      print('❌ Get user profile error: $e');
      rethrow;
    }
  }

  // Create user profile
  Future<void> createUserProfile(String uid, String email, {String? displayName}) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'fullName': displayName ?? 'User',
        'createdAt': FieldValue.serverTimestamp(),
        'country': 'Ghana',
        'language': 'English',
        'appearance': 'Light',
        'profileImageUrl': null,
        'authProvider': 'email',
      });
    } catch (e) {
      print('❌ Create user profile failed: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
      return true;
    } catch (e) {
      print('❌ Update user profile error: $e');
      return false;
    }
  }

  // Upload profile image
  Future<String?> uploadProfileImage(String userId, File imageFile) async {
    try {
      final ref = _storage.ref().child('profile_images').child('$userId.jpg');
      
      // Upload file
      await ref.putFile(imageFile);
      
      // Get download URL
      final downloadUrl = await ref.getDownloadURL();
      
      // Update user profile with new image URL
      await updateUserProfile(userId, {'profileImageUrl': downloadUrl});
      
      return downloadUrl;
    } catch (e) {
      print('❌ Upload profile image error: $e');
      return null;
    }
  }

  // Update country
  Future<bool> updateCountry(String userId, String country) async {
    return updateUserProfile(userId, {'country': country});
  }

  // Update language
  Future<bool> updateLanguage(String userId, String language) async {
    return updateUserProfile(userId, {'language': language});
  }

  // Update appearance
  Future<bool> updateAppearance(String userId, String appearance) async {
    return updateUserProfile(userId, {'appearance': appearance});
  }

  // Update default search date
  Future<bool> updateDefaultSearchDate(String userId, DateTime date) async {
    return updateUserProfile(
      userId, 
      {'defaultSearchDate': Timestamp.fromDate(date)}
    );
  }

  // Get saved routes
  Future<List<Map<String, dynamic>>> getSavedRoutes(String userId) async {
    try {
      final routesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_routes')
          .orderBy('savedAt', descending: true)
          .get();
      
      return routesSnapshot.docs.map((doc) {
        final data = doc.data();
        // Add the document ID to the map
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('❌ Get saved routes error: $e');
      return [];
    }
  }

  // Delete a saved route
  Future<bool> deleteRoute(String userId, String routeId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_routes')
          .doc(routeId)
          .delete();
      return true;
    } catch (e) {
      print('❌ Delete route error: $e');
      return false;
    }
  }

  // Save a new route
  Future<bool> saveRoute(String userId, Map<String, dynamic> routeData) async {
    try {
      // Add timestamp when the route was saved
      routeData['savedAt'] = FieldValue.serverTimestamp();
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_routes')
          .add(routeData);
      return true;
    } catch (e) {
      print('❌ Save route error: $e');
      return false;
    }
  }
}