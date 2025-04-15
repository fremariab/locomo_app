import 'route_segment.dart';

class CompositeRoute {
  final List<RouteSegment> segments;
  final double totalFare;
  final int totalDuration;
  final String departureTime;
  final String arrivalTime;
  final String origin;
  final String destination;

  CompositeRoute({
    required this.segments,
    required this.totalFare,
    required this.totalDuration,
    required this.departureTime,
    required this.arrivalTime,
    required this.origin,
    required this.destination,
  });

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

  

Map<String, dynamic> toJson() {
  return {
    'segments': segments.map((s) => s.toJson()).toList(),
    'totalFare': totalFare,
    'totalDuration': totalDuration,
    'departureTime': departureTime,
    'arrivalTime': arrivalTime,
    'origin': origin,
    'destination': destination,
  };
}

}
