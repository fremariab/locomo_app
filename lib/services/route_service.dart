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

  // New method to construct composite routes.
  static Future<List<dynamic>> searchCompositeRoutes({
    required String origin,
    required String destination,
    String preference = "none",
    double? budget,
  }) async {
    // Step 1: Get the trotro routes from the existing searchRoutes.
    final trotroRoutes = await searchRoutes(
      origin: origin,
      destination: destination,
      preference: preference,
      budget: budget,
    );

    List<dynamic> compositeRoutes = [];

    // Step 2: For each route, integrate walking segments.
    // This example assumes that each route object from the backend
    // includes keys "firstStation" and "lastStation" representing the station addresses.
    for (var route in trotroRoutes) {
      final String firstStation = route["firstStation"];
      final String lastStation = route["lastStation"];

      // Obtain walking directions:
      final originWalking = await MapService.getWalkingDirections(
        origin: origin,
        destination: firstStation,
      );
      final destinationWalking = await MapService.getWalkingDirections(
        origin: lastStation,
        destination: destination,
      );

      // Merge these walking segments into your route.
      route["originWalking"] = originWalking;
      route["destinationWalking"] = destinationWalking;

      compositeRoutes.add(route);
    }

    return compositeRoutes;
  }
}
