// import 'package:latlong2/latlong.dart';

// export 'route.dart';
import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';

List<LatLng> _decodePolyline(String encoded) {
  List<LatLng> points = [];
  int index = 0, len = encoded.length;
  int lat = 0, lng = 0;

  while (index < len) {
    int b, shift = 0, result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lat += dlat;

    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lng += dlng;

    points.add(LatLng(lat / 1E5, lng / 1E5));
  }
  return points;
}
class RouteSegment {
  final String description;
  final double fare;
  final int duration; // in minutes
  final String type; // 'bus', 'walk', etc.
  final String? departureTime;
   List<LatLng>? polyline;

  RouteSegment({
    required this.description,
    required this.fare,
    required this.duration,
    required this.type,
    this.departureTime,
    this.polyline,
  });
  
  // Factory method to create a RouteSegment from a JSON map
  factory RouteSegment.fromJson(Map<String, dynamic> json) {
  return RouteSegment(
    description: json['description']?.toString() ?? '',
    fare: (json['fare'] ?? 0).toDouble(),
    duration: json['duration']?.toInt() ?? 0,
    type: json['type']?.toString() ?? 'unknown',
    departureTime: json['departureTime']?.toString(),
    polyline: json['polyline'] != null
        ? (json['polyline'] as List)
            .map((p) => LatLng(p['lat'], p['lng']))
            .toList()
        : null,
  );
}

Map<String, dynamic> toJson() {
  return {
    'description': description,
    'fare': fare,
    'duration': duration,
    'type': type,
    'departureTime': departureTime,
    'polyline': polyline
        ?.map((p) => {'lat': p.latitude, 'lng': p.longitude})
        .toList(),
  };
}

}

class CompositeRoute {
  final List<RouteSegment> segments;
  final double totalFare;
  final int totalDuration;
  final String departureTime;
  final String arrivalTime;
  final String? origin;
  final String? destination;

  CompositeRoute({
    required this.segments,
    required this.totalFare,
    required this.totalDuration,
    required this.departureTime,
    required this.arrivalTime,
    this.origin,
    this.destination,
  });

  // Factory method to create a CompositeRoute from a map
  factory CompositeRoute.fromMap(Map<String, dynamic> map) {
  final List<RouteSegment> routeSegments = [];

  // Process each segment in the route
  final segments = map['segments'] as List? ?? [];
  for (var segment in segments) {
    final segmentMap = segment as Map<String, dynamic>;
    
    // Process polyline data
    List<LatLng>? polylinePoints;
    if (segmentMap['polyline'] != null) {
      try {
        if (segmentMap['polyline'] is String) {
          // If it's an encoded polyline string
          polylinePoints = _decodePolyline(segmentMap['polyline']);
        } else if (segmentMap['polyline'] is List) {
          // If it's already a list of coordinates
          polylinePoints = (segmentMap['polyline'] as List)
              .map((p) => LatLng(p['lat'], p['lng']))
              .toList();
        }
      } catch (e) {
        print('Error processing polyline data: $e');
      }
    }
    
    final routeSegment = RouteSegment(
      description: segmentMap['description']?.toString() ?? '',
      fare: (segmentMap['fare'] ?? 0).toDouble(),
      duration: segmentMap['duration']?.toInt() ?? 0,
      type: segmentMap['type']?.toString() ?? 'unknown',
      departureTime: segmentMap['departureTime']?.toString(),
      polyline: polylinePoints,  // Add this line to include polyline data
    );

    routeSegments.add(routeSegment);
  }

  return CompositeRoute(
    segments: routeSegments,
    totalFare: (map['totalFare'] ?? 0).toDouble(),
    totalDuration: map['totalDuration']?.toInt() ?? 0,
    departureTime: map['departureTime']?.toString() ?? 'Now',
    arrivalTime: map['arrivalTime']?.toString() ?? 'Later',
    origin: map['origin']?.toString(),
    destination: map['destination']?.toString(),
  );
}
  // Convert the route to a map for storage
Map<String, dynamic> toJson() {
    return {
      'segments': segments
          .map((segment) => {
                'description': segment.description,
                'fare': segment.fare,
                'duration': segment.duration,
                'type': segment.type,
                'departureTime': segment.departureTime,
                'polyline': segment.polyline != null
                    ? jsonEncode(segment.polyline!
                        .map((e) => {'lat': e.latitude, 'lng': e.longitude})
                        .toList())
                    : null,
              })
          .toList(),
      'totalFare': totalFare,
      'totalDuration': totalDuration,
      'departureTime': departureTime,
      'arrivalTime': arrivalTime,
      'origin': origin,
      'destination': destination,
    };
  }
}

