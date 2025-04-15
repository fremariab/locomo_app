import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';

class TrotroStation {
  final String id;
  final String name;
  final String? description;
  final double latitude;
  final double longitude;
  final List<String>? routes;
  final List<String>? stops;
  final double? fare;
Map<String, dynamic>? additionalInfo;

  TrotroStation({
    required this.id,
    required this.name,
    this.description,
    required this.latitude,
    required this.longitude,
    this.routes,
    this.stops,
    this.fare,
    this.additionalInfo,
  });

  // Factory constructor to create a Station from Firestore document
  factory TrotroStation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // Handle different coordinate storage formats
    double latitude, longitude;
    
    if (data.containsKey('lat') && data.containsKey('lng')) {
      // Direct fields format
      latitude = data['lat'];
      longitude = data['lng'];
    } else if (data.containsKey('coordinates')) {
      // Nested coordinates object
      final coordinates = data['coordinates'];
      latitude = coordinates['lat'];
      longitude = coordinates['lng'];
    } else if (data.containsKey('location')) {
      // GeoPoint format
      final location = data['location'];
      latitude = location.latitude;
      longitude = location.longitude;
    } else {
      // Default if no coordinates found (Accra)
      latitude = 5.6037;
      longitude = -0.1870;
    }
    
    return TrotroStation(
      id: doc.id,
      name: data['name'] ?? 'Unknown Station',
      description: data['description'],
      latitude: latitude,
      longitude: longitude,
      routes: data['routes'] != null 
          ? List<String>.from(data['routes']) 
          : null,
      stops: data['stops'] != null
          ? List<String>.from(data['stops'])
          : null,
      fare: data['fare']?.toDouble(),
      additionalInfo: data['additionalInfo'],
    );
  }

  // To JSON for caching locally
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'lat': latitude,
      'lng': longitude,
      'routes': routes,
      'stops': stops,
      'fare': fare,
      'additionalInfo': additionalInfo,
    };
  }

  // Create from JSON (for offline data)
  factory TrotroStation.fromJson(Map<String, dynamic> json) {
    return TrotroStation(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      latitude: json['lat'] ?? json['latitude'],
      longitude: json['lng'] ?? json['longitude'],
      routes: json['routes'] != null 
          ? List<String>.from(json['routes']) 
          : null,
      stops: json['stops'] != null
          ? List<String>.from(json['stops'])
          : null,
      fare: json['fare']?.toDouble(),
      additionalInfo: json['additionalInfo'],
    );
  }

  // Calculate distance to another location using the Haversine formula
  double distanceTo(double targetLat, double targetLng) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    double dLat = _toRadians(targetLat - latitude);
    double dLng = _toRadians(targetLng - longitude);
    
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(latitude)) * math.cos(_toRadians(targetLat)) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    
    double c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  // Helper method to convert degrees to radians
  double _toRadians(double degree) {
    return degree * (math.pi / 180);
  }

  // Check if this station serves a particular destination
  bool servesDestination(String destination) {
    if (stops == null) return false;
    
    // Convert both to lowercase for case-insensitive comparison
    final destLower = destination.toLowerCase();
    return stops!.any((stop) => stop.toLowerCase().contains(destLower));
  }

  // Get the location as a string for API calls
  String get locationString => '$latitude,$longitude';
}