import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteSegment {
  final String description;
  final double fare;
  final int duration;
  final String type;
  final String? departureTime;

  // 🆕 Add this field
  final List<LatLng>? polyline;

  RouteSegment({
    required this.description,
    required this.fare,
    required this.duration,
    required this.type,
    this.departureTime,
    this.polyline, // 🆕 Add to constructor
  });

  // If you're using fromJson / toJson, update them too
  factory RouteSegment.fromJson(Map<String, dynamic> json) {
    return RouteSegment(
      description: json['description'],
      fare: (json['fare'] as num).toDouble(),
      duration: json['duration'],
      type: json['type'],
      departureTime: json['departureTime'],
      polyline: json['polyline'] != null
          ? (json['polyline'] as List)
              .map((e) => LatLng(e['lat'], e['lng']))
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
