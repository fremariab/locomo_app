import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:locomo_app/models/route.dart';
import 'package:locomo_app/services/database_helper.dart';
import 'package:locomo_app/services/connectivity_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:locomo_app/widgets/MainScaffold.dart';

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

  Future<void> _setupMapData() async {
    final Set<Polyline> polylines = {};
    final Set<Marker> markers = {};

    // Add debug check for overall route data
    debugPrint(
        "Setting up map with route data: ${widget.route.origin} to ${widget.route.destination}");
    debugPrint("Total segments: ${widget.route.segments.length}");

    // Fallback coordinates if we don't find valid polylines
    LatLng? firstValidPoint;
    LatLng? lastValidPoint;

    // Process each segment to create polylines
    for (var i = 0; i < widget.route.segments.length; i++) {
      final seg = widget.route.segments[i];
      debugPrint("Processing segment $i: ${seg.type}, ${seg.description}");

      if (seg.polyline != null && seg.polyline!.isNotEmpty) {
        // Store first valid point we find for fallback
        firstValidPoint ??= seg.polyline!.first;
        lastValidPoint = seg.polyline!.last;

        polylines.add(Polyline(
          polylineId: PolylineId("segment_$i"),
          color: _getSegmentColor(seg.type),
          width: 4,
          points: seg.polyline!,
        ));

        debugPrint(
            '✅ Added polyline for segment $i with ${seg.polyline!.length} points');
      } else {
        debugPrint('⚠️ Segment $i has no valid polyline data');
      }
    }

    // Only add markers if we have valid points
    if (firstValidPoint != null) {
      markers.add(Marker(
        markerId: const MarkerId("start"),
        position: firstValidPoint,
        infoWindow: InfoWindow(title: widget.route.origin ?? "Start"),
      ));

      if (lastValidPoint != null) {
        markers.add(Marker(
          markerId: const MarkerId("end"),
          position: lastValidPoint,
          infoWindow: InfoWindow(title: widget.route.destination ?? "End"),
        ));
      }

      debugPrint('✅ Added start and end markers');
    } else {
      // Add fallback markers based on textual data
      debugPrint('⚠️ No valid polyline points found, adding fallback markers');
      // You could add geocoding here to convert origin/destination to coordinates
    }

    setState(() {
      _polylines.addAll(polylines);
      _markers.addAll(markers);
    });

    // Delay the camera update to ensure the map is ready
    if (_markers.isNotEmpty && _mapController != null) {
      try {
        LatLngBounds bounds = LatLngBounds(
          southwest: _markers.map((m) => m.position).reduce((a, b) => LatLng(
              a.latitude < b.latitude ? a.latitude : b.latitude,
              a.longitude < b.longitude ? a.longitude : b.longitude)),
          northeast: _markers.map((m) => m.position).reduce((a, b) => LatLng(
              a.latitude > b.latitude ? a.latitude : b.latitude,
              a.longitude > b.longitude ? a.longitude : b.longitude)),
        );

        // Use a longer delay to ensure map is fully loaded
        Future.delayed(const Duration(milliseconds: 500), () {
          _mapController!
              .animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));
        });
      } catch (e) {
        debugPrint('⚠️ Error calculating map bounds: $e');
      }
    }
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
  controller.animateCamera(CameraUpdate.newLatLngZoom(accraCoordinates, 12));
  
  // Add fallback markers if needed
  if (_markers.isEmpty) {
    setState(() {
      // Approximate positions - replace with actual coordinates
      final accraMall = const LatLng(5.632, -0.172);
      final ashesiUniv = const LatLng(5.759, -0.220);
      
      _markers.add(Marker(
        markerId: const MarkerId("start"),
        position: accraMall,
        infoWindow: const InfoWindow(title: "Accra Mall"),
      ));
      
      _markers.add(Marker(
        markerId: const MarkerId("end"),
        position: ashesiUniv,
        infoWindow: const InfoWindow(title: "Ashesi University"),
      ));
      
      // Add a basic polyline connecting the two points
      _polylines.add(Polyline(
        polylineId: const PolylineId("backup_route"),
        color: Colors.blue,
        width: 4,
        points: [accraMall, ashesiUniv],
      ));
    });
  }
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

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 0,
      child: Scaffold(
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
                        'Trip Detailzs',
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
                    children: [
                      // Trip Summary Card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4.0,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Fastest label
                            Text(
                              widget.isFromFavorites
                                  ? 'Saved Route'
                                  : 'Recommended',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Time and star
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
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
                                      ' — ',
                                      style: TextStyle(
                                        color: Colors.grey,
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
                                IconButton(
                                  icon: Icon(
                                    _isFavorite
                                        ? Icons.star
                                        : Icons.star_border,
                                    size: 24,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: _toggleFavorite,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Route text
                            Row(
                              children: [
                                Text(
                                  widget.route.origin ?? 'Unknown',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: Text(
                                    '→',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Text(
                                  widget.route.destination ?? 'Unknown',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Walk info
                            if (widget.route.segments.isNotEmpty)
                              Text(
                                widget.route.segments.first.description,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                              ),
                            const SizedBox(height: 12),

                            // Transfers and Price
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton(
                                  onPressed: () {},
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                          '${widget.route.segments.length - 1} ${widget.route.segments.length - 1 == 1 ? 'Transfer' : 'Transfers'}'),
                                      const SizedBox(width: 4),
                                    ],
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFC32E31),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    textStyle: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'GHS ${widget.route.totalFare.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Map section
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                height: 200,
                                width: double.infinity,
                                child: GoogleMap(
                                  onMapCreated: (controller) {
                                    _mapController = controller;
                                    if (_markers.isNotEmpty) {
                                      final bounds = LatLngBounds(
                                        southwest: _markers
                                            .map((m) => m.position)
                                            .reduce((a, b) => LatLng(
                                                a.latitude < b.latitude
                                                    ? a.latitude
                                                    : b.latitude,
                                                a.longitude < b.longitude
                                                    ? a.longitude
                                                    : b.longitude)),
                                        northeast: _markers
                                            .map((m) => m.position)
                                            .reduce((a, b) => LatLng(
                                                a.latitude > b.latitude
                                                    ? a.latitude
                                                    : b.latitude,
                                                a.longitude > b.longitude
                                                    ? a.longitude
                                                    : b.longitude)),
                                      );

                                      Future.delayed(
                                          const Duration(milliseconds: 100),
                                          () {
                                        controller.animateCamera(
                                            CameraUpdate.newLatLngBounds(
                                                bounds, 50));
                                      });
                                    }
                                  },
                                  initialCameraPosition: CameraPosition(
                                    target: _markers.isNotEmpty
                                        ? _markers.first.position
                                        : const LatLng(5.6037, -0.1870),
                                    zoom: 13,
                                  ),
                                  polylines: _polylines,
                                  markers: _markers,
                                  myLocationButtonEnabled: false,
                                  zoomControlsEnabled: false,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Trip steps
                            ...widget.route.segments
                                .asMap()
                                .entries
                                .map((entry) {
                              final index = entry.key;
                              final segment = entry.value;

                              final isWalk = segment.type == 'walk';
                              final time = segment.departureTime ??
                                  (index == 0
                                      ? widget.route.departureTime
                                      : '');
                              final durationMin =
                                  (segment.duration / 60).ceil();
                              final icon = isWalk
                                  ? Icons.directions_walk
                                  : Icons.directions_bus;
                              final iconColor =
                                  isWalk ? Colors.green : Colors.orange;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 60,
                                      child: Text(time,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500)),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.only(right: 12),
                                      child: CircleAvatar(
                                        radius: 14,
                                        backgroundColor: Colors.grey[200],
                                        child: Icon(icon,
                                            size: 16, color: iconColor),
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(segment.description,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600)),
                                          Text(
                                            isWalk
                                                ? 'Walk for $durationMin min'
                                                : 'Ride for $durationMin min',
                                            style: const TextStyle(
                                                color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              );
                            }).toList(),

                            // Final destination
                            TripStep(
                              time: widget.route.arrivalTime,
                              location:
                                  widget.route.destination ?? 'Destination',
                              instruction: '',
                              icon: Icons.location_on,
                              transportType: 'walk',
                            ),
                          ],
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
