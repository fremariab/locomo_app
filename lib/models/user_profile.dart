import 'package:cloud_firestore/cloud_firestore.dart';

// This class is just for handling user info (like name, email, etc.)
class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final DateTime createdAt;
  final String? profileImageUrl;
  final String country;
  final DateTime? defaultSearchDate;
  final String authProvider;

  // Constructor for creating a user profile
  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.createdAt,
    this.profileImageUrl,
    required this.country,
    this.defaultSearchDate,
    this.authProvider = 'email',
  });

  // This method creates a UserProfile object using data from Firestore
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return UserProfile(
      id: doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      profileImageUrl: data['profileImageUrl'],
      country: data['country'] ?? 'Ghana',
      defaultSearchDate: (data['defaultSearchDate'] as Timestamp?)?.toDate(),
      authProvider: data['authProvider'] ?? 'email',
    );
  }

  // This method turns the UserProfile object into a Map so we can save it in Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'profileImageUrl': profileImageUrl,
      'country': country,
      'defaultSearchDate': defaultSearchDate != null ? Timestamp.fromDate(defaultSearchDate!) : null,
      'authProvider': authProvider,
    };
  }
}
