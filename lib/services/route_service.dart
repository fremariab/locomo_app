import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'map_service.dart';

class RouteService {
  // Calls backend to find matching trotro routes between origin and destination
  static Future<List<dynamic>> searchRoutes({
    required String origin,
    required String destination,
    String preference = "none",
    double? budget,
  }) async {
    final url = Uri.parse("https://searchroutes-t4mpqf2cta-uc.a.run.app");

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

    if (response.statusCode == 200) {
      return jsonDecode(response.body)["results"];
    } else {
      throw Exception("Search failed: ${response.body}");
    }
  }

  // Combines trotro route with walking segments at the start and end
  static Future<List<dynamic>> searchCompositeRoutes({
    required String origin,
    required String destination,
    String preference = "none",
    double? budget,
  }) async {
    try {
      final trotroRoutes = await searchRoutes(
        origin: origin,
        destination: destination,
        preference: preference,
        budget: budget,
      );

      List<dynamic> compositeRoutes = [];

      for (var route in trotroRoutes) {
        final stops = List<String>.from(route['stops'] ?? []);
        if (stops.isEmpty) continue;

        final firstStation = stops.first;
        final lastStation = stops.last;

        // Use fallback/default values if some fields are missing
        route['departure_time'] ??= 'Now';
        route['arrival_time'] ??= 'Later';
        route['time'] ??= stops.length * 2; // Assume 2 minutes per stop
        route['details'] ??= route['routeName'] ?? 'Direct route';
        route['transfers'] ??= 0;

        // Add walking segments to and from the route
        try {
          final originWalking = await MapService.getWalkingDirections(
            origin: origin,
            destination: firstStation,
          );

          final destinationWalking = await MapService.getWalkingDirections(
            origin: lastStation,
            destination: destination,
          );

          route['originWalking'] = originWalking;
          route['destinationWalking'] = destinationWalking;
        } catch (e) {
          debugPrint('Walking directions failed: $e');
        }

        compositeRoutes.add(route);
      }

      return compositeRoutes;
    } catch (e) {
      debugPrint('Composite route search failed: $e');
      rethrow;
    }
  }
}
