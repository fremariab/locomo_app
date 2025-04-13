import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:locomo_app/models/user_profile.dart';

class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Your Imgur client ID
  final String _imgurClientId = '6d6de4859cac130';

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

  // Create user profile - keep as is
  Future<void> createUserProfile(String uid, String email, {String? displayName}) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'fullName': displayName ?? 'User',
        'createdAt': FieldValue.serverTimestamp(),
        'country': 'Ghana',
   /*      'language': 'English',
        'appearance': 'Light', */
        'profileImageUrl': null,
        'authProvider': 'email',
      });
    } catch (e) {
      print('❌ Create user profile failed: $e');
      rethrow;
    }
  }

  // Update user profile - keep as is
  Future<bool> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
      return true;
    } catch (e) {
      print('❌ Update user profile error: $e');
      return false;
    }
  }

  // Upload profile image - changed to use Imgur
  Future<String?> uploadProfileImage(String userId, File imageFile) async {
    try {
      // Create a multipart request for Imgur
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.imgur.com/3/image'),
      );
      
      // Add Imgur client ID header
      request.headers['Authorization'] = 'Client-ID $_imgurClientId';
      
      // Prepare the file for upload
      final fileBytes = await imageFile.readAsBytes();
      final fileExtension = imageFile.path.split('.').last.toLowerCase();
      final mimeType = 'image/$fileExtension';
      
      // Add the file to the request
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          fileBytes,
          filename: 'profile_$userId.$fileExtension',
          contentType: MediaType.parse(mimeType),
        ),
      );
      
      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        // Extract image URL from response
        final jsonData = json.decode(response.body);
        final imageUrl = jsonData['data']['link'];
        
        // Update user profile with the new URL in Firestore
        await updateUserProfile(userId, {'profileImageUrl': imageUrl});
        
        return imageUrl;
      } else {
        print('❌ Upload profile image error: ${response.body}');
      }
      
      return null;
    } catch (e) {
      print('❌ Upload profile image error: $e');
      return null;
    }
  }

  // The rest of your methods remain unchanged
  // Update country
  Future<bool> updateCountry(String userId, String country) async {
    return updateUserProfile(userId, {'country': country});
  }

  // Update language
/*   Future<bool> updateLanguage(String userId, String language) async {
    return updateUserProfile(userId, {'language': language});
  }
 */
  // Update appearance
/*   Future<bool> updateAppearance(String userId, String appearance) async {
    return updateUserProfile(userId, {'appearance': appearance});
  } */

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