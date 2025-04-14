import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' show sin, cos, sqrt, atan2, pi, asin;

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection names
  static const String stationsCollection = 'stations';
  static const String routesCollection = 'routes';

  // Cache keys
  static const String stationsCacheKey = 'cached_stations';
  static const String routesCacheKey = 'cached_routes';
  static const String lastUpdateTimeKey = 'last_update_time';

  // Cache expiration time (24 hours)
  static const Duration cacheExpiration = Duration(hours: 24);

  // Get all stations from Firestore
  Future<List<Map<String, dynamic>>> getStations() async {
    try {
      // Check if we should use cached data
      if (await _shouldUseCache()) {
        final cachedData = await _getCachedStations();
        if (cachedData != null && cachedData.isNotEmpty) {
          return cachedData;
        }
      }

      // Fetch from Firestore
      final stationsSnapshot =
          await _firestore.collection(stationsCollection).get();

      final List<Map<String, dynamic>> stations = [];

      for (var doc in stationsSnapshot.docs) {
        stations.add({
          'id': doc.id,
          ...doc.data(),
        });
      }

      // Cache the data
      await _cacheStations(stations);

      return stations;
    } catch (e) {
      // If error, try to get from cache as fallback
      final cachedData = await _getCachedStations();
      if (cachedData != null && cachedData.isNotEmpty) {
        return cachedData;
      }

      // If no cache, rethrow the error
      rethrow;
    }
  }

  // Get stations near a location
  Future<List<Map<String, dynamic>>> getNearbyStations(
      double latitude, double longitude, double radiusKm) async {
    print('=== STARTING NEARBY STATIONS QUERY ===');
    print('📍 Search Center: $latitude, $longitude');
    print('🔍 Radius: $radiusKm km');

    try {
      print('\n🔄 Fetching all stations...');
      List<Map<String, dynamic>> allStations = await getStations();
      print('✅ Found ${allStations.length} total stations');

      if (allStations.isEmpty) {
        print('⚠️ No stations found in database!');
        return [];
      }

      print('\n🔎 Filtering stations by distance...');
      final nearbyStations = allStations.where((station) {
        print('\n-----------------------');
        print('🔍 Checking station: ${station['name'] ?? 'Unnamed Station'}');
        print('📄 Full data: $station');

        try {
          double stationLat, stationLng;
          String coordinateSource = '';

          // Debug coordinate extraction
          if (station.containsKey('lat') && station.containsKey('lng')) {
            stationLat = station['lat'];
            stationLng = station['lng'];
            coordinateSource = 'Direct lat/lng fields';
          } else if (station.containsKey('coordinates')) {
            print('ℹ️ Found coordinates object: ${station['coordinates']}');
            stationLat = station['coordinates']['lat'];
            stationLng = station['coordinates']['lng'];
            coordinateSource = 'Coordinates object';
          } else if (station.containsKey('location') &&
              station['location'] is GeoPoint) {
            final GeoPoint location = station['location'];
            stationLat = location.latitude;
            stationLng = location.longitude;
            coordinateSource = 'GeoPoint';
          } else {
            print('❌ No valid location data found in station');
            return false;
          }

          print(
              '📌 Extracted coordinates ($coordinateSource): $stationLat, $stationLng');

          final distance =
              _calculateDistance(latitude, longitude, stationLat, stationLng);
          print('📏 Distance: ${distance.toStringAsFixed(6)} km');

          station['distance'] = distance;

          if (distance <= radiusKm) {
            print('✅ WITHIN RADIUS');
            return true;
          } else {
            print('❌ Outside search radius');
            return false;
          }
        } catch (e) {
          print('‼️ Error processing station: $e');
          return false;
        }
      }).toList()
        ..sort((a, b) =>
            (a['distance'] as double).compareTo(b['distance'] as double));

      print(
          '\n🎯 FINAL RESULT: Found ${nearbyStations.length} nearby stations');
      return nearbyStations;
    } catch (e) {
      print('‼️ CRITICAL ERROR in getNearbyStations: $e');
      rethrow;
    }
  }

  // Get routes that pass through a station
  Future<List<Map<String, dynamic>>> getRoutesForStation(
      String stationId) async {
    try {
      final routesSnapshot = await _firestore
          .collection(routesCollection)
          .where('stations', arrayContains: stationId)
          .get();

      final List<Map<String, dynamic>> routes = [];

      for (var doc in routesSnapshot.docs) {
        routes.add({
          'id': doc.id,
          ...doc.data(),
        });
      }

      return routes;
    } catch (e) {
      rethrow;
    }
  }

  // Cache stations data locally
  Future<void> _cacheStations(List<Map<String, dynamic>> stations) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert GeoPoint to simple lat/lng for JSON serialization
      final serializableStations = stations.map((station) {
        // Handle different data structure formats
        if (station['location'] is GeoPoint) {
          final GeoPoint geoPoint = station['location'];
          station['location'] = {
            'latitude': geoPoint.latitude,
            'longitude': geoPoint.longitude,
          };
        }
        return station;
      }).toList();

      // Store as JSON string
      await prefs.setString(stationsCacheKey, jsonEncode(serializableStations));

      // Update cache timestamp
      await prefs.setInt(
          lastUpdateTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // Fail silently, as this is just caching
      debugPrint('Error caching stations: $e');
    }
  }

  // Get cached stations data
  Future<List<Map<String, dynamic>>?> _getCachedStations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stationsJson = prefs.getString(stationsCacheKey);

      if (stationsJson == null) return null;

      final List<dynamic> decoded = jsonDecode(stationsJson);

      // Convert back to appropriate format
      return decoded.map((station) {
        // Handle different possible formats in the cache
        if (station['location'] is Map) {
          final locationMap = station['location'];
          // In the app, we'll parse this based on how we're using it
          station['location'] =
              GeoPoint(locationMap['latitude'], locationMap['longitude']);
        }
        return station as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      debugPrint('Error getting cached stations: $e');
      return null;
    }
  }

  // Check if we should use cache based on expiration time
  Future<bool> _shouldUseCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdateTime = prefs.getInt(lastUpdateTimeKey);

      if (lastUpdateTime == null) return false;

      final lastUpdate = DateTime.fromMillisecondsSinceEpoch(lastUpdateTime);
      final now = DateTime.now();

      return now.difference(lastUpdate) < cacheExpiration;
    } catch (e) {
      return false;
    }
  }

  // Delete all cached data (for logout or reset)
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(stationsCacheKey);
      await prefs.remove(routesCacheKey);
      await prefs.remove(lastUpdateTimeKey);
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  // Calculate distance between two points using Haversine formula
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // Earth radius in kilometers

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(lat1)) *
            _cos(_toRadians(lat2)) *
            _sin(dLon / 2) *
            _sin(dLon / 2);

    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    final distance = R * c;

    return distance;
  }

  // Helper math functions
  double _toRadians(double degrees) => degrees * 3.14159265359 / 180;
  double _sin(double x) => sin(x);
  double _cos(double x) => cos(x);
  double _sqrt(double x) => sqrt(x);
  double _atan2(double y, double x) => atan2(y, x);
}
