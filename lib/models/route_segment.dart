class RouteSegment {
  final String description;
  final double fare;
  final int duration;
  final String type;

  RouteSegment({
    required this.description,
    required this.fare,
    required this.duration,
    required this.type,
  });

  factory RouteSegment.fromJson(Map<String, dynamic> json) {
    return RouteSegment(
      description: json['description'] ?? '',
      fare: (json['fare'] ?? 0).toDouble(),
      duration: json['duration'] ?? 0,
      type: json['type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'fare': fare,
      'duration': duration,
      'type': type,
    };
  }
}
