class TimelineStep {
  final String time;
  final String description;

  const TimelineStep({
    required this.time,
    required this.description,
  });

  factory TimelineStep.fromJson(Map<String, dynamic> json) {
    return TimelineStep(
      time: json['time'] as String? ?? '--:--',
      description: json['description'] as String? ?? 'Route step',
    );
  }
}