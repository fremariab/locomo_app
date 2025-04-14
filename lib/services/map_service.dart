import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class MapService {
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
      print("Directions error: ${response.body}");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getDistancesFromUser({
    required String userLocation,
    required List<String> stationCoords, // List of "lat,lng"
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
      print("Distance error: ${response.body}");
      return null;
    }
  }

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
      print("Walking Directions error: ${response.body}");
      return null;
    }
  }
}
