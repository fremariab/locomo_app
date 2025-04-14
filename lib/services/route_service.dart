import 'package:http/http.dart' as http;
import 'dart:convert';
import 'map_service.dart'; // Make sure this import is available for MapService.getWalkingDirections

class RouteService {
  // Existing method remains unchanged.
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

    print("📤 Sending Route Request: ${jsonEncode(payload)}");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    print("📥 Response Status: ${response.statusCode}");
    print("📥 Response Body: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body)["results"];
    } else {
      throw Exception("Search failed: ${response.body}");
    }
  }


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
      // Use first and last stops if firstStation/lastStation not available
      final stops = List<String>.from(route['stops'] ?? []);
      if (stops.isEmpty) continue;

      final firstStation = stops.first;
      final lastStation = stops.last;

      // Add default timing estimates if not provided
      route['departure_time'] ??= 'Now';
      route['arrival_time'] ??= 'Later';
      route['time'] ??= (stops.length * 2); // 2 mins per stop estimate
      route['details'] ??= route['routeName'] ?? 'Direct route';
      route['transfers'] ??= 0;

      // Get walking directions with null checks
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
        print('Error getting walking directions: $e');
      }

      compositeRoutes.add(route);
    }

    return compositeRoutes;
  } catch (e) {
    print('Error in composite route search: $e');
    rethrow;
  }
}}
