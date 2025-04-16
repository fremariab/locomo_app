class Transfer {
  final String description;
  final int duration;

  const Transfer({
    required this.description,
    required this.duration,
  });

  factory Transfer.fromJson(Map<String, dynamic> json) {
    return Transfer(
      description: json['description'] as String? ?? 'Transfer point',
      duration: json['duration_minutes'] as int? ?? 0,
    );
  }
}