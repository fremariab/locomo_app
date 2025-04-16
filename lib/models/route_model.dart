import 'transfer.dart';
import 'timeline_step.dart';

class RouteModel {
  final String origin;
  final String destination;
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final double price;
  final String? walkingInfo;
  final List<Transfer> transfers;
  final List<TimelineStep> timeline;

  const RouteModel({
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.price,
    this.walkingInfo,
    required this.transfers,
    required this.timeline,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      origin: json['origin'] as String? ?? 'Unknown origin',
      destination: json['destination'] as String? ?? 'Unknown destination',
      departureTime: json['departure_time'] as String? ?? 'Now',
      arrivalTime: json['arrival_time'] as String? ?? 'Later',
      duration: json['time']?.toString() ?? 'Unknown duration',
      price: (json['fare'] as num?)?.toDouble() ?? 0.0,
      walkingInfo: json['walking_info'] as String?,
      transfers: (json['transfers'] as List<dynamic>?)
              ?.map((t) => Transfer.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
      timeline: (json['timeline'] as List<dynamic>?)
              ?.map((t) => TimelineStep.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  // Helper method to convert stops to timeline
  static List<TimelineStep> convertStopsToTimeline(List<dynamic> stops) {
    return stops.asMap().entries.map((entry) {
      return TimelineStep(
        time: '${entry.key + 1}',
        description: entry.value.toString(),
      );
    }).toList();
  }
}