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
  final bool isStation;

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
    required this.isStation,
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
      isStation: false,
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
    bool isStation = false,
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
      isStation: isStation,
    );
  }

  factory TrotroStation.fromFirestore(DocumentSnapshot doc) {
    final raw = doc.data();
    if (raw == null) return TrotroStation.notFound(doc.id);
    final data = raw as Map<String, dynamic>;

    // 1️⃣ Parse coordinates (GeoPoint or nested Map)
    double latitude, longitude;
    final coordsField = data['coordinates'];
    if (coordsField is GeoPoint) {
      latitude = coordsField.latitude;
      longitude = coordsField.longitude;
    } else if (coordsField is Map<String, dynamic> &&
        coordsField['lat'] != null &&
        coordsField['lng'] != null) {
      latitude = (coordsField['lat'] as num).toDouble();
      longitude = (coordsField['lng'] as num).toDouble();
    } else if (data['location'] is GeoPoint) {
      // fallback if you stored under `location`
      final gp = data['location'] as GeoPoint;
      latitude = gp.latitude;
      longitude = gp.longitude;
    } else {
      // final fallback to a sane default
      print("⚠️ No valid coords for ${doc.id}, defaulting to Accra");
      latitude = 5.6037;
      longitude = -0.1870;
    }

    // 2️⃣ Parse connections array
    List<Map<String, dynamic>>? parsedConnections;
    final rawConns = data['connections'];
    if (rawConns is List) {
      parsedConnections = rawConns.whereType<Map<String, dynamic>>().toList();
      print('✅ Parsed ${parsedConnections.length} connections for ${doc.id}');
    } else {
      print('⚠️ No connections array for ${doc.id}');
    }

    return TrotroStation(
      id: doc.id,
      name: data['name'] ?? doc.id,
      latitude: latitude,
      longitude: longitude,
      description: data['description'],
      imageUrl: data['imageUrl'],
      routes: _parseStringList(data['routes']),
      stops: _parseStringList(data['stops']),
      facilities: _parseStringList(data['facilities']),
      fare: data['fare']?.toDouble(),
      additionalInfo: data['additionalInfo'] != null
          ? Map<String, dynamic>.from(data['additionalInfo'])
          : null,
      connections: parsedConnections,
      isStation: true,
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
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

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
