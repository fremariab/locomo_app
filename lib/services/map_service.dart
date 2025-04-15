import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import '../utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class MapService {
  // Get driving directions between two places using Google Maps API
  static Future<Map<String, dynamic>?> getDirections({
    required String origin,
    required String destination,
  }) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=${Uri.encodeComponent(origin)}'
      '&destination=${Uri.encodeComponent(destination)}'
      '&key=$googleMapsApiKey',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      debugPrint("Directions error: ${response.body}");
      return null;
    }
  }

  // Get distances from the user's location to multiple stations
  static Future<Map<String, dynamic>?> getDistancesFromUser({
    required String userLocation,
    required List<String> stationCoords, // Format: ["lat,lng", ...]
  }) async {
    final destinations = stationCoords.join('|');
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/distancematrix/json'
      '?origins=${Uri.encodeComponent(userLocation)}'
      '&destinations=${Uri.encodeComponent(destinations)}'
      '&mode=walking'
      '&key=$googleMapsApiKey',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      debugPrint("Distance error: ${response.body}");
      return null;
    }
  }
  static Future<String?> getUserLocation() async {
  final permission = await Permission.location.request();
  if (!permission.isGranted) return null;

  final location = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  return '${location.latitude},${location.longitude}';
}


  // Get walking directions instead of driving
  static Future<Map<String, dynamic>?> getWalkingDirections({
    required String origin,
    required String destination,
  }) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=${Uri.encodeComponent(origin)}'
      '&destination=${Uri.encodeComponent(destination)}'
      '&mode=walking'
      '&key=$googleMapsApiKey',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      debugPrint("Walking Directions error: ${response.body}");
      return null;
    }
  }
}
