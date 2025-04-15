export 'route.dart';

class RouteSegment {
  final String description;
  final double fare;
  final int duration; // in minutes
  final String type; // 'bus', 'walk', etc.
  final String? departureTime;

  RouteSegment({
    required this.description,
    required this.fare,
    required this.duration,
    required this.type,
    this.departureTime,
  });
  // Factory method to create a RouteSegment from a JSON map
  factory RouteSegment.fromJson(Map<String, dynamic> json) {
    return RouteSegment(
      description: json['description']?.toString() ?? '',
      fare: (json['fare'] ?? 0).toDouble(),
      duration: json['duration']?.toInt() ?? 0,
      type: json['type']?.toString() ?? 'unknown',
      departureTime: json['departureTime']?.toString(),
    );
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
      final routeSegment = RouteSegment(
        description: segmentMap['description']?.toString() ?? '',
        fare: (segmentMap['fare'] ?? 0).toDouble(),
        duration: segmentMap['duration']?.toInt() ?? 0,
        type: segmentMap['type']?.toString() ?? 'unknown',
        departureTime: segmentMap['departureTime']?.toString(),
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
  factory CompositeRoute.fromJson(Map<String, dynamic> json) {
    return CompositeRoute(
      segments: (json['segments'] as List<dynamic>)
          .map((e) => RouteSegment.fromJson(e))
          .toList(),
      totalFare: (json['totalFare'] ?? 0).toDouble(),
      totalDuration: json['totalDuration'] ?? 0,
      departureTime: json['departureTime'] ?? '',
      arrivalTime: json['arrivalTime'] ?? '',
      origin: json['origin'] ?? '',
      destination: json['destination'] ?? '',
    );
  }
  // Convert the route to a map for storage
  Map<String, dynamic> toMap() {
    return {
      'segments': segments
          .map((segment) => {
                'description': segment.description,
                'fare': segment.fare,
                'duration': segment.duration,
                'type': segment.type,
                'departureTime': segment.departureTime,
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
