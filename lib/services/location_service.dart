import 'package:flutter/foundation.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart' as perm;

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_google_maps_webservices/directions.dart' as gmaps;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:math' show sin, cos, sqrt, atan2, pi, asin;

class LocationService {
final loc.Location _location = loc.Location();
  // final gmaps.DirectionsApi _directionsApi = gmaps.DirectionsApi(
final gmaps.GoogleMapsDirections _directionsApi = gmaps.GoogleMapsDirections(
  apiKey: dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '',
);




  // Singleton instance
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Get the instance
  static LocationService get instance => _instance;

  // Stream of location updates
Stream<loc.LocationData>? _locationUpdates;
  Stream<loc.LocationData> get locationUpdates {
    _locationUpdates ??= _location.onLocationChanged;
    return _locationUpdates!;
  }

  // Initialize location service
  Future<bool> initialize() async {
    bool _serviceEnabled;
    perm.PermissionStatus _permissionGranted;

    // Check if location service is enabled
    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled) {
        return false;
      }
    }

    // Check if permission is granted
// Check if permission is granted
final loc.PermissionStatus locationPermission = await _location.hasPermission();
if (locationPermission == loc.PermissionStatus.denied) {
  final loc.PermissionStatus requestedPermission = await _location.requestPermission();
  if (requestedPermission != loc.PermissionStatus.granted) {
    return false;
  }
}

    // Configure location settings
    await _location.changeSettings(
accuracy: loc.LocationAccuracy.high,
      interval: 10000, // 10 seconds
      distanceFilter: 10, // 10 meters
    );

    return true;
  }

  // Get the current location once
Future<loc.LocationData?> getCurrentLocation() async {
    try {
      final isInitialized = await initialize();
      
      if (!isInitialized) {
        return null;
      }
      
      return await _location.getLocation();
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  // Check if location permission is granted
  Future<bool> hasLocationPermission() async {
var status = await perm.Permission.location.status;
    return status.isGranted;
  }

  // Request location permission
  Future<bool> requestLocationPermission() async {
var status = await perm.Permission.location.request();
    return status.isGranted;
  }

  // Open app settings page
  Future<bool> openAppSettings() async {
    return await openAppSettings();
  }

  // Calculate distance between two points in kilometers
  double calculateDistance(LatLng point1, LatLng point2) {
    const int earthRadius = 6371; // in kilometers
    
    // Convert to radians
    final double lat1 = _degreesToRadians(point1.latitude);
    final double lon1 = _degreesToRadians(point1.longitude);
    final double lat2 = _degreesToRadians(point2.latitude);
    final double lon2 = _degreesToRadians(point2.longitude);
    
    // Haversine formula
    final double dLat = lat2 - lat1;
    final double dLon = lon2 - lon1;
    
    final double a = 
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * 
        sin(dLon / 2) * sin(dLon / 2);
        
    final double c = 2 * asin(sqrt(a));
    
    // Calculate the distance in kilometers
    return earthRadius * c;
  }

  // Convert degrees to radians
  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180.0);
  }

  // Get directions between two points
  Future<DirectionsResult?> getDirections(LatLng origin, LatLng destination) async {
    try {
      final response = await _directionsApi.directionsWithLocation(
        gmaps.Location(lat: origin.latitude, lng: origin.longitude),
        gmaps.Location(lat: destination.latitude, lng: destination.longitude),
        travelMode: gmaps.TravelMode.transit, // Using transit for public transportation
      );
      
      if (response.isOkay && response.routes.isNotEmpty) {
        return DirectionsResult(
          points: _decodePolyline(response.routes[0].overviewPolyline.points),
          distance: response.routes[0].legs[0].distance.text,
          duration: response.routes[0].legs[0].duration.text,
          steps: _parseSteps(response.routes[0].legs[0].steps),
        );
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting directions: $e');
      return null;
    }
  }

  // Parse steps from Google Directions API response
  List<DirectionStep> _parseSteps(List<gmaps.Step> steps) {
    return steps.map((step) {
      return DirectionStep(
        instruction: step.htmlInstructions,
        distance: step.distance.text,
        duration: step.duration.text,
        travelMode: step.travelMode.name,
        polyline: _decodePolyline(step.polyline.points),
      );
    }).toList();
  }

  // Decode encoded polyline
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;
      
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      
      double latitude = lat / 1E5;
      double longitude = lng / 1E5;
      points.add(LatLng(latitude, longitude));
    }
    return points;
  }
}

// Model classes for directions
class DirectionsResult {
  final List<LatLng> points;
  final String distance;
  final String duration;
  final List<DirectionStep> steps;

  DirectionsResult({
    required this.points,
    required this.distance,
    required this.duration,
    required this.steps,
  });
}

class DirectionStep {
  final String instruction;
  final String distance;
  final String duration;
  final String travelMode;
  final List<LatLng> polyline;

  DirectionStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.travelMode,
    required this.polyline,
  });
}