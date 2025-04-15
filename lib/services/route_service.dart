import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'map_service.dart';
import '../utils/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/station_model.dart';
import '../models/composite_route.dart'; // ONLY if CompositeRoute is defined here
import '../models/route_segment.dart'; // ONLY if RouteSegment is defined here

class RouteService {
  String _findClosest(
      List<TrotroStation> stations, double userLat, double userLng) {
    double _toRadians(double deg) => deg * (pi / 180);

    double calculateDistance(
        double lat1, double lon1, double lat2, double lon2) {
      const earthRadius = 6371;
      final dLat = _toRadians(lat2 - lat1);
      final dLon = _toRadians(lon2 - lon1);
      final a = sin(dLat / 2) * sin(dLat / 2) +
          cos(_toRadians(lat1)) *
              cos(_toRadians(lat2)) *
              sin(dLon / 2) *
              sin(dLon / 2);
      final c = 2 * atan2(sqrt(a), sqrt(1 - a));
      return earthRadius * c;
    }

    stations.sort((a, b) {
      final distA =
          calculateDistance(userLat, userLng, a.latitude, a.longitude);
      final distB =
          calculateDistance(userLat, userLng, b.latitude, b.longitude);
      return distA.compareTo(distB);
    });

    return stations.first.name;
  }

  double _distanceBetween(String location1, String location2) {
    final loc1 = location1.split(',').map(double.parse).toList();
    final loc2 = location2.split(',').map(double.parse).toList();
    final lat1 = loc1[0];
    final lon1 = loc1[1];
    final lat2 = loc2[0];
    final lon2 = loc2[1];

    const earthRadius = 6371; // Radius of the Earth in kilometers
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c; // Distance in kilometers
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  static Future<List<TrotroStation>> getAllStationsAndStops() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('stations').get();
    return snapshot.docs
        .map((doc) => TrotroStation.fromFirestore(doc))
        .toList();
  }

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

    debugPrint('Searching routes with payload: $payload');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final results = jsonDecode(response.body)["results"];
      debugPrint('Found ${results.length} routes');
      return results;
    } else {
      debugPrint(
          'Search failed with status ${response.statusCode}: ${response.body}');
      throw Exception("Search failed: ${response.body}");
    }
  }

  // Combines trotro route with walking segments at the start and end
  static Future<List<CompositeRoute>> searchCompositeRoutes({
    required String origin,
    required String destination,
    String preference = 'lowest_fare',
    double? budget,
  }) async {
    debugPrint(
        'Searching for routes from $origin to $destination (preference: $preference, budget: $budget)');

    try {
      // First try to find direct routes
      var routes = await _findDirectRoutes(origin, destination);
      if (routes.isNotEmpty) {
        debugPrint('Found ${routes.length} direct routes');
        return routes;
      }

      debugPrint(
          'No direct routes found, searching for routes via stations...');

      // Get all stations from database
      final stations = await _getStationsFromLocalDatabase(origin);
      debugPrint('Retrieved ${stations.length} stations from database');

      if (stations.isEmpty) {
        debugPrint('No stations found in database');
        return [];
      }

      // Find nearest station to origin
      final nearestToOrigin = await _findNearestStation(origin, stations);
      if (nearestToOrigin == null) {
        debugPrint('No nearest station found to origin');
        return [];
      }
      debugPrint('Found nearest station to origin: ${nearestToOrigin.name}');

      // Find stations that have routes to destination area
      final potentialDestStations = stations.where((station) {
        final stops = station.stops;
        final routes = station.routes;

        // Check if any stops or routes contain the destination name
        return (stops != null &&
                stops.any((stop) =>
                    stop.toLowerCase().contains(destination.toLowerCase()))) ||
            (routes != null &&
                routes.any((route) =>
                    route.toLowerCase().contains(destination.toLowerCase())));
      }).toList();

      debugPrint(
          'Found ${potentialDestStations.length} potential destination stations');

      // Try to find routes through each potential destination station
      for (final destStation in potentialDestStations) {
        debugPrint('Trying route through station: ${destStation.name}');

        // Get route from origin to first station
        final firstLeg = await MapService.getWalkingDirections(
          origin: origin,
          destination:
              '${nearestToOrigin.latitude},${nearestToOrigin.longitude}',
        );

        if (firstLeg == null) continue;

        // Get route from last station to destination
        final lastLeg = await MapService.getWalkingDirections(
          origin: '${destStation.latitude},${destStation.longitude}',
          destination: destination,
        );

        if (lastLeg == null) continue;

        // Create composite route through these stations
        final route = await _createRouteViaStations(
          origin: origin,
          destination: destination,
          firstStation: nearestToOrigin,
          lastStation: destStation,
          firstLeg: firstLeg,
          lastLeg: lastLeg,
          preference: preference,
          maxFare: budget,
        );

        if (route != null) {
          routes.add(route);
          debugPrint(
              'Added route via stations: ${nearestToOrigin.name} -> ${destStation.name}');
        }
      }

      if (routes.isEmpty) {
        debugPrint('No routes found through any stations');
        return [];
      }

      debugPrint('Found ${routes.length} routes via stations');
      return routes;
    } catch (e) {
      debugPrint('Error searching for routes: $e');
      return [];
    }
  }

  // Helper method to process routes and add walking segments
  static Future<List<dynamic>> _processRoutes(
    List<dynamic> routes,
    String origin,
    String destination, {
    Map<String, dynamic>? nearestStation,
  }) async {
    List<dynamic> compositeRoutes = [];

    for (var route in routes) {
      try {
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

        // Add walking/driving segments to and from the route
        try {
          // Get directions from origin to first station
          final originToStation = await MapService.getWalkingDirections(
            origin: origin,
            destination: nearestStation?['name'] ?? firstStation,
          );

          // Check if the distance is more than 2km (2000 meters)
          final originDistance =
              originToStation?['distance']?['value'] as int? ?? 0;
          final isOriginFar = originDistance > 2000;

          // Get directions from last station to destination
          final stationToDestination = await MapService.getWalkingDirections(
            origin: lastStation,
            destination: destination,
          );

          // Check if the distance is more than 2km (2000 meters)
          final destinationDistance =
              stationToDestination?['distance']?['value'] as int? ?? 0;
          final isDestinationFar = destinationDistance > 2000;

          // If origin is far, get driving directions instead
          Map<String, dynamic>? originTransport;
          if (isOriginFar) {
            originTransport = await MapService.getDirections(
              origin: origin,
              destination: nearestStation?['name'] ?? firstStation,
            );
            route['originTransport'] = {
              'type': 'drive',
              'distance': originTransport?['distance'],
              'duration': originTransport?['duration'],
              'instructions':
                  'Drive to ${nearestStation?['name'] ?? firstStation}',
            };
          } else {
            route['originWalking'] = {
              'type': 'walk',
              'distance': originToStation?['distance'],
              'duration': originToStation?['duration'],
              'instructions':
                  'Walk to ${nearestStation?['name'] ?? firstStation}',
            };
          }

          // If destination is far, get driving directions instead
          Map<String, dynamic>? destinationTransport;
          if (isDestinationFar) {
            destinationTransport = await MapService.getDirections(
              origin: lastStation,
              destination: destination,
            );
            route['destinationTransport'] = {
              'type': 'drive',
              'distance': destinationTransport?['distance'],
              'duration': destinationTransport?['duration'],
              'instructions': 'Drive from ${lastStation} to $destination',
            };
          } else {
            route['destinationWalking'] = {
              'type': 'walk',
              'distance': stationToDestination?['distance'],
              'duration': stationToDestination?['duration'],
              'instructions': 'Walk from ${lastStation} to $destination',
            };
          }

          if (nearestStation != null) {
            route['nearestStation'] = nearestStation;
          }
        } catch (e) {
          debugPrint('Transport directions failed: $e');
        }

        compositeRoutes.add(route);
      } catch (e) {
        debugPrint('Error processing route: $e');
        continue;
      }
    }

    return compositeRoutes;
  }

  // Helper method to find the nearest station to a location
  static Future<TrotroStation?> _findNearestStation(
      String location, List<TrotroStation> stations) async {
    try {
      debugPrint('Finding nearest station to: $location');

      // First, get the coordinates of the location
      final geocodingUrl =
          Uri.parse('https://maps.googleapis.com/maps/api/geocode/json'
              '?address=${Uri.encodeComponent(location)}'
              '&key=$googleMapsApiKey');

      final geocodingResponse = await http.get(geocodingUrl);
      if (geocodingResponse.statusCode != 200) {
        debugPrint(
            'Geocoding failed with status ${geocodingResponse.statusCode}');
        return null;
      }

      final geocodingData = jsonDecode(geocodingResponse.body);
      if (geocodingData['results'].isEmpty) {
        debugPrint('Location not found in geocoding results');
        return null;
      }

      final locationCoords =
          geocodingData['results'][0]['geometry']['location'];
      final locationString =
          '${locationCoords['lat']},${locationCoords['lng']}';
      debugPrint('Location coordinates: $locationString');

      // Try to find stations from local database first
      debugPrint('Checking local database for stations...');
      if (stations.isNotEmpty) {
        debugPrint('Found ${stations.length} stations in database');

        // Calculate distances for each station
        for (var station in stations) {
          try {
            final stationLocation = '${station.latitude},${station.longitude}';

            // Get walking distance
            final walkingDistanceUrl = Uri.parse(
                'https://maps.googleapis.com/maps/api/distancematrix/json'
                '?origins=$locationString'
                '&destinations=$stationLocation'
                '&mode=walking'
                '&key=$googleMapsApiKey');

            final walkingResponse = await http.get(walkingDistanceUrl);
            if (walkingResponse.statusCode == 200) {
              final walkingData = jsonDecode(walkingResponse.body);
              if (walkingData['rows'].isNotEmpty &&
                  walkingData['rows'][0]['elements'].isNotEmpty) {
                final element = walkingData['rows'][0]['elements'][0];
                if (element['status'] == 'OK') {
                  // Store distance in additionalInfo
                  station.additionalInfo ??= {};
                  station.additionalInfo!['distance'] = element['distance'];
                  station.additionalInfo!['duration'] = element['duration'];
                  station.additionalInfo!['type'] = 'walking';
                }
              }
            }
          } catch (e) {
            debugPrint('Error calculating distance for station: $e');
          }
        }

        // Sort by distance and return the nearest
        stations.sort((a, b) {
          final aDistance =
              a.additionalInfo?['distance']?['value'] as int? ?? 999999;
          final bDistance =
              b.additionalInfo?['distance']?['value'] as int? ?? 999999;
          return aDistance.compareTo(bDistance);
        });

        debugPrint('Nearest station from database: ${stations.first.name}');
        return stations.first;
      }

      // If no stations found in database, try Places API
      debugPrint('No stations found in database, trying Places API...');
      final placesStations = await _getNearbyStations(locationString);
      if (placesStations.isNotEmpty) {
        debugPrint('Found ${placesStations.length} stations from Places API');
        return placesStations.first;
      }

      // If still no stations found, use hardcoded stations as last resort
      debugPrint(
          'No stations found from Places API, using hardcoded stations...');
      final hardcodedStations = _getHardcodedStations();
      if (hardcodedStations.isNotEmpty) {
        debugPrint('Using hardcoded station: ${hardcodedStations.first.name}');
        return hardcodedStations.first;
      }

      debugPrint('No stations found in any source');
      return null;
    } catch (e) {
      debugPrint('Error finding nearest station: $e');
      return null;
    }
  }

  // Get stations from local database
  static Future<List<TrotroStation>> _getStationsFromLocalDatabase(
      String location) async {
    try {
      final db = FirebaseFirestore.instance;
      final stationsRef = db.collection('stations');

      // Get all stations
      final snapshot = await stationsRef.get();

      // Convert to list of maps
      final stations =
          snapshot.docs.map((doc) => TrotroStation.fromFirestore(doc)).toList();

      return stations;
    } catch (e) {
      debugPrint('Error getting stations from database: $e');
      return [];
    }
  }

  // Get hardcoded stations as a fallback
  static List<TrotroStation> _getHardcodedStations() {
    // List of major transit stations in Accra
    return [
      TrotroStation(
          id: 'kaneshie',
          name: 'Kaneshie Station',
          latitude: 5.6037,
          longitude: -0.2270,
          additionalInfo: {
            'distance': {'text': '15 km', 'value': 15000},
          }),
      TrotroStation(
          id: 'tema',
          name: 'Tema Station',
          latitude: 5.6868,
          longitude: -0.0089,
          additionalInfo: {
            'distance': {'text': '25 km', 'value': 25000},
          }),
      TrotroStation(
          id: 'accra_central',
          name: 'Accra Central Station',
          latitude: 5.5600,
          longitude: -0.2057,
          additionalInfo: {
            'distance': {'text': '20 km', 'value': 20000},
          }),
      TrotroStation(
          id: 'madina',
          name: 'Madina Station',
          latitude: 5.6823,
          longitude: -0.1647,
          additionalInfo: {
            'distance': {'text': '10 km', 'value': 10000},
          }),
      TrotroStation(
          id: 'achimota',
          name: 'Achimota Station',
          latitude: 5.6000,
          longitude: -0.2333,
          additionalInfo: {
            'distance': {'text': '12 km', 'value': 12000},
          }),
    ];
  }

  // Helper method to get nearby stations
  static Future<List<TrotroStation>> _getNearbyStations(String location) async {
    try {
      // Use Google Places API to find transit stations with a larger radius
      final placesUrl = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
          '?location=$location'
          '&radius=50000' // Increased to 50km radius
          '&type=transit_station|bus_station' // Added bus_station type
          '&key=$googleMapsApiKey');

      final placesResponse = await http.get(placesUrl);
      if (placesResponse.statusCode != 200) {
        debugPrint(
            'Places API failed with status ${placesResponse.statusCode}');
        return [];
      }

      final placesData = jsonDecode(placesResponse.body);
      if (placesData['results'].isEmpty) {
        debugPrint('No transit stations found in Places API results');
        return [];
      }

      // Get distances for all found stations
      final stations = <TrotroStation>[];
      for (var place in placesData['results']) {
        final stationLocation =
            '${place['geometry']['location']['lat']},${place['geometry']['location']['lng']}';

        // First try walking distance
        final walkingDistanceUrl =
            Uri.parse('https://maps.googleapis.com/maps/api/distancematrix/json'
                '?origins=$location'
                '&destinations=$stationLocation'
                '&mode=walking'
                '&key=$googleMapsApiKey');

        final walkingResponse = await http.get(walkingDistanceUrl);
        if (walkingResponse.statusCode == 200) {
          final walkingData = jsonDecode(walkingResponse.body);
          if (walkingData['rows'].isNotEmpty &&
              walkingData['rows'][0]['elements'].isNotEmpty) {
            final element = walkingData['rows'][0]['elements'][0];
            if (element['status'] == 'OK') {
              stations.add(TrotroStation(
                  id: place['place_id'],
                  name: place['name'],
                  latitude: place['geometry']['location']['lat'] as double,
                  longitude: place['geometry']['location']['lng'] as double,
                  additionalInfo: {
                    'distance': element['distance'],
                    'duration': element['duration'],
                    'type': 'walking',
                  }));
              continue;
            }
          }
        }

        // If walking distance fails, try driving distance
        final drivingDistanceUrl =
            Uri.parse('https://maps.googleapis.com/maps/api/distancematrix/json'
                '?origins=$location'
                '&destinations=$stationLocation'
                '&mode=driving'
                '&key=$googleMapsApiKey');

        final drivingResponse = await http.get(drivingDistanceUrl);
        if (drivingResponse.statusCode == 200) {
          final drivingData = jsonDecode(drivingResponse.body);
          if (drivingData['rows'].isNotEmpty &&
              drivingData['rows'][0]['elements'].isNotEmpty) {
            final element = drivingData['rows'][0]['elements'][0];
            if (element['status'] == 'OK') {
              stations.add(TrotroStation(
                  id: place['place_id'],
                  name: place['name'],
                  latitude: place['geometry']['location']['lat'] as double,
                  longitude: place['geometry']['location']['lng'] as double,
                  additionalInfo: {
                    'distance': element['distance'],
                    'duration': element['duration'],
                    'type': 'driving',
                  }));
            }
          }
        }
      }

      debugPrint('Found ${stations.length} stations with distances');
      return stations;
    } catch (e) {
      debugPrint('Error getting nearby stations: $e');
      return [];
    }
  }

  static Future<CompositeRoute?> _createRouteViaStations({
    required String origin,
    required String destination,
    required TrotroStation firstStation,
    required TrotroStation lastStation,
    required Map<String, dynamic> firstLeg,
    required Map<String, dynamic> lastLeg,
    String preference = 'lowest_fare',
    double? maxFare,
  }) async {
    try {
      // Calculate estimated fare based on distance
      final firstLegDistance = firstLeg['distance']['value'] as int;
      final lastLegDistance = lastLeg['distance']['value'] as int;
      final totalDistance = firstLegDistance + lastLegDistance;

      // Estimate fare based on distance (GHS 2 per km)
      final estimatedFare = (totalDistance / 1000 * 2).ceil().toDouble();

      if (maxFare != null && estimatedFare > maxFare) {
        debugPrint(
            'Estimated fare (GHS $estimatedFare) exceeds max fare (GHS $maxFare)');
        return null;
      }

      // Create segments
      final segments = <RouteSegment>[];

      // Add first walking/driving segment
      segments.add(RouteSegment(
        description: firstLegDistance > 2000
            ? 'Drive to ${firstStation.name}'
            : 'Walk to ${firstStation.name}',
        fare: 0,
        duration: firstLeg['duration']['value'] as int,
        type: firstLegDistance > 2000 ? 'drive' : 'walk',
      ));

      // Add trotro segment between stations
      segments.add(RouteSegment(
        description:
            'Take trotro from ${firstStation.name} to ${lastStation.name}',
        fare: estimatedFare,
        duration: 3600, // 1 hour estimated
        type: 'bus',
      ));

      // Add last walking/driving segment
      segments.add(RouteSegment(
        description: lastLegDistance > 2000
            ? 'Drive from ${lastStation.name} to $destination'
            : 'Walk from ${lastStation.name} to $destination',
        fare: 0,
        duration: lastLeg['duration']['value'] as int,
        type: lastLegDistance > 2000 ? 'drive' : 'walk',
      ));

      // Create departure and arrival times
      final now = DateTime.now();
      final departureTime = now.add(Duration(minutes: 5));
      final totalDuration = (firstLeg['duration']['value'] as int) +
          (lastLeg['duration']['value'] as int) +
          3600; // Add 1 hour for trotro segment
      final arrivalTime = departureTime.add(Duration(seconds: totalDuration));

      // Create composite route
      return CompositeRoute(
        segments: segments,
        totalFare: estimatedFare,
        totalDuration: totalDuration,
        departureTime:
            '${departureTime.hour.toString().padLeft(2, '0')}:${departureTime.minute.toString().padLeft(2, '0')}',
        arrivalTime:
            '${arrivalTime.hour.toString().padLeft(2, '0')}:${arrivalTime.minute.toString().padLeft(2, '0')}',
        origin: origin,
        destination: destination,
      );
    } catch (e) {
      debugPrint('Error creating route via stations: $e');
      return null;
    }
  }

  static Future<List<CompositeRoute>> _findDirectRoutes(
      String origin, String destination) async {
    try {
      final directionsResult = await MapService.getDirections(
        origin: origin,
        destination: destination,
      );
      if (directionsResult == null) return [];

      final route = CompositeRoute(
        segments: [
          RouteSegment(
            description: 'Direct route from $origin to $destination',
            fare: 0,
            duration: directionsResult['routes'][0]['legs'][0]['duration']
                ['value'] as int,
            type: 'transit',
          )
        ],
        totalFare: 0, // Unknown for direct routes
        totalDuration: directionsResult['routes'][0]['legs'][0]['duration']
            ['value'] as int,
        departureTime:
            '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        arrivalTime:
            '${DateTime.now().add(Duration(seconds: directionsResult['routes'][0]['legs'][0]['duration']['value'] as int)).hour.toString().padLeft(2, '0')}:${DateTime.now().add(Duration(seconds: directionsResult['routes'][0]['legs'][0]['duration']['value'] as int)).minute.toString().padLeft(2, '0')}',
        origin: origin,
        destination: destination,
      );

      return [route];
    } catch (e) {
      debugPrint('Error finding direct routes: $e');
      return [];
    }
  }

  // Helper method to get directions between two points
  static Future<Map<String, dynamic>?> _getDirections({
    required String origin,
    required String destination,
  }) async {
    try {
      final url =
          Uri.parse('https://maps.googleapis.com/maps/api/directions/json'
              '?origin=${Uri.encodeComponent(origin)}'
              '&destination=${Uri.encodeComponent(destination)}'
              '&mode=driving'
              '&key=$googleMapsApiKey');

      final response = await http.get(url);
      if (response.statusCode != 200) {
        debugPrint('Directions API failed with status ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body);
      if (data['status'] != 'OK' || data['routes'].isEmpty) {
        debugPrint('No routes found in directions response');
        return null;
      }

      return data;
    } catch (e) {
      debugPrint('Error getting directions: $e');
      return null;
    }
  }
}
