import 'package:locomo_app/models/route.dart';
import 'package:locomo_app/services/database_helper.dart';
import 'package:locomo_app/services/connectivity_service.dart';

import 'search_results.dart';
import 'package:flutter/material.dart';
import 'package:locomo_app/services/map_service.dart';
import 'package:locomo_app/services/route_service.dart';
import 'package:flutter/services.dart';
import 'package:locomo_app/widgets/MainScaffold.dart' as widgets;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class TravelHomePage extends StatefulWidget {
  final String? initialOrigin;
  final String? initialDestination;

  const TravelHomePage({
    Key? key, 
    this.initialOrigin,
    this.initialDestination,
  }) : super(key: key);

  @override
  State<TravelHomePage> createState() => _TravelHomePageState();
}

class _TravelHomePageState extends State<TravelHomePage> {
  final TextEditingController originController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  final TextEditingController _controller = TextEditingController(); // Budget controller
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<CompositeRoute> _compositeRoutes = [];

  @override
  void initState() {
    super.initState();
    // Pre-fill the origin and destination if provided
    if (widget.initialOrigin != null) {
      originController.text = widget.initialOrigin!;
    }
    if (widget.initialDestination != null) {
      destinationController.text = widget.initialDestination!;
    }
  }

  // Get the current user's ID
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return widgets.MainScaffold(
      currentIndex: 0,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CustomPaint(
                    size: const Size(double.infinity, 225),
                    painter: RedCurvePainter(),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const SizedBox(height: 5),
                        Image.asset(
                          'assets/images/locomo_logo3.png',
                          width: 50,
                          height: 50,
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'What are your\ntravel plans?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: originController,
                      decoration: const InputDecoration(
                        labelText: 'Origin',
                        labelStyle: TextStyle(
                          color: Color(0xFFD9D9D9),
                          fontWeight: FontWeight.w200,
                          fontFamily: 'Poppins',
                          fontSize: 16,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFD9D9D9)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFD9D9D9)),
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: destinationController,
                      decoration: const InputDecoration(
                        labelText: 'Destination',
                        labelStyle: TextStyle(
                          color: Color(0xFFD9D9D9),
                          fontWeight: FontWeight.w200,
                          fontFamily: 'Poppins',
                          fontSize: 16,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFD9D9D9)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFD9D9D9)),
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            iconEnabledColor: Colors.white,
                            dropdownColor: const Color(0xFFd9d9d9),
                            decoration: const InputDecoration(
                              labelText: 'Travel Preference',
                              labelStyle: TextStyle(
                                color: Color(0xFFD9D9D9),
                                fontWeight: FontWeight.w200,
                                fontFamily: 'Poppins',
                                fontSize: 16,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color(0xFFD9D9D9)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color(0xFFD9D9D9)),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400,
                            ),
                            value: 'lowest_fare',
                            items: const [
                              DropdownMenuItem(
                                  value: 'none', child: Text('None')),
                              DropdownMenuItem(
                                  value: 'shortest_time',
                                  child: Text('Shortest Time')),
                              DropdownMenuItem(
                                  value: 'lowest_fare',
                                  child: Text('Lowest Fare')),
                              DropdownMenuItem(
                                  value: 'fewest_transfers',
                                  child: Text('Fewest Transfers')),
                            ],
                            onChanged: (value) {},
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: _controller,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+(\.\d{0,2})?')),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Budget',
                              prefixText: 'GHC ',
                              labelStyle: TextStyle(
                                color: Color(0xFFD9D9D9),
                                fontWeight: FontWeight.w200,
                                fontFamily: 'Poppins',
                                fontSize: 16,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color(0xFFD9D9D9)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color(0xFFD9D9D9)),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          final origin = originController.text.trim();
                          final destination = destinationController.text.trim();

                          if (origin.isEmpty || destination.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      "Please enter both origin and destination")),
                            );
                            return;
                          }

                          try {
                            // Use the composite route search that includes walking segments.
                            final dynamicRoutes =
                                await RouteService.searchCompositeRoutes(
                              origin: origin,
                              destination: destination,
                              preference:
                                  'lowest_fare', // or get it from your dropdown
                              budget: double.tryParse(_controller.text.trim()),
                            );

                            if (dynamicRoutes.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text("No suggested routes found.")),
                              );
                              return;
                            }

                            // Save search results for offline viewing
                            final String searchId = const Uuid().v4();
                            await DatabaseHelper().saveOfflineRoute(
                              id: searchId,
                              origin: origin,
                              destination: destination,
                              routeData: {
                                'routes': dynamicRoutes,
                                'timestamp': DateTime.now().toIso8601String(),
                              },
                            );

                            // Get current time for departure
                            final now = DateTime.now();
                            final departureTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
                            
                            // Convert dynamic routes to CompositeRoute objects with time information
                            final compositeRoutes = await Future.wait(dynamicRoutes.map((route) async {
                              // Get walking directions for origin and destination
                              Map<String, dynamic>? originWalking;
                              Map<String, dynamic>? destinationWalking;
                              
                              try {
                                originWalking = await MapService.getWalkingDirections(
                                  origin: origin,
                                  destination: route['firstStation'] ?? origin,
                                );
                              } catch (e) {
                                debugPrint('Error getting origin walking directions: $e');
                              }
                              
                              try {
                                destinationWalking = await MapService.getWalkingDirections(
                                  origin: route['lastStation'] ?? destination,
                                  destination: destination,
                                );
                              } catch (e) {
                                debugPrint('Error getting destination walking directions: $e');
                              }
                              
                              // Calculate total duration including walking
                              final originWalkingDuration = originWalking?['duration'] as int? ?? 0;
                              final destinationWalkingDuration = destinationWalking?['duration'] as int? ?? 0;
                              final routeDuration = route['time'] as int? ?? 0;
                              
                              final totalDuration = routeDuration + originWalkingDuration + destinationWalkingDuration;
                              
                              // Calculate arrival time
                              final arrivalDateTime = now.add(Duration(minutes: totalDuration));
                              final arrivalTime = '${arrivalDateTime.hour.toString().padLeft(2, '0')}:${arrivalDateTime.minute.toString().padLeft(2, '0')}';
                              
                              // Create route segments
                              final segments = <RouteSegment>[];
                              
                              // Add origin walking segment if needed
                              if (originWalking != null && originWalking['distance'] != null) {
                                segments.add(RouteSegment(
                                  description: 'Walk from $origin to ${route['firstStation'] ?? origin}',
                                  fare: 0,
                                  duration: originWalkingDuration,
                                  type: 'walk',
                                ));
                              }
                              
                              // Add main route segment
                              segments.add(RouteSegment(
                                description: route['details']?.toString() ?? 'Direct route',
                                fare: (route['fare'] ?? 0).toDouble(),
                                duration: routeDuration,
                                type: 'bus',
                              ));
                              
                              // Add destination walking segment if needed
                              if (destinationWalking != null && destinationWalking['distance'] != null) {
                                segments.add(RouteSegment(
                                  description: 'Walk from ${route['lastStation'] ?? destination} to $destination',
                                  fare: 0,
                                  duration: destinationWalkingDuration,
                                  type: 'walk',
                                ));
                              }
                              
                              // Create the composite route with non-null values
                              return CompositeRoute(
                                segments: segments,
                                totalFare: (route['fare'] ?? 0).toDouble(),
                                totalDuration: totalDuration,
                                departureTime: departureTime,
                                arrivalTime: arrivalTime,
                                origin: origin,
                                destination: destination,
                              );
                            }));

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    TravelResultsPage(
                                      results: compositeRoutes,
                                      origin: origin,
                                      destination: destination,
                                      onSaveRoute: _saveRouteToFavorites,
                                    ),
                              ),
                            );
                          } catch (e) {
                            // Check if we're offline and try to load from local database
                            final isOnline = await ConnectivityService().isConnected();
                            
                            if (!isOnline) {
                              // Try to load from local database
                              final offlineRoutes = await DatabaseHelper().getOfflineRoutes();
                              final matchingRoutes = offlineRoutes.where((route) => 
                                route['origin'] == origin && 
                                route['destination'] == destination
                              ).toList();
                              
                              if (matchingRoutes.isNotEmpty) {
                                // Use the most recent matching route
                                final routeData = matchingRoutes.first['routeData'] as Map<String, dynamic>;
                                final dynamicRoutes = routeData['routes'] as List<dynamic>;
                                
                                // Get current time for departure
                                final now = DateTime.now();
                                final departureTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
                                
                                // Convert dynamic routes to CompositeRoute objects with time information
                                final compositeRoutes = await Future.wait(dynamicRoutes.map((route) async {
                                  // Get walking directions for origin and destination
                                  Map<String, dynamic>? originWalking;
                                  Map<String, dynamic>? destinationWalking;
                                  
                                  try {
                                    originWalking = await MapService.getWalkingDirections(
                                      origin: origin,
                                      destination: route['firstStation'] ?? origin,
                                    );
                                  } catch (e) {
                                    debugPrint('Error getting origin walking directions: $e');
                                  }
                                  
                                  try {
                                    destinationWalking = await MapService.getWalkingDirections(
                                      origin: route['lastStation'] ?? destination,
                                      destination: destination,
                                    );
                                  } catch (e) {
                                    debugPrint('Error getting destination walking directions: $e');
                                  }
                                  
                                  // Calculate total duration including walking
                                  final originWalkingDuration = originWalking?['duration'] as int? ?? 0;
                                  final destinationWalkingDuration = destinationWalking?['duration'] as int? ?? 0;
                                  final routeDuration = route['time'] as int? ?? 0;
                                  
                                  final totalDuration = routeDuration + originWalkingDuration + destinationWalkingDuration;
                                  
                                  // Calculate arrival time
                                  final arrivalDateTime = now.add(Duration(minutes: totalDuration));
                                  final arrivalTime = '${arrivalDateTime.hour.toString().padLeft(2, '0')}:${arrivalDateTime.minute.toString().padLeft(2, '0')}';
                                  
                                  // Create route segments
                                  final segments = <RouteSegment>[];
                                  
                                  // Add origin walking segment if needed
                                  if (originWalking != null && originWalking['distance'] != null) {
                                    segments.add(RouteSegment(
                                      description: 'Walk from $origin to ${route['firstStation'] ?? origin}',
                                      fare: 0,
                                      duration: originWalkingDuration,
                                      type: 'walk',
                                    ));
                                  }
                                  
                                  // Add main route segment
                                  segments.add(RouteSegment(
                                    description: route['details']?.toString() ?? 'Direct route',
                                    fare: (route['fare'] ?? 0).toDouble(),
                                    duration: routeDuration,
                                    type: 'bus',
                                  ));
                                  
                                  // Add destination walking segment if needed
                                  if (destinationWalking != null && destinationWalking['distance'] != null) {
                                    segments.add(RouteSegment(
                                      description: 'Walk from ${route['lastStation'] ?? destination} to $destination',
                                      fare: 0,
                                      duration: destinationWalkingDuration,
                                      type: 'walk',
                                    ));
                                  }
                                  
                                  // Create the composite route with non-null values
                                  return CompositeRoute(
                                    segments: segments,
                                    totalFare: (route['fare'] ?? 0).toDouble(),
                                    totalDuration: totalDuration,
                                    departureTime: departureTime,
                                    arrivalTime: arrivalTime,
                                    origin: origin,
                                    destination: destination,
                                  );
                                }));

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        TravelResultsPage(
                                          results: compositeRoutes,
                                          origin: origin,
                                          destination: destination,
                                          onSaveRoute: _saveRouteToFavorites,
                                        ),
                                  ),
                                );
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Showing offline results"),
                                    backgroundColor: Color(0xFFC32E31),
                                  ),
                                );
                                return;
                              }
                            }
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: $e")),
                            );
                          }
                        },

                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC32E31),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Search',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.normal,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Color(0xFFD9D9D9)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Explore Stations',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'See All',
                            style: TextStyle(
                              color: Color(0xFFC32E31),
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 180,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          StationCard(
                            imagePath: 'assets/images/onboarding11.png',
                            stationName: 'Shiashie Station',
                          ),
                          const SizedBox(width: 12),
                          StationCard(
                            imagePath: 'assets/images/onboarding8.jpg',
                            stationName: 'Kaneshie Station',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Save a route to the user's favorites
  Future<void> _saveRouteToFavorites(String origin, String destination, double fare) async {
    // Check if user is signed in
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to save routes'),
          backgroundColor: Color(0xFFC32E31),
        ),
      );
      return;
    }

    try {
      // Create a basic route object since we don't have the full route data here
      final routeMap = {
        'segments': [],
        'totalFare': fare,
        'totalDuration': 0,
        'departureTime': 'Now',
        'arrivalTime': 'Later',
        'origin': origin,
        'destination': destination,
      };

      // Check if this route is already saved for this specific user
      final existingRoutes = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('favorite_routes')
          .where('origin', isEqualTo: origin)
          .where('destination', isEqualTo: destination)
          .get();

      if (existingRoutes.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This route is already in your favorites'),
            backgroundColor: Color(0xFFC32E31),
          ),
        );
        return;
      }

      // Save the new route to the specific user's collection
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('favorite_routes')
          .add({
        'origin': origin,
        'destination': destination,
        'fare': fare,
        'routeData': routeMap,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': currentUserId, // Add user ID for additional security
      });

      // Also save to local database for offline access
      final routeId = DateTime.now().millisecondsSinceEpoch.toString();
      await DatabaseHelper().addFavoriteRoute(
        id: routeId,
        userId: currentUserId!,
        origin: origin,
        destination: destination,
        fare: fare,
        routeData: routeMap,
        synced: 1,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Route saved to favorites'),
          backgroundColor: Color(0xFFC32E31),
        ),
      );
    } catch (e) {
      debugPrint('Error saving route to favorites: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save route: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class StationCard extends StatelessWidget {
  final String imagePath;
  final String stationName;

  const StationCard({
    Key? key,
    required this.imagePath,
    required this.stationName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 180,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            imagePath,
            fit: BoxFit.cover,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Text(
              stationName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RedCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Base color background
    final Paint basePaint = Paint()
      ..color = const Color(0xFFB22A2D)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);

    // Light red curve
    final Paint lightCurvePaint = Paint()
      ..color = const Color(0xFFC32E31)
      ..style = PaintingStyle.fill;
    final Path lightCurvePath = Path();
    lightCurvePath.moveTo(0, size.height * 0.6);
    lightCurvePath.quadraticBezierTo(
        size.width * 0.7, size.height * 0.2, size.width, size.height * 0.3);
    lightCurvePath.lineTo(size.width, 0);
    lightCurvePath.lineTo(0, 0);
    lightCurvePath.close();
    canvas.drawPath(lightCurvePath, lightCurvePaint);

    // Darker bottom curve
    final Paint darkCurvePaint = Paint()
      ..color = const Color(0xFF9E2528)
      ..style = PaintingStyle.fill;
    final Path darkCurvePath = Path();
    darkCurvePath.moveTo(size.width * 0.5, size.height);
    darkCurvePath.quadraticBezierTo(
        size.width * 0.8, size.height * 0.7, size.width, size.height * 0.8);
    darkCurvePath.lineTo(size.width, size.height);
    darkCurvePath.close();
    canvas.drawPath(darkCurvePath, darkCurvePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
