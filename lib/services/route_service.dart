import 'dart:convert';
import 'dart:math' show pi, sin, cos, sqrt, atan2;
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:locomo_app/models/station_model.dart';
import 'package:locomo_app/models/route.dart';

class RouteService {
  static const String _googleMapsApiKey =
      'AIzaSyCPHQDG-WWZvehWnrpSlQAssPAHPUw2pmM';
  static const String _routesCollection = 'stations';

  
  static Future<List<TrotroStation>> getAllStationsAndStops() async {
  final firestore = FirebaseFirestore.instance;
  final allNodes = <TrotroStation>[];

  // ─── Stations ─────────────────────────────────────────────────────────────
  final stationSnap = await firestore.collection('stations').get();
  for (var doc in stationSnap.docs) {
    final data = doc.data();
    // Normalize the nested coordinates map
    final rawCoords = data['coordinates'];
    double lat = 0.0, lng = 0.0;
    if (rawCoords is Map) {
      final coords = Map<String, dynamic>.from(rawCoords);
      lat = (coords['lat'] as num?)?.toDouble() ?? 0.0;
      lng = (coords['lng'] as num?)?.toDouble() ?? 0.0;
    }

    final name = (data['name'] as String?)?.trim();
    if (name == null || name.isEmpty) continue;

    allNodes.add(TrotroStation(
      id:        doc.id,
      name:      name,
      latitude:  lat,
      longitude: lng,
      isStation: true,
      // you can populate other fields if you like
    ));
  }

  // ─── Stops ────────────────────────────────────────────────────────────────
  final stopSnap = await firestore.collection('stops').get();
  for (var doc in stopSnap.docs) {
    final data = doc.data();
    final rawCoords = data['coordinates'];
    double lat = 0.0, lng = 0.0;
    if (rawCoords is Map) {
      final coords = Map<String, dynamic>.from(rawCoords);
      lat = (coords['lat'] as num?)?.toDouble() ?? 0.0;
      lng = (coords['lng'] as num?)?.toDouble() ?? 0.0;
    }

    final name = (data['name'] as String?)?.trim();
    if (name == null || name.isEmpty) continue;

    allNodes.add(TrotroStation(
      id:        doc.id,
      name:      name,
      latitude:  lat,
      longitude: lng,
      isStation: false,
    ));
  }

  return allNodes;
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
  /// Fetch graph from Firestore (including both stations and stops)
  static Future<Map<String, List<String>>> buildGraph() async {
    final db = FirebaseFirestore.instance;
    final graph = <String, List<String>>{};

    // Helper to add bidirectional edge
    void link(String a, String b) {
      graph.putIfAbsent(a, () => []);
      graph.putIfAbsent(b, () => []);
      if (!graph[a]!.contains(b)) graph[a]!.add(b);
      if (!graph[b]!.contains(a)) graph[b]!.add(a);
    }

    // ─── Stops ────────────────────────────────────────────────────────────────
    final stopSnap = await db.collection('stops').get();
    for (var doc in stopSnap.docs) {
      final stopId = doc.id;
      graph.putIfAbsent(stopId, () => []);

      final data = doc.data();
      // 1) link stop ↔ nearest station
      final nearby = data['nearbyStationId'] as String?;
      if (nearby != null) link(stopId, nearby);

      // 2) link stop ↔ other stops
      final rawConns = data['connections'] as List<dynamic>? ?? [];
      for (var c in rawConns.cast<Map<String, dynamic>>()) {
        final otherStop = c['stopId'] as String?;
        if (otherStop != null) link(stopId, otherStop);
      }
    }

    // ─── Stations ─────────────────────────────────────────────────────────────
    final stationSnap = await db.collection('stations').get();
    for (var doc in stationSnap.docs) {
      final stationId = doc.id;
      graph.putIfAbsent(stationId, () => []);

      final data = doc.data();
      final rawConns = data['connections'] as List<dynamic>? ?? [];

      for (var c in rawConns.cast<Map<String, dynamic>>()) {
        // station ↔ station
        if (c['stationId'] != null) {
          link(stationId, c['stationId'] as String);
        }
        // station ↔ stop
        if (c['stopId'] != null) {
          link(stationId, c['stopId'] as String);
        }
      }
    }

    debugPrint('🗺️ Graph:');
    graph.forEach((k, vs) => debugPrint('  $k → ${vs.join(", ")}'));
    return graph;
  }

  /// Fetch either a station _or_ a stop by its ID
  static Future<TrotroStation> getNodeById(String id) async {
  // 1️⃣ Try station first
  final stationDoc = await FirebaseFirestore.instance
      .collection('stations')
      .doc(id)
      .get();
  if (stationDoc.exists) {
    return TrotroStation.fromFirestore(stationDoc);
  }

  // 2️⃣ Fallback to stop
  final stopDoc = await FirebaseFirestore.instance
      .collection('stops')
      .doc(id)
      .get();
  if (stopDoc.exists) {
    final data = stopDoc.data()!;

    // Safely extract nested coordinates map
    double lat = 0.0, lng = 0.0;
    final raw = data['coordinates'];
    if (raw is Map) {
      final coords = Map<String, dynamic>.from(raw);
      lat = (coords['lat'] as num?)?.toDouble() ?? 0.0;
      lng = (coords['lng'] as num?)?.toDouble() ?? 0.0;
    }

    return TrotroStation(
      id:        stopDoc.id,
      name:      data['name']      ?? 'Stop',
      latitude:  lat,
      longitude: lng,
      isStation: false,
    );
  }

  // 3️⃣ If neither exists, return a not‐found placeholder
  return TrotroStation.notFound(id);
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

  /// Fetch station by its Firestore doc ID
  static Future<TrotroStation> getStationById(String stationId) async {
    final doc = await FirebaseFirestore.instance
        .collection('stations')
        .doc(stationId)
        .get();
    if (!doc.exists) {
      return TrotroStation.notFound(stationId);
    }
    return TrotroStation.fromFirestore(doc);
  }

  static Future<int> _busLegDurationSeconds(LatLng from, LatLng to) async {
    // Try transit first, then driving
    for (final mode in ['transit', 'driving']) {
      final url =
          Uri.parse('https://maps.googleapis.com/maps/api/directions/json'
              '?origin=${from.latitude},${from.longitude}'
              '&destination=${to.latitude},${to.longitude}'
              '&mode=$mode'
              '&key=$_googleMapsApiKey');
      final resp = await http.get(url);
      final data = jsonDecode(resp.body);
      debugPrint('[$mode] status=${data['status']} for $from → $to');
      if (data['routes']?.isNotEmpty == true) {
        final secs = data['routes'][0]['legs'][0]['duration']['value'] as int;
        debugPrint('→ Got $secs s via $mode for $from → $to');
        return secs;
      }
    }

    // Fallback to distance estimate
    final distKm = haversineDistance(
      lat1: from.latitude,
      lon1: from.longitude,
      lat2: to.latitude,
      lon2: to.longitude,
    );
    final fallback = estimateDuration(distanceInKm: distKm, type: 'bus');
    debugPrint('Fallback estimate $fallback s for $from → $to');
    return fallback;
  }

  /// Dart version of findRoute function (Geocode → BFS → Fare → Segments)
  static Future<List<CompositeRoute>> findRouteDartBased(
      String originText, String destinationText,
      {String preference = 'none'}) async {
    debugPrint(
        '🔍 Starting Dart route search from "$originText" to "$destinationText"...');

    Future<Map<String, dynamic>?> _geocode(String place) async {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(place)}&key=$_googleMapsApiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['results'].isNotEmpty) {
          final result = data['results'][0];

          // ✅ Check if the result is in Ghana
          final components = result['address_components'] as List<dynamic>;
          final isGhana = components.any((component) {
            final types = component['types'] as List<dynamic>;
            return types.contains('country') && component['short_name'] == 'GH';
          });

          if (!isGhana) {
            debugPrint('❌ "$place" is outside Ghana. Skipping.');
            return null;
          }

          final location = result['geometry']['location'];
          debugPrint('📍 Geocoded "$place" → $location');
          return location;
        } else {
          debugPrint('❌ Location not found. Try simplifying the name.');
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

    final startStation = originNearest['id'];
    final endStation = destNearest['id'];

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
      // final walkDuration =
      //     estimateDuration(distanceInKm: walkDistance, type: 'walk');
      final fromCoord = LatLng(originGeo['lat'], originGeo['lng']);
      final toCoord = LatLng(originNearest['lat'], originNearest['lng']);
      final walkDuration = await _busLegDurationSeconds(fromCoord, toCoord);

      segments.add(RouteSegment(
        description: 'Walk to ${originNearest['name']}',
        fare: 0,
        duration: walkDuration,
        type: 'walk',
      ));

      // route_service.dart → findRouteDartBased(...)
      for (int i = 0; i < stationPath.length - 1; i++) {
        final from = stationPath[i];
        final to = stationPath[i + 1];
        // 1) Try to read fare from the “from” node’s connections:
        final fromNode = await getNodeById(from);
        double fare;
        final match =
            fromNode.connections?.cast<Map<String, dynamic>>().firstWhere(
                  (c) => (c['stationId'] == to) || (c['stopId'] == to),
                  orElse: () => {},
                );
        if (match != null && match.containsKey('fare')) {
          fare = (match['fare'] as num).toDouble();
        } else {
          // 2) Fallback to your external fare document
          fare = await fetchFare(from, to);
        }
        totalFare += fare;
        final fromStation = await getNodeById(from);
        final toStation = await getNodeById(to);
        final distance = haversineDistance(
          lat1: fromStation.latitude,
          lon1: fromStation.longitude,
          lat2: toStation.latitude,
          lon2: toStation.longitude,
        );

        // **This is where you currently estimate duration, hence the 0 s result**
        // final duration = estimateDuration(distanceInKm: distance, type: 'bus');
        final fromCoord = LatLng(fromStation.latitude, fromStation.longitude);
        final toCoord = LatLng(toStation.latitude, toStation.longitude);
        final duration = await _busLegDurationSeconds(fromCoord, toCoord);
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
        totalDuration: (totalDuration / 60).round(),
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
    int maxPaths = 3,   
  }) {
    List<List<String>> allPaths = [];

    void dfs(String current, List<String> path, Set<String> visited) {
       if (allPaths.length >= maxPaths) return;  
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
          if (allPaths.length >= maxPaths) return;
        }
      }
    }

    dfs(start, [start], {start});
    return allPaths;
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
