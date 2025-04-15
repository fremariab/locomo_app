import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:locomo_app/models/user_profile.dart';
import 'package:flutter/material.dart';

class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _imgurClientId = '6d6de4859cac130'; // Imgur Client ID

  // Fetches the user profile from Firestore
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Get user profile error: $e');
      rethrow;
    }
  }

  // Creates a new user profile with default values
  Future<void> createUserProfile(String uid, String email, {String? displayName}) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'fullName': displayName ?? 'User',
        'createdAt': FieldValue.serverTimestamp(),
        'country': 'Ghana',
        'profileImageUrl': null,
        'authProvider': 'email',
      });
    } catch (e) {
      debugPrint('Create user profile error: $e');
      rethrow;
    }
  }

  // Updates fields in the user profile
  Future<bool> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
      return true;
    } catch (e) {
      debugPrint('Update user profile error: $e');
      return false;
    }
  }

  // Uploads an image to Imgur and updates the user's profile image URL
  Future<String?> uploadProfileImage(String userId, File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.imgur.com/3/image'),
      );

      request.headers['Authorization'] = 'Client-ID $_imgurClientId';

      final fileBytes = await imageFile.readAsBytes();
      final fileExtension = imageFile.path.split('.').last.toLowerCase();
      final mimeType = 'image/$fileExtension';

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          fileBytes,
          filename: 'profile_$userId.$fileExtension',
          contentType: MediaType.parse(mimeType),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final imageUrl = jsonData['data']['link'];
        await updateUserProfile(userId, {'profileImageUrl': imageUrl});
        return imageUrl;
      } else {
        debugPrint('Imgur upload error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Upload image error: $e');
      return null;
    }
  }

  // Updates country field
  Future<bool> updateCountry(String userId, String country) async {
    return updateUserProfile(userId, {'country': country});
  }

  // Updates default search date
  Future<bool> updateDefaultSearchDate(String userId, DateTime date) async {
    return updateUserProfile(userId, {
      'defaultSearchDate': Timestamp.fromDate(date),
    });
  }

  // Gets list of saved routes for the user
  Future<List<Map<String, dynamic>>> getSavedRoutes(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_routes')
          .orderBy('savedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (e) {
      debugPrint('Get saved routes error: $e');
      return [];
    }
  }

  // Deletes a saved route by ID
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
      debugPrint('Delete route error: $e');
      return false;
    }
  }

  // Saves a new route to Firestore
  Future<bool> saveRoute(String userId, Map<String, dynamic> routeData) async {
    try {
      routeData['savedAt'] = FieldValue.serverTimestamp();
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_routes')
          .add(routeData);
      return true;
    } catch (e) {
      debugPrint('Save route error: $e');
      return false;
    }
  }
}
