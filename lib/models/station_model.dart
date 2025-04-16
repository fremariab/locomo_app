// import 'dart:math' as math;
// import 'package:cloud_firestore/cloud_firestore.dart';

// class TrotroStation {
//   static const String tempIdPrefix = 'temp_';
  
//   final String id;
//   final String name;
//   final String? description;
//   final String? imageUrl;
//   final double latitude;
//   final double longitude;
//   final List<String>? routes;
//   final List<String>? stops;
//   final List<String>? facilities;
//   final double? fare;
//   final Map<String, dynamic>? additionalInfo;

//   TrotroStation({
//     required this.id,
//     required this.name,
//     this.description,
//     this.imageUrl,
//     required this.latitude,
//     required this.longitude,
//     this.routes,
//     this.stops,
//     this.facilities,
//     this.fare,
//     this.additionalInfo,
//   }) {
//     if (name.isEmpty) {
//       throw ArgumentError('Station name cannot be empty');
//     }
//   }

//   // Factory method for not found stations
//   factory TrotroStation.notFound(String stationName) {
//     return TrotroStation(
//       id: 'not_found_${DateTime.now().millisecondsSinceEpoch}',
//       name: stationName,
//       latitude: 0.0,
//       longitude: 0.0,
//     );
//   }

//   // Factory constructor for temporary stations
//   factory TrotroStation.temporary({
//     required String name,
//     required double latitude,
//     required double longitude,
//     String? description,
//     String? imageUrl,
//     List<String>? routes,
//     List<String>? stops,
//     List<String>? facilities,
//     double? fare,
//     Map<String, dynamic>? additionalInfo,
//   }) {
//     return TrotroStation(
//       id: '$tempIdPrefix${DateTime.now().millisecondsSinceEpoch}',
//       name: name,
//       latitude: latitude,
//       longitude: longitude,
//       description: description,
//       imageUrl: imageUrl,
//       routes: routes,
//       stops: stops,
//       facilities: facilities,
//       fare: fare,
//       additionalInfo: additionalInfo,
//     );
//   }

//   // Factory constructor from Firestore
//   factory TrotroStation.fromFirestore(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;
    
//     double latitude, longitude;
//     if (data.containsKey('lat') && data.containsKey('lng')) {
//       latitude = (data['lat'] as num).toDouble();
//       longitude = (data['lng'] as num).toDouble();
//     } else if (data.containsKey('coordinates')) {
//       final coordinates = data['coordinates'] as Map<String, dynamic>;
//       latitude = (coordinates['lat'] as num).toDouble();
//       longitude = (coordinates['lng'] as num).toDouble();
//     } else if (data.containsKey('location')) {
//       final location = data['location'] as GeoPoint;
//       latitude = location.latitude;
//       longitude = location.longitude;
//     } else {
//       latitude = 5.6037;  // Default Accra coordinates
//       longitude = -0.1870;
//     }

//     return TrotroStation(
//       id: doc.id,
//       name: data['name'] ?? 'Unknown Station',
//       description: data['description'],
//       imageUrl: data['imageUrl'],
//       latitude: latitude,
//       longitude: longitude,
//       routes: _parseStringList(data['routes']),
//       stops: _parseStringList(data['stops']),
//       facilities: _parseStringList(data['facilities']),
//       fare: data['fare']?.toDouble(),
//       additionalInfo: data['additionalInfo'] != null
//           ? Map<String, dynamic>.from(data['additionalInfo'])
//           : null,
//     );
//   }

//   static List<String>? _parseStringList(dynamic data) {
//     if (data == null) return null;
//     if (data is List) return List<String>.from(data);
//     return null;
//   }


//   double distanceTo(double targetLat, double targetLng) {
//     const double earthRadius = 6371; // km
    
//     double dLat = _toRadians(targetLat - latitude);
//     double dLng = _toRadians(targetLng - longitude);
    
//     double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
//         math.cos(_toRadians(latitude)) * 
//         math.cos(_toRadians(targetLat)) *
//         math.sin(dLng / 2) * math.sin(dLng / 2);
    
//     double c = 2 * math.asin(math.sqrt(a));
//     return earthRadius * c;
//   }

//   double _toRadians(double degree) => degree * (math.pi / 180);

//   bool servesDestination(String destination) {
//     if (stops == null) return false;
//     final destLower = destination.toLowerCase();
//     return stops!.any((stop) => stop.toLowerCase().contains(destLower));
//   }

//   String get locationString => '$latitude,$longitude';

//   String get formattedFacilities {
//     if (facilities == null || facilities!.isEmpty) {
//       return 'No facilities listed';
//     }
//     return facilities!.join(', ');
//   }

//   bool hasFacility(String facility) {
//     if (facilities == null) return false;
//     return facilities!.any((f) => f.toLowerCase() == facility.toLowerCase());
//   }

//   bool get isTemporary => id.startsWith(tempIdPrefix);
// }

import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';

class TrotroStation {
  static const String tempIdPrefix = 'temp_';

  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final double latitude;
  final double longitude;
  final List<String>? routes;
  final List<String>? stops;
  final List<String>? facilities;
  final double? fare;
  final Map<String, dynamic>? additionalInfo;

  /// ✅ New: connections to other stations
  final List<Map<String, dynamic>>? connections;

  TrotroStation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.description,
    this.imageUrl,
    this.routes,
    this.stops,
    this.facilities,
    this.fare,
    this.additionalInfo,
    this.connections,
  }) {
    if (name.isEmpty) {
      throw ArgumentError('Station name cannot be empty');
    }
  }

  factory TrotroStation.notFound(String stationName) {
    return TrotroStation(
      id: 'not_found_${DateTime.now().millisecondsSinceEpoch}',
      name: stationName,
      latitude: 0.0,
      longitude: 0.0,
    );
  }

  factory TrotroStation.temporary({
    required String name,
    required double latitude,
    required double longitude,
    String? description,
    String? imageUrl,
    List<String>? routes,
    List<String>? stops,
    List<String>? facilities,
    double? fare,
    Map<String, dynamic>? additionalInfo,
    List<Map<String, dynamic>>? connections,
  }) {
    return TrotroStation(
      id: '$tempIdPrefix${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      latitude: latitude,
      longitude: longitude,
      description: description,
      imageUrl: imageUrl,
      routes: routes,
      stops: stops,
      facilities: facilities,
      fare: fare,
      additionalInfo: additionalInfo,
      connections: connections,
    );
  }

  factory TrotroStation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    double latitude, longitude;
    if (data.containsKey('lat') && data.containsKey('lng')) {
      latitude = (data['lat'] as num).toDouble();
      longitude = (data['lng'] as num).toDouble();
    } else if (data.containsKey('coordinates')) {
      final coordinates = data['coordinates'] as Map<String, dynamic>;
      latitude = (coordinates['lat'] as num).toDouble();
      longitude = (coordinates['lng'] as num).toDouble();
    } else if (data.containsKey('location')) {
      final location = data['location'] as GeoPoint;
      latitude = location.latitude;
      longitude = location.longitude;
    } else {
      latitude = 5.6037; // Default Accra coords
      longitude = -0.1870;
    }

    // ✅ Parse connections if present
    final connectionsRaw = data['connections'];
    List<Map<String, dynamic>>? parsedConnections;
    if (connectionsRaw is List) {
      parsedConnections = connectionsRaw
          .whereType<Map>() // filter valid maps only
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    return TrotroStation(
      id: doc.id,
      name: data['name'] ?? 'Unknown Station',
      description: data['description'],
      imageUrl: data['imageUrl'],
      latitude: latitude,
      longitude: longitude,
      routes: _parseStringList(data['routes']),
      stops: _parseStringList(data['stops']),
      facilities: _parseStringList(data['facilities']),
      fare: data['fare']?.toDouble(),
      additionalInfo: data['additionalInfo'] != null
          ? Map<String, dynamic>.from(data['additionalInfo'])
          : null,
      connections: parsedConnections,
    );
  }

  static List<String>? _parseStringList(dynamic data) {
    if (data == null) return null;
    if (data is List) return List<String>.from(data);
    return null;
  }

  double distanceTo(double targetLat, double targetLng) {
    const double earthRadius = 6371;
    double dLat = _toRadians(targetLat - latitude);
    double dLng = _toRadians(targetLng - longitude);

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(latitude)) *
            math.cos(_toRadians(targetLat)) *
            math.sin(dLng / 2) * math.sin(dLng / 2);

    double c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * (math.pi / 180);

  bool servesDestination(String destination) {
    if (stops == null) return false;
    final destLower = destination.toLowerCase();
    return stops!.any((stop) => stop.toLowerCase().contains(destLower));
  }

  String get locationString => '$latitude,$longitude';

  String get formattedFacilities {
    if (facilities == null || facilities!.isEmpty) {
      return 'No facilities listed';
    }
    return facilities!.join(', ');
  }

  bool hasFacility(String facility) {
    if (facilities == null) return false;
    return facilities!.any((f) => f.toLowerCase() == facility.toLowerCase());
  }

  bool get isTemporary => id.startsWith(tempIdPrefix);
}
