import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:locomo_app/models/route.dart';
import 'package:locomo_app/services/database_helper.dart';
import 'package:locomo_app/services/connectivity_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:locomo_app/widgets/MainScaffold.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';

class TripDetailsScreen extends StatefulWidget {
  final CompositeRoute route;
  final bool isFromFavorites;

  const TripDetailsScreen({
    Key? key,
    required this.route,
    this.isFromFavorites = false,
  }) : super(key: key);

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isFavorite = false;
  bool _isOnline = true;
  GoogleMapController? _mapController;
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};

  @override
  void initState() {
    debugPrint('Route has ${widget.route.segments.length} segments');
    for (var i = 0; i < widget.route.segments.length; i++) {
      final segment = widget.route.segments[i];
      debugPrint('Segment $i type: ${segment.type}');
      if (segment.polyline == null) {
        debugPrint('  - NO POLYLINE DATA');
      } else {
        debugPrint('  - Has polyline with ${segment.polyline!.length} points');
      }
    }
    super.initState();
    _checkConnectivity();
    _checkIfFavorite();
    _setupMapData();

    ConnectivityService().connectivityStream.listen((isOnline) {
      setState(() => _isOnline = isOnline);
    });
  }

  Future<void> _checkConnectivity() async {
    final isConnected = await ConnectivityService().isConnected();
    setState(() => _isOnline = isConnected);
  }

  Color _getSegmentColor(String type) {
    switch (type) {
      case 'walk':
        return Colors.green;
      case 'drive':
        return Colors.blue;
      case 'bus':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  Future<Map<String, LatLng>> fetchStationCoordinates() async {
  final Map<String, LatLng> stationCoords = {};
  try {
    final snapshot = await FirebaseFirestore.instance.collection('stations').get();
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final id = doc.id;
      final coord = data['coordinates'];
      final lat = coord?['lat'];
      final lng = coord?['lng'];

      if (lat != null && lng != null) {
        stationCoords[id] = LatLng(lat, lng);
      } else {
        debugPrint("⚠️ Missing coordinates for $id");
      }
    }
    debugPrint("✅ Fetched ${stationCoords.length} station coordinates.");
  } catch (e) {
    debugPrint("❌ Failed to fetch station coordinates: $e");
  }
  return stationCoords;
}


  Future<void> _checkIfFavorite() async {
    if (_auth.currentUser == null) return;
    final localFavorites =
        await DatabaseHelper().getFavoriteRoutes(_auth.currentUser!.uid);
    final isInLocalFavorites = localFavorites.any((route) =>
        route['origin'] == widget.route.origin &&
        route['destination'] == widget.route.destination);
    if (isInLocalFavorites) {
      setState(() => _isFavorite = true);
      return;
    }
    if (_isOnline) {
      final snapshot = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('favorite_routes')
          .where('origin', isEqualTo: widget.route.origin)
          .where('destination', isEqualTo: widget.route.destination)
          .get();
      setState(() => _isFavorite = snapshot.docs.isNotEmpty);
    }
  }

  Future<String?> _getEncodedPolyline(String origin, String destination) async {
  const apiKey = 'AIzaSyCPHQDG-WWZvehWnrpSlQAssPAHPUw2pmM'; // Replace with your actual key
  final modes = ['transit', 'driving', 'walking'];

  for (String mode in modes) {
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$apiKey&mode=$mode';

    debugPrint('🌐 Trying mode=$mode for $origin → $destination');
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final polyline = data['routes'][0]['overview_polyline']['points'];
        debugPrint("✅ Polyline found using mode=$mode");
        return polyline;
      } else {
        debugPrint("❌ No routes found using mode=$mode");
      }
    } else {
      debugPrint("❌ HTTP error (${response.statusCode}) using mode=$mode");
    }
  }

  debugPrint("🛑 All modes failed for $origin → $destination");
  return null;
}


 Future<String?> _getEncodedPolylineFromDescription(String description) async {
  final stationCoords = await fetchAllNodeCoordinates();

  // Skip anything that doesn't follow the expected format
  if (!description.contains(' to ')) {
    // Try fallback handling for things like: "Walk or Kitase Station"
    if (description.toLowerCase().startsWith("walk or ")) {
      final fallbackStation = description
          .replaceFirst(RegExp(r'walk or ', caseSensitive: false), '')
          .toLowerCase()
          .trim()
          .replaceAll(RegExp(r'[^a-z0-9_]+'), '_');

      final coord = stationCoords[fallbackStation];
      if (coord != null) {
        final origin = "5.7636,-0.2105"; // Replace with user's location or app default
        final destination = '${coord.latitude},${coord.longitude}';
        debugPrint("🩹 Fallback: Getting polyline for user → $fallbackStation");
        return _getEncodedPolyline(origin, destination);
      } else {
        debugPrint("❌ Unknown fallback station: $fallbackStation");
        return null;
      }
    }

    debugPrint("⏭️ Skipping non-standard description: $description");
    return null;
  }

  // Normal case: "Ride from X to Y"
  final parts = description.split(' to ');
  if (parts.length != 2) return null;

  final rawOrigin = parts[0]
      .toLowerCase()
      .replaceFirst(RegExp(r'^(walk|ride|drive) from ', caseSensitive: false), '')
      .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .trim();

  final rawDestination = parts[1]
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .trim();

  final originCoord = stationCoords[rawOrigin];
  final destinationCoord = stationCoords[rawDestination];

  if (originCoord == null || destinationCoord == null) {
    debugPrint("❌ Unknown station(s): $rawOrigin or $rawDestination");
    return null;
  }

  final origin = '${originCoord.latitude},${originCoord.longitude}';
  final destination = '${destinationCoord.latitude},${destinationCoord.longitude}';

  return _getEncodedPolyline(origin, destination);
}

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

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  Future<void> _setupMapData() async {
  final Set<Polyline> polylines = {};
  final Set<Marker> markers = {};
LatLng? firstKnownStart;
LatLng? lastKnownEnd;
  for (int i = 0; i < widget.route.segments.length; i++) {
    
    final seg = widget.route.segments[i];
  
    // Fetch polyline if missing
    if (seg.polyline == null || seg.polyline!.isEmpty) {
      
      final encoded = await _getEncodedPolylineFromDescription(seg.description);
      if (encoded != null) {
        seg.polyline = _decodePolyline(encoded);
        debugPrint('✅ Polyline fetched from API for segment $i');
      } else {
        debugPrint('❌ Could not fetch polyline for segment $i');
        continue; // Skip adding this segment if still empty
      }
    }

    // Only now check if polyline exists (after potential fetch)
    if (seg.polyline != null && seg.polyline!.isNotEmpty) {
      final polyline = Polyline(
        polylineId: PolylineId("segment_$i"),
        color: _getSegmentColor(seg.type),
        width: 4,
        points: seg.polyline!,
      );

      polylines.add(polyline);

      // Set start marker only on the first segment
      if (i == 0) {
        markers.add(Marker(
          markerId: const MarkerId("start"),
          position: seg.polyline!.first,
          infoWindow: const InfoWindow(title: "Start"),
        ));
      }

      // Set end marker on the last segment
      if (i == widget.route.segments.length - 1) {
        markers.add(Marker(
          markerId: const MarkerId("end"),
          position: seg.polyline!.last,
          infoWindow: const InfoWindow(title: "End"),
        ));
      }
    }
  }

  setState(() {
    _polylines.addAll(polylines);
    _markers.addAll(markers);
  });
}

  Future<void> _toggleFavorite() async {
    if (_auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to save routes'),
          backgroundColor: Color(0xFFC32E31),
        ),
      );
      return;
    }

    try {
      if (_isFavorite) {
        // Remove from favorites
        await _removeFromFavorites();
      } else {
        // Add to favorites
        await _addToFavorites();
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update favorites: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // First, check if we have actual data to display
    if (widget.route.segments.isEmpty || _polylines.isEmpty) {
      // Hardcode the bounds for Accra Mall to Ashesi University if no valid data
      _setDefaultMapView(controller);
      return;
    }

    // Set timeout to ensure map is ready
    Future.delayed(const Duration(milliseconds: 300), () {
      try {
        if (_markers.length >= 2) {
          LatLngBounds bounds = LatLngBounds(
            southwest: _markers.map((m) => m.position).reduce((a, b) => LatLng(
                a.latitude < b.latitude ? a.latitude : b.latitude,
                a.longitude < b.longitude ? a.longitude : b.longitude)),
            northeast: _markers.map((m) => m.position).reduce((a, b) => LatLng(
                a.latitude > b.latitude ? a.latitude : b.latitude,
                a.longitude > b.longitude ? a.longitude : b.longitude)),
          );
          controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
        } else {
          _setDefaultMapView(controller);
        }
      } catch (e) {
        debugPrint('Error setting map bounds: $e');
        _setDefaultMapView(controller);
      }
    });
  }

  void _setDefaultMapView(GoogleMapController controller) {
    // Hardcoded default view for Accra Mall to Ashesi University route
    // These are approximate coordinates, replace with exact values
    final accraCoordinates = const LatLng(5.6037, -0.1870); // Accra center
    controller.animateCamera(CameraUpdate.newLatLngZoom(accraCoordinates, 10));

    
  }

  // Add route to favorites
  Future<void> _addToFavorites() async {
    if (_auth.currentUser == null) return;

    try {
      // Generate a unique ID for the route
      final routeId = DateTime.now().millisecondsSinceEpoch.toString();

      // Save to local database first
      await DatabaseHelper().addFavoriteRoute(
        id: routeId,
        userId: _auth.currentUser!.uid,
        origin: widget.route.origin ?? 'Unknown',
        destination: widget.route.destination ?? 'Unknown',
        fare: widget.route.totalFare,
        synced: _isOnline ? 1 : 0,
      );

      // If online, also save to Firestore
      if (_isOnline) {
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .collection('favorite_routes')
            .doc(routeId)
            .set({
          'origin': widget.route.origin ?? 'Unknown',
          'destination': widget.route.destination ?? 'Unknown',
          'fare': widget.route.totalFare,
          'createdAt': FieldValue.serverTimestamp(),
          'userId': _auth.currentUser!.uid,
        });

        // Mark as synced in local database
        await DatabaseHelper().markFavoriteRouteAsSynced(routeId);
      }

      setState(() {
        _isFavorite = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Route saved to favorites'),
          backgroundColor: Color(0xFFC32E31),
        ),
      );
    } catch (e) {
      debugPrint('Error adding to favorites: $e');
      rethrow;
    }
  }

  // Remove route from favorites
  Future<void> _removeFromFavorites() async {
    if (_auth.currentUser == null) return;

    try {
      // Find the route ID in local database
      final localFavorites =
          await DatabaseHelper().getFavoriteRoutes(_auth.currentUser!.uid);
      final matchingRoute = localFavorites.firstWhere(
        (route) =>
            route['origin'] == widget.route.origin &&
            route['destination'] == widget.route.destination,
        orElse: () => {'id': ''},
      );

      final routeId = matchingRoute['id'] as String;

      if (routeId.isNotEmpty) {
        // Delete from local database
        await DatabaseHelper().deleteFavoriteRoute(routeId);

        // If online, also delete from Firestore
        if (_isOnline) {
          await _firestore
              .collection('users')
              .doc(_auth.currentUser!.uid)
              .collection('favorite_routes')
              .doc(routeId)
              .delete();
        }
      }

      setState(() {
        _isFavorite = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Route removed from favorites'),
          backgroundColor: Color(0xFFC32E31),
        ),
      );
    } catch (e) {
      debugPrint('Error removing from favorites: $e');
      rethrow;
    }
  }
  Future<Map<String, LatLng>> fetchAllNodeCoordinates() async {
  final coords = <String, LatLng>{};
  // stations
  final stations = await FirebaseFirestore.instance.collection('stations').get();
  for (var doc in stations.docs) {
    final data = doc.data();
    coords[data['id'] ?? doc.id] = LatLng(
      data['coordinates']['lat'], data['coordinates']['lng']
    );
  }
  // stops
  final stops = await FirebaseFirestore.instance.collection('stops').get();
  for (var doc in stops.docs) {
    final data = doc.data();
    coords[data['id'] ?? doc.id] = LatLng(
      data['coordinates']['lat'], data['coordinates']['lng']
    );
  }
  return coords;
}


  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 0,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // App Bar
            Container(
              color: const Color(0xFFC32E31),
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top, bottom: 16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left,
                        color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Trip Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Content - Scrollable
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with "Fastest" label and times
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Fastest',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  widget.route.departureTime,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const Text(
                                  ' → ',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  '${widget.route.totalDuration} → ',
                                  style: const TextStyle(
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  widget.route.arrivalTime,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${widget.route.origin} → ${widget.route.destination}',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 24),

                      // Price section
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'GHS ${widget.route.totalFare.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                            const SizedBox(height: 4),
                            
                          ],
                        ),
                      ),

                      const Divider(height: 24),

                      // Trip steps with checkboxes
                      Column(
                        children: [
                          // Departure point
                          _buildStepItem(
                            time: widget.route.departureTime,
                            location: widget.route.origin ?? 'Departure',
                            instruction: '',
                            isWalk: false,
                            isFirst: true,
                          ),

                          // All segments
                          ...widget.route.segments.map((segment) {
                            final isWalk = segment.type == 'walk';
                            final durationMin = (segment.duration / 60).ceil();
                            return _buildStepItem(
                              time: segment.departureTime ?? '',
                              location: segment.description,
                              instruction: isWalk
                                  ? 'Walk for $durationMin min'
                                  : 'Ride for $durationMin min',
                              isWalk: isWalk,
                            );
                          }).toList(),

                          // Arrival point
                          _buildStepItem(
                            time: widget.route.arrivalTime,
                            location: widget.route.destination ?? 'Destination',
                            instruction: '',
                            isWalk: false,
                            isLast: true,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Map section
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          height: 200,
                          width: double.infinity,
                          child: GoogleMap(
                            onMapCreated: _onMapCreated,
                            initialCameraPosition: CameraPosition(
                              target: const LatLng(5.6380, -0.1730),
                              zoom: 15,
                            ),
                            polylines: _polylines,
                            markers: _markers,
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                            scrollGesturesEnabled: true,
                            zoomGesturesEnabled: true,
                            tiltGesturesEnabled: true,
                            rotateGesturesEnabled: true,
                            gestureRecognizers:
                                <Factory<OneSequenceGestureRecognizer>>{
                              Factory<OneSequenceGestureRecognizer>(
                                () => EagerGestureRecognizer(),
                              ),
                            }.toSet(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// Helper widget for building each step item with checkbox
  Widget _buildStepItem({
    required String time,
    required String location,
    required String instruction,
    required bool isWalk,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time column
          SizedBox(
            width: 70,
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                time,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          // Vertical line and checkbox
          Column(
            children: [
              // Top line (only if not first item)
              if (!isFirst)
                Container(
                  width: 1,
                  height: 12,
                  color: Colors.grey[400],
                ),

              // Checkbox
              Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey[400]!,
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.check,
                  size: 16,
                  color: Colors.green,
                ),
              ),

              // Bottom line (only if not last item)
              if (!isLast)
                Container(
                  width: 1,
                  height: 12,
                  color: Colors.grey[400],
                ),
            ],
          ),

          // Location and instruction
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                if (instruction.isNotEmpty)
                  Text(
                    instruction,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TripStep extends StatelessWidget {
  final String time;
  final String location;
  final String instruction;
  final IconData icon;
  final String transportType;

  const TripStep({
    Key? key,
    required this.time,
    required this.location,
    required this.instruction,
    required this.icon,
    this.transportType = 'walk',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine icon and color based on transport type
    IconData displayIcon = icon;
    Color iconColor = Colors.black54;

    if (transportType == 'drive') {
      displayIcon = Icons.directions_car;
      iconColor = Colors.blue;
    } else if (transportType == 'walk') {
      displayIcon = Icons.directions_walk;
      iconColor = Colors.green;
    } else if (transportType == 'bus') {
      displayIcon = Icons.directions_bus;
      iconColor = Colors.orange;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time column
        SizedBox(
          width: 60,
          child: Text(
            time,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),

        // Icon column
        Container(
          margin: const EdgeInsets.only(right: 12),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                displayIcon,
                size: 16,
                color: iconColor,
              ),
            ),
          ),
        ),

        // Location and instruction column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                location,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              if (instruction.isNotEmpty)
                Text(
                  instruction,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
