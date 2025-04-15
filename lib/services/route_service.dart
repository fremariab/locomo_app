import 'dart:convert';
import 'dart:math' show pi, sin, cos, sqrt, atan2;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:locomo_app/models/station_model.dart';
import 'package:locomo_app/models/route.dart';

class RouteService {
  static const String _googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
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
:wq
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
