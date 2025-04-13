import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final DateTime createdAt;
  final String? profileImageUrl;
  final String country;
  final String language;
  final String appearance;
  final DateTime? defaultSearchDate;
  final String authProvider;

  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.createdAt,
    this.profileImageUrl,
    required this.country,
    required this.language,
    required this.appearance,
    this.defaultSearchDate,
    this.authProvider = 'email',
  });

  // Factory constructor to create UserProfile from Firestore document
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      id: doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      profileImageUrl: data['profileImageUrl'],
      country: data['country'] ?? 'Ghana',
      language: data['language'] ?? 'English',
      appearance: data['appearance'] ?? 'Light',
      defaultSearchDate: (data['defaultSearchDate'] as Timestamp?)?.toDate(),
      authProvider: data['authProvider'] ?? 'email',
    );
  }

  // Convert to Map for updating in Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'profileImageUrl': profileImageUrl,
      'country': country,
      'language': language,
      'appearance': appearance,
      'defaultSearchDate': defaultSearchDate != null ? Timestamp.fromDate(defaultSearchDate!) : null,
      'authProvider': authProvider,
    };
  }
}