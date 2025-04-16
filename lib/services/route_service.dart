import 'dart:convert';
import 'dart:math' show pi, sin, cos, sqrt, atan2;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:locomo_app/models/station_model.dart';
import 'package:locomo_app/models/route.dart';

class RouteService {
  static const String _googleMapsApiKey =
      'AIzaSyCPHQDG-WWZvehWnrpSlQAssPAHPUw2pmM';
  static const String _routesCollection = 'stations';
  static const String _searchRoutesEndpoint =
      'https://searchroutes-t4mpqf2cta-uc.a.run.app/searchRoutes';

  /// Fetches all trotro stations and stops from Firestore
  static Future<List<TrotroStation>> getAllStationsAndStops() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection(_routesCollection).get();

      return snapshot.docs
          .map((doc) => TrotroStation.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting stations: $e');
      throw Exception('Failed to load stations. Please try again later.');
    }
  }

  /// Gets details for a specific station by name
  static Future<TrotroStation> getStationDetails(String stationName) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('stations')
          .where('name', isEqualTo: stationName)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return TrotroStation.notFound(stationName);
      }

      return TrotroStation.fromFirestore(snapshot.docs.first);
    } catch (e) {
      debugPrint('Error getting station details: $e');
      return TrotroStation.notFound(stationName);
    }
  }

  static int estimateDuration({
    required double distanceInKm,
    required String type,
  }) {
    // Walking: 5 km/h, Trotro: 20 km/h
    final speed = type == 'walk' ? 5.0 : 20.0;
    final hours = distanceInKm / speed;
    return (hours * 3600).round(); // seconds
  }

  /// Fetch graph from Firestore (station_id → List of connected station_ids)
  static Future<Map<String, List<String>>> buildGraph() async {
    final Map<String, List<String>> graph = {};
    final snapshot =
        await FirebaseFirestore.instance.collection('stations').get();
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final id = data['id'] ?? doc.id;
      final connections = (data['connections'] ?? []) as List<dynamic>;
      graph[id] = connections.map((c) => c['stationId'] as String).toList();
    }
    debugPrint('🗺️ Full graph structure:');
    graph.forEach((station, connections) {
      debugPrint('  $station → ${connections.join(", ")}');
    });
    return graph;
  }

  /// Breadth-first search to find shortest path in graph
  static List<String>? bfsPath(
      Map<String, List<String>> graph, String start, String goal) {
    final queue = <List<String>>[];
    final visited = <String>{};
    queue.add([start]);

    while (queue.isNotEmpty) {
      final path = queue.removeAt(0);
      final node = path.last;

      if (node == goal) return path;

      if (!visited.contains(node)) {
        visited.add(node);
        for (var neighbor in graph[node] ?? []) {
          final newPath = List<String>.from(path)..add(neighbor);
          queue.add(newPath);
        }
      }
    }
    return null;
  }

  /// Estimate fare between two stations
  static Future<double> fetchFare(String fromId, String toId) async {
    final fareDoc = await FirebaseFirestore.instance
        .collection("fares")
        .doc("station_to_station")
        .get();
    final data = fareDoc.data();
    if (data == null) return 0;
    return (data["${fromId}_$toId"] ?? 0).toDouble();
  }

  /// Dart version of findRoute function (Geocode → BFS → Fare → Segments)
  static Future<List<CompositeRoute>> findRouteDartBased(
      String originText, String destinationText,{String preference = 'none'}) async {
    debugPrint(
        '🔍 Starting Dart route search from "$originText" to "$destinationText"...');

    Future<Map<String, dynamic>?> _geocode(String place) async {
      final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(place)}&key=$_googleMapsApiKey');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'].isNotEmpty) {
          debugPrint(
              '📍 Geocoded "$place" → ${data['results'][0]['geometry']['location']}');
          return data['results'][0]['geometry']['location'];
        } else {
          debugPrint('❌ Location not found. Try simplifying the name.');
          return null;
        }
      } else {
        debugPrint(
            '❌ Geocode failed for "$place" with status ${response.statusCode}');
      }
      return null;
    }

    final originGeo = await _geocode(originText);
    final destGeo = await _geocode(destinationText);
    if (originGeo == null || destGeo == null) {
      debugPrint('❌ One of the locations could not be geocoded.');
      return [];
    }

    final originNearest =
        await getNearestStopOrStation(originGeo['lat'], originGeo['lng']);
    final destNearest =
        await getNearestStopOrStation(destGeo['lat'], destGeo['lng']);

    debugPrint(
        '📍 Nearest to origin: ${originNearest?['name']} (${originNearest?['id']})');
    debugPrint(
        '📍 Nearest to destination: ${destNearest?['name']} (${destNearest?['id']})');

    if (originNearest == null || destNearest == null) {
      debugPrint('❌ Could not find nearest station or stop.');
      return [];
    }

    final graph = await buildGraph();
    debugPrint('📊 Loaded graph with ${graph.length} stations.');

    final startStation =
        originNearest['nearbyStationId'] ?? originNearest['id'];
    final endStation = destNearest['nearbyStationId'] ?? destNearest['id'];
    debugPrint('🧭 Finding path from "$startStation" to "$endStation"...');

    final allPaths = findAllPaths(graph, startStation, endStation);
    debugPrint(
        '🔁 Found ${allPaths.length} paths from "$startStation" to "$endStation"');

    final now = DateTime.now();
    List<CompositeRoute> routes = [];

    for (var stationPath in allPaths) {
      final segments = <RouteSegment>[];
      double totalFare = 0.0;

      final walkDistance = haversineDistance(
        lat1: originGeo['lat'],
        lon1: originGeo['lng'],
        lat2: originNearest['lat'],
        lon2: originNearest['lng'],
      );
      final walkDuration =
          estimateDuration(distanceInKm: walkDistance, type: 'walk');
      segments.add(RouteSegment(
        description: 'Walk to ${originNearest['name']}',
        fare: 0,
        duration: walkDuration,
        type: 'walk',
      ));

      for (int i = 0; i < stationPath.length - 1; i++) {
        final from = stationPath[i];
        final to = stationPath[i + 1];
        final fare = await fetchFare(from, to);
        totalFare += fare;

        final fromStation = await getStationDetails(from);
        final toStation = await getStationDetails(to);
        final distance = haversineDistance(
          lat1: fromStation.latitude,
          lon1: fromStation.longitude,
          lat2: toStation.latitude,
          lon2: toStation.longitude,
        );
        final duration = estimateDuration(distanceInKm: distance, type: 'bus');

        segments.add(RouteSegment(
          description: 'Ride from $from to $to',
          fare: fare,
          duration: duration,
          type: 'bus',
        ));
      }

      final totalDuration = segments.fold<int>(0, (sum, s) => sum + s.duration);
      final arrival = now.add(Duration(seconds: totalDuration));

      routes.add(CompositeRoute(
        segments: segments,
        totalFare: totalFare,
        totalDuration: totalDuration,
        departureTime: '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
        arrivalTime:
            '${arrival.hour}:${arrival.minute.toString().padLeft(2, '0')}',
        origin: originText,
        destination: destinationText,
      ));
    }
    switch (preference) {
      case 'lowest_fare':
        routes.sort((a, b) => a.totalFare.compareTo(b.totalFare));
        break;
      case 'shortest_time':
        routes.sort((a, b) => a.totalDuration.compareTo(b.totalDuration));
        break;
      case 'fewest_transfers':
        routes.sort((a, b) => a.segments.length.compareTo(b.segments.length));
        break;
      default:
        break;
    }

    return routes;
  }

  /// Returns the nearest stop or station to the given coordinates
  static Future<Map<String, dynamic>?> getNearestStopOrStation(
      double lat, double lng) async {
    double _toRadians(double degree) => degree * pi / 180;

    double haversine(double lat1, double lon1, double lat2, double lon2) {
      const R = 6371; // km
      final dLat = _toRadians(lat2 - lat1);
      final dLon = _toRadians(lon2 - lon1);
      final a = sin(dLat / 2) * sin(dLat / 2) +
          cos(_toRadians(lat1)) *
              cos(_toRadians(lat2)) *
              sin(dLon / 2) *
              sin(dLon / 2);
      final c = 2 * atan2(sqrt(a), sqrt(1 - a));
      return R * c * 1000; // meters
    }

    final db = FirebaseFirestore.instance;
    Map<String, dynamic>? nearest;
    double minDist = double.infinity;

    final stops = await db.collection("stops").get();
    for (var doc in stops.docs) {
      final data = doc.data();
      final coords = data['coordinates'];
      if (coords != null && coords['lat'] != null && coords['lng'] != null) {
        final dist = haversine(lat, lng, coords['lat'], coords['lng']);
        if (dist < minDist) {
          minDist = dist;
          nearest = {
            "type": "stop",
            "id": data['id'] ?? doc.id,
            "name": data['name'] ?? 'Unnamed Stop',
            "lat": coords['lat'],
            "lng": coords['lng'],
            "distance": dist,
            "nearbyStationId": data['nearbyStationId'],
          };
        }
      }
    }

    final stations = await db.collection("stations").get();
    for (var doc in stations.docs) {
      final data = doc.data();
      final coords = data['coordinates'];
      if (coords != null && coords['lat'] != null && coords['lng'] != null) {
        final dist = haversine(lat, lng, coords['lat'], coords['lng']);
        if (dist < minDist) {
          minDist = dist;
          nearest = {
            "type": "station",
            "id": data['id'] ?? doc.id,
            "name": data['name'] ?? 'Unnamed Station',
            "lat": coords['lat'],
            "lng": coords['lng'],
            "distance": dist,
          };
        }
      }
    }

    return nearest;
  }

  /// Returns all possible paths from `start` to `goal` in the graph
  static List<List<String>> findAllPaths(
    Map<String, List<String>> graph,
    String start,
    String goal, {
    int maxDepth = 10, // Optional: prevent infinite recursion
  }) {
    List<List<String>> allPaths = [];

    void dfs(String current, List<String> path, Set<String> visited) {
      if (path.length > maxDepth) return; // Limit path length to avoid loops
      if (current == goal) {
        allPaths.add(List<String>.from(path));
        return;
      }

      for (String neighbor in graph[current] ?? []) {
        if (!visited.contains(neighbor)) {
          visited.add(neighbor);
          path.add(neighbor);
          dfs(neighbor, path, visited);
          path.removeLast();
          visited.remove(neighbor);
        }
      }
    }

    dfs(start, [start], {start});
    return allPaths;
  }

  /// Searches for composite routes between origin and destination
  /// with optional preferences and budget constraints
  static Future<List<CompositeRoute>> searchCompositeRoutes({
    required String origin,
    required String destination,
    String preference = 'none',
    double? budget,
  }) async {
    try {
      // Validate inputs
      if (origin.isEmpty || destination.isEmpty) {
        throw ArgumentError('Origin and destination cannot be empty');
      }

      final response = await _makeRouteSearchRequest(
        origin: origin,
        destination: destination,
        preference: preference,
        budget: budget,
      );

      final data = jsonDecode(response.body);
      return _parseRouteResponse(data, origin, destination);
    } on http.ClientException catch (e) {
      debugPrint('Network error during route search: $e');
      throw Exception('Network error. Please check your connection.');
    } on FormatException catch (e) {
      debugPrint('Invalid response format: $e');
      throw Exception('Invalid route data received. Please try again.');
    } catch (e) {
      debugPrint('Composite route search error: $e');
      rethrow;
    }
  }

  /// Makes the HTTP request to the route search endpoint
  static Future<http.Response> _makeRouteSearchRequest({
    required String origin,
    required String destination,
    required String preference,
    double? budget,
  }) async {
    final url = Uri.parse(_searchRoutesEndpoint);
    final payload = {
      "origin": origin,
      "destination": destination,
      "preference": preference,
      "budget": budget,
    };

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw HttpException(
        "Route search failed with status ${response.statusCode}: ${response.body}",
        statusCode: response.statusCode,
      );
    }

    return response;
  }

  /// Parses the route search response into CompositeRoute objects
  static List<CompositeRoute> _parseRouteResponse(
    Map<String, dynamic> data,
    String origin,
    String destination,
  ) {
    final segments = <RouteSegment>[];

    // Add walk to start segment if present
    if (data['walkToStart'] != null) {
      segments.add(_createWalkSegment(
        data['walkToStart'],
        prefix: 'Walk to start',
      ));
    }

    // Add all trotro segments
    for (var seg in data['trotroSegments'] ?? []) {
      segments.add(_createTrotroSegment(seg));
    }

    // Add walk to destination segment if present
    if (data['walkToEnd'] != null) {
      segments.add(_createWalkSegment(
        data['walkToEnd'],
        prefix: 'Walk to destination',
      ));
    }

    // Calculate timing information
    final (departureTime, arrivalTime, totalDuration) =
        _calculateTiming(segments);

    return [
      CompositeRoute(
        segments: segments,
        totalFare: (data['totalFare'] as num?)?.toDouble() ?? 0.0,
        totalDuration: totalDuration,
        departureTime: departureTime,
        arrivalTime: arrivalTime,
        origin: origin,
        destination: destination,
      )
    ];
  }

  /// Creates a walk segment from response data
  static RouteSegment _createWalkSegment(
    Map<String, dynamic> data, {
    String prefix = 'Walk',
  }) {
    return RouteSegment(
      description: data['instructions'] ?? '$prefix',
      fare: 0,
      duration: _parseDuration(data['duration'] ?? '0 min'),
      type: 'walk',
    );
  }

  /// Creates a trotro segment from response data
  static RouteSegment _createTrotroSegment(Map<String, dynamic> seg) {
    return RouteSegment(
      description: 'Ride from ${seg['from']} to ${seg['to']}',
      fare: (seg['fare'] as num?)?.toDouble() ?? 0.0,
      duration: 900, // 15 min estimate
      type: 'bus',
    );
  }

  /// Calculates departure, arrival times and total duration
  static (String, String, int) _calculateTiming(List<RouteSegment> segments) {
    final departure = DateTime.now();
    final totalDuration = segments.fold<int>(0, (sum, s) => sum + s.duration);
    final arrival = departure.add(Duration(seconds: totalDuration));

    return (
      _formatTime(departure),
      _formatTime(arrival),
      totalDuration,
    );
  }

  /// Parses duration strings like "5 min" or "1 hour 30 min" into seconds
  static int _parseDuration(String text) {
    try {
      if (text.contains("hour")) {
        final parts = text.split(" ");
        final hour = int.tryParse(parts[0]) ?? 0;
        final min = int.tryParse(parts.length > 2 ? parts[2] : "0") ?? 0;
        return (hour * 60 + min) * 60;
      } else {
        final min = int.tryParse(text.split(" ")[0]) ?? 0;
        return min * 60;
      }
    } catch (e) {
      debugPrint('Error parsing duration "$text": $e');
      return 0;
    }
  }

  /// Formats DateTime into HH:MM format
  static String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  /// Calculates distance between two points using Haversine formula
  /// Returns distance in kilometers
  static double haversineDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const R = 6371.0; // Earth radius in km

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  /// Converts degrees to radians
  static double _toRadians(double degrees) => degrees * pi / 180;
}

/// Custom exception for HTTP errors
class HttpException implements Exception {
  final String message;
  final int? statusCode;

  HttpException(this.message, {this.statusCode});

  @override
  String toString() =>
      'HttpException: $message${statusCode != null ? ' (Status $statusCode)' : ''}';
}
