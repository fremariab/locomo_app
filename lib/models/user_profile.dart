import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String fullName;
  final DateTime createdAt;
  final String? profileImageUrl;
  final String country;
  final String language;
  final String appearance;
  final DateTime? defaultSearchDate;
  final String? authProvider;

  UserProfile({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.createdAt,
    this.profileImageUrl,
    required this.country,
    required this.language,
    required this.appearance,
    this.defaultSearchDate,
    this.authProvider,
  });

  // Create a UserProfile from a Map (from Firestore)
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      profileImageUrl: map['profileImageUrl'],
      country: map['country'] ?? 'Ghana',
      language: map['language'] ?? 'English',
      appearance: map['appearance'] ?? 'Light',
      defaultSearchDate: map['defaultSearchDate'] != null
          ? (map['defaultSearchDate'] as Timestamp).toDate()
          : null,
      authProvider: map['authProvider'],
    );
  }

  // Convert UserProfile to a Map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'createdAt': Timestamp.fromDate(createdAt),
      'profileImageUrl': profileImageUrl,
      'country': country,
      'language': language,
      'appearance': appearance,
      'defaultSearchDate': defaultSearchDate != null
          ? Timestamp.fromDate(defaultSearchDate!)
          : null,
      'authProvider': authProvider,
    };
  }

  // Create a copy of UserProfile with updated fields
  UserProfile copyWith({
    String? uid,
    String? email,
    String? fullName,
    DateTime? createdAt,
    String? profileImageUrl,
    String? country,
    String? language,
    String? appearance,
    DateTime? defaultSearchDate,
    String? authProvider,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      createdAt: createdAt ?? this.createdAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      country: country ?? this.country,
      language: language ?? this.language,
      appearance: appearance ?? this.appearance,
      defaultSearchDate: defaultSearchDate ?? this.defaultSearchDate,
      authProvider: authProvider ?? this.authProvider,
    );
  }
}