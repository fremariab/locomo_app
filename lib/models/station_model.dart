class TrotroStation {
  final String id;
  final String name;
  final String? description;
  final double latitude;
  final double longitude;
  final List<String>? routes;
  final Map<String, dynamic>? additionalInfo;

  TrotroStation({
    required this.id,
    required this.name,
    this.description,
    required this.latitude,
    required this.longitude,
    this.routes,
    this.additionalInfo,
  });

  // Factory constructor to create a Station from Firestore document
  factory TrotroStation.fromFirestore(String id, Map<String, dynamic> data) {
    // Handle different coordinate storage formats
    double latitude, longitude;
    
    if (data.containsKey('lat') && data.containsKey('lng')) {
      // Direct fields format
      latitude = data['lat'];
      longitude = data['lng'];
    } else if (data.containsKey('coordinates')) {
      // Nested coordinates object
      final coordinates = data['coordinates'];
      latitude = coordinates['lat'];
      longitude = coordinates['lng'];
    } else if (data.containsKey('location')) {
      // GeoPoint format
      final location = data['location'];
      latitude = location.latitude;
      longitude = location.longitude;
    } else {
      // Default if no coordinates found (Accra)
      latitude = 5.6037;
      longitude = -0.1870;
    }
    
    return TrotroStation(
      id: id,
      name: data['name'] ?? 'Unknown Station',
      description: data['description'],
      latitude: latitude,
      longitude: longitude,
      routes: data['routes'] != null 
          ? List<String>.from(data['routes']) 
          : null,
      additionalInfo: data['additionalInfo'],
    );
  }

  // To JSON for caching locally
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'lat': latitude,
      'lng': longitude,
      'routes': routes,
      'additionalInfo': additionalInfo,
    };
  }

  // Create from JSON (for offline data)
  factory TrotroStation.fromJson(Map<String, dynamic> json) {
    return TrotroStation(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      latitude: json['lat'] ?? json['latitude'],
      longitude: json['lng'] ?? json['longitude'],
      routes: json['routes'] != null 
          ? List<String>.from(json['routes']) 
          : null,
      additionalInfo: json['additionalInfo'],
    );
  }
}