// import 'package:locomo_app/models/route.dart';

// import 'package:locomo_app/services/database_helper.dart';
// import 'package:locomo_app/services/connectivity_service.dart';

// import 'search_results.dart';
// import 'package:flutter/material.dart';
// import 'package:locomo_app/services/map_service.dart';
// import 'package:locomo_app/services/route_service.dart';
// import 'package:locomo_app/models/station_model.dart';
// import 'package:flutter/services.dart';
// import 'package:locomo_app/widgets/MainScaffold.dart' as widgets;
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:uuid/uuid.dart';
// import 'dart:math';

// class TravelHomePage extends StatefulWidget {
//   final String? initialOrigin;
//   final String? initialDestination;

//   const TravelHomePage({
//     Key? key,
//     this.initialOrigin,
//     this.initialDestination,
//   }) : super(key: key);

//   @override
//   State<TravelHomePage> createState() => _TravelHomePageState();
// }

// class _TravelHomePageState extends State<TravelHomePage> {
//   List<String> _allLocations = [];
//   String? _selectedOrigin;
//   String? _selectedDestination;
//   final TextEditingController _controller =
//       TextEditingController(); // Budget controller
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   List<CompositeRoute> _compositeRoutes = [];

//   @override
//   void initState() {
//     super.initState();
//     // Pre-fill the origin and destination if provided
//     _loadLocations();
//   }

//   Future<void> _loadLocations() async {
//     try {
//       // Get user location - ensure this returns a LatLng or similar object
//       final userLocation = await MapService.getUserLocation();
//       final stations = await RouteService.getAllStationsAndStops();

//       setState(() {
//         _allLocations = stations.map((s) => s.name).toList();

//         // Only set closest stations if we have user location
//         if (userLocation != null) {
//           _selectedOrigin = _findClosest(
//               stations, userLocation.latitude, userLocation.longitude);
//           // Set destination to null or find another close station
//           _selectedDestination = null;
//         } else {
//           // Fallback to first station if no location available
//           _selectedOrigin = stations.isNotEmpty ? stations.first.name : null;
//           _selectedDestination = null;
//         }
//       });
//     } catch (e) {
//       debugPrint('Error loading locations: $e');
//       // Fallback to loading just station names
//       final stations = await RouteService.getAllStationsAndStops();
//       setState(() {
//         _allLocations = stations.map((s) => s.name).toList();
//         _selectedOrigin = stations.isNotEmpty ? stations.first.name : null;
//         _selectedDestination = null;
//       });
//     }
//   }

//   // Get the current user's ID
//   String? get currentUserId => _auth.currentUser?.uid;

//   @override
//   Widget build(BuildContext context) {
//     return widgets.MainScaffold(
//       currentIndex: 0,
//       child: SafeArea(
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Stack(
//                 children: [
//                   CustomPaint(
//                     size: const Size(double.infinity, 225),
//                     painter: RedCurvePainter(),
//                   ),
//                   Container(
//                     width: double.infinity,
//                     padding: const EdgeInsets.all(20),
//                     child: Column(
//                       children: [
//                         const SizedBox(height: 5),
//                         Image.asset(
//                           'assets/images/locomo_logo3.png',
//                           width: 50,
//                           height: 50,
//                         ),
//                         const SizedBox(height: 5),
//                         const Text(
//                           'What are your\ntravel plans?',
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                             fontFamily: 'Poppins',
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     DropdownButtonFormField<String>(
//                       value: _selectedOrigin,
//                       decoration: InputDecoration(labelText: 'Origin'),
//                       items: _allLocations
//                           .map((loc) => DropdownMenuItem(
//                                 value: loc,
//                                 child: Text(loc),
//                               ))
//                           .toList(),
//                       onChanged: (val) => setState(() => _selectedOrigin = val),
//                     ),
//                     const SizedBox(height: 16),
//                     DropdownButtonFormField<String>(
//                       value: _selectedOrigin,
//                       decoration: InputDecoration(labelText: 'Destination'),
//                       items: _allLocations
//                           .map((loc) => DropdownMenuItem(
//                                 value: loc,
//                                 child: Text(loc),
//                               ))
//                           .toList(),
//                       onChanged: (val) => setState(() => _selectedOrigin = val),
//                     ),
//                     const SizedBox(height: 16),
//                     Row(
//                       children: [
//                         Expanded(
//                           flex: 2,
//                           child: DropdownButtonFormField<String>(
//                             iconEnabledColor: Colors.white,
//                             dropdownColor: const Color(0xFFd9d9d9),
//                             decoration: const InputDecoration(
//                               labelText: 'Travel Preference',
//                               labelStyle: TextStyle(
//                                 color: Color(0xFFD9D9D9),
//                                 fontWeight: FontWeight.w200,
//                                 fontFamily: 'Poppins',
//                                 fontSize: 16,
//                               ),
//                               enabledBorder: OutlineInputBorder(
//                                 borderSide:
//                                     BorderSide(color: Color(0xFFD9D9D9)),
//                               ),
//                               focusedBorder: OutlineInputBorder(
//                                 borderSide:
//                                     BorderSide(color: Color(0xFFD9D9D9)),
//                               ),
//                               contentPadding: EdgeInsets.symmetric(
//                                   horizontal: 16, vertical: 12),
//                             ),
//                             style: const TextStyle(
//                               color: Colors.black,
//                               fontSize: 16,
//                               fontFamily: 'Poppins',
//                               fontWeight: FontWeight.w400,
//                             ),
//                             value: 'lowest_fare',
//                             items: const [
//                               DropdownMenuItem(
//                                   value: 'none', child: Text('None')),
//                               DropdownMenuItem(
//                                   value: 'shortest_time',
//                                   child: Text('Shortest Time')),
//                               DropdownMenuItem(
//                                   value: 'lowest_fare',
//                                   child: Text('Lowest Fare')),
//                               DropdownMenuItem(
//                                   value: 'fewest_transfers',
//                                   child: Text('Fewest Transfers')),
//                             ],
//                             onChanged: (value) {},
//                           ),
//                         ),
//                         const SizedBox(width: 16),
//                         Expanded(
//                           flex: 1,
//                           child: TextField(
//                             controller: _controller,
//                             keyboardType: const TextInputType.numberWithOptions(
//                                 decimal: true),
//                             inputFormatters: [
//                               FilteringTextInputFormatter.allow(
//                                   RegExp(r'^\d+(\.\d{0,2})?')),
//                             ],
//                             decoration: const InputDecoration(
//                               labelText: 'Budget',
//                               prefixText: 'GHC ',
//                               labelStyle: TextStyle(
//                                 color: Color(0xFFD9D9D9),
//                                 fontWeight: FontWeight.w200,
//                                 fontFamily: 'Poppins',
//                                 fontSize: 16,
//                               ),
//                               enabledBorder: OutlineInputBorder(
//                                 borderSide:
//                                     BorderSide(color: Color(0xFFD9D9D9)),
//                               ),
//                               focusedBorder: OutlineInputBorder(
//                                 borderSide:
//                                     BorderSide(color: Color(0xFFD9D9D9)),
//                               ),
//                               contentPadding: EdgeInsets.symmetric(
//                                   horizontal: 16, vertical: 12),
//                             ),
//                             style: const TextStyle(
//                               color: Colors.black,
//                               fontSize: 16,
//                               fontFamily: 'Poppins',
//                               fontWeight: FontWeight.w400,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 20),
//                     SizedBox(
//                       width: double.infinity,
//                       height: 50,
//                       child: ElevatedButton(
//                         onPressed: () async {
//                           final origin = _selectedOrigin;
//                           final destination = _selectedDestination;

//                           if (origin == null || destination == null) {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(
//                                   content: Text(
//                                       "Please select both origin and destination")),
//                             );
//                             return;
//                           }

//                           try {
//                             // Use the composite route search that includes walking segments.
//                             final compositeRoutes =
//                                 await RouteService.searchCompositeRoutes(
//                               origin: origin,
//                               destination: destination,
//                               preference:
//                                   'lowest_fare', // or get it from your dropdown
//                               budget: double.tryParse(_controller.text.trim()),
//                             );

//                             if (compositeRoutes.isEmpty) {
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 const SnackBar(
//                                     content:
//                                         Text("No suggested routes found.")),
//                               );
//                               return;
//                             }

//                             // Save search results for offline viewing
//                             final String searchId = const Uuid().v4();
//                             await DatabaseHelper().saveOfflineRoute(
//                               id: searchId,
//                               origin: origin,
//                               destination: destination,
//                               routeData: {
//                                 'routes': compositeRoutes
//                                     .map((r) => r.toJson())
//                                     .toList(),
//                                 'timestamp': DateTime.now().toIso8601String(),
//                               },
//                             );

//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (_) => TravelResultsPage(
//                                   results:
//                                       compositeRoutes.cast<CompositeRoute>(),
//                                   origin: origin,
//                                   destination: destination,
//                                   onSaveRoute: _saveRouteToFavorites,
//                                 ),
//                               ),
//                             );
//                           } catch (e) {
//                             // Check if we're offline and try to load from local database
//                             final isOnline =
//                                 await ConnectivityService().isConnected();

//                             if (!isOnline) {
//                               // Try to load from local database
//                               final offlineRoutes =
//                                   await DatabaseHelper().getOfflineRoutes();
//                               final matchingRoutes = offlineRoutes
//                                   .where((route) =>
//                                       route['origin'] == origin &&
//                                       route['destination'] == destination)
//                                   .toList();

//                               if (matchingRoutes.isNotEmpty) {
//                                 // Use the most recent matching route
//                                 final routeData = matchingRoutes
//                                     .first['routeData'] as Map<String, dynamic>;
//                                 final routesJson =
//                                     routeData['routes'] as List<dynamic>;

//                                 // Convert JSON back to CompositeRoute objects
//                                 final compositeRoutes = routesJson
//                                     .map(
//                                         (json) => CompositeRoute.fromJson(json))
//                                     .toList();

//                                 Navigator.push(
//                                   context,
//                                   MaterialPageRoute(
//                                     builder: (_) => TravelResultsPage(
//                                       results: compositeRoutes
//                                           .cast<CompositeRoute>(),
//                                       origin: origin,
//                                       destination: destination,
//                                       onSaveRoute: _saveRouteToFavorites,
//                                     ),
//                                   ),
//                                 );
//                               } else {
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   const SnackBar(
//                                       content: Text(
//                                           "No routes found. Please check your internet connection.")),
//                                 );
//                               }
//                             } else {
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 SnackBar(
//                                     content:
//                                         Text("Error searching for routes: $e")),
//                               );
//                             }
//                           }
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFFC32E31),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                         ),
//                         child: const Text(
//                           'Search',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 18,
//                             fontWeight: FontWeight.normal,
//                             fontFamily: 'Poppins',
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 24),
//                     const Divider(color: Color(0xFFD9D9D9)),
//                     const SizedBox(height: 16),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         const Text(
//                           'Explore Stations',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.w600,
//                             fontFamily: 'Poppins',
//                           ),
//                         ),
//                         TextButton(
//                           onPressed: () {},
//                           child: const Text(
//                             'See All',
//                             style: TextStyle(
//                               color: Color(0xFFC32E31),
//                               fontWeight: FontWeight.w500,
//                               fontSize: 13,
//                               fontFamily: 'Poppins',
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 12),
//                     SizedBox(
//                       height: 180,
//                       child: ListView(
//                         scrollDirection: Axis.horizontal,
//                         children: [
//                           StationCard(
//                             imagePath: 'assets/images/onboarding11.png',
//                             stationName: 'Shiashie Station',
//                           ),
//                           const SizedBox(width: 12),
//                           StationCard(
//                             imagePath: 'assets/images/onboarding8.jpg',
//                             stationName: 'Kaneshie Station',
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   String _findClosest(
//       List<TrotroStation> stations, double userLat, double userLng) {
//     double _toRadians(double degree) => degree * (pi / 180); // 👈 Move this up

//     double calculateDistance(
//         double lat1, double lon1, double lat2, double lon2) {
//       const earthRadius = 6371;
//       final dLat = _toRadians(lat2 - lat1);
//       final dLon = _toRadians(lon2 - lon1);
//       final a = sin(dLat / 2) * sin(dLat / 2) +
//           cos(_toRadians(lat1)) *
//               cos(_toRadians(lat2)) *
//               sin(dLon / 2) *
//               sin(dLon / 2);
//       final c = 2 * atan2(sqrt(a), sqrt(1 - a));
//       return earthRadius * c;
//     }

//     stations.sort((a, b) {
//       final distA =
//           calculateDistance(userLat, userLng, a.latitude, a.longitude);
//       final distB =
//           calculateDistance(userLat, userLng, b.latitude, b.longitude);
//       return distA.compareTo(distB);
//     });

//     return stations.isNotEmpty ? stations.first.name : '';
//   }

//   // Save a route to the user's favorites
//   Future<void> _saveRouteToFavorites(
//       String origin, String destination, double fare) async {
//     // Check if user is signed in
//     if (currentUserId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please sign in to save routes'),
//           backgroundColor: Color(0xFFC32E31),
//         ),
//       );
//       return;
//     }

//     try {
//       // Create a basic route object since we don't have the full route data here
//       final routeMap = {
//         'segments': [],
//         'totalFare': fare,
//         'totalDuration': 0,
//         'departureTime': 'Now',
//         'arrivalTime': 'Later',
//         'origin': origin,
//         'destination': destination,
//       };

//       // Check if this route is already saved for this specific user
//       final existingRoutes = await _firestore
//           .collection('users')
//           .doc(currentUserId)
//           .collection('favorite_routes')
//           .where('origin', isEqualTo: origin)
//           .where('destination', isEqualTo: destination)
//           .get();

//       if (existingRoutes.docs.isNotEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('This route is already in your favorites'),
//             backgroundColor: Color(0xFFC32E31),
//           ),
//         );
//         return;
//       }

//       // Save the new route to the specific user's collection
//       await _firestore
//           .collection('users')
//           .doc(currentUserId)
//           .collection('favorite_routes')
//           .add({
//         'origin': origin,
//         'destination': destination,
//         'fare': fare,
//         'routeData': routeMap,
//         'createdAt': FieldValue.serverTimestamp(),
//         'userId': currentUserId, // Add user ID for additional security
//       });

//       // Also save to local database for offline access
//       final routeId = DateTime.now().millisecondsSinceEpoch.toString();
//       await DatabaseHelper().addFavoriteRoute(
//         id: routeId,
//         userId: currentUserId!,
//         origin: origin,
//         destination: destination,
//         fare: fare,
//         routeData: routeMap,
//         synced: 1,
//       );

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Route saved to favorites'),
//           backgroundColor: Color(0xFFC32E31),
//         ),
//       );
//     } catch (e) {
//       debugPrint('Error saving route to favorites: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to save route: ${e.toString()}'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
// }

// class StationCard extends StatelessWidget {
//   final String imagePath;
//   final String stationName;

//   const StationCard({
//     Key? key,
//     required this.imagePath,
//     required this.stationName,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 160,
//       height: 180,
//       clipBehavior: Clip.hardEdge,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Stack(
//         fit: StackFit.expand,
//         children: [
//           Image.asset(
//             imagePath,
//             fit: BoxFit.cover,
//           ),
//           Container(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 colors: [
//                   Colors.transparent,
//                   Colors.black.withOpacity(0.7),
//                 ],
//               ),
//             ),
//           ),
//           Positioned(
//             bottom: 12,
//             left: 12,
//             right: 12,
//             child: Text(
//               stationName,
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.w600,
//                 fontSize: 15,
//                 fontFamily: 'Poppins',
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class RedCurvePainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     // Base color background
//     final Paint basePaint = Paint()
//       ..color = const Color(0xFFB22A2D)
//       ..style = PaintingStyle.fill;
//     canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);

//     // Light red curve
//     final Paint lightCurvePaint = Paint()
//       ..color = const Color(0xFFC32E31)
//       ..style = PaintingStyle.fill;
//     final Path lightCurvePath = Path();
//     lightCurvePath.moveTo(0, size.height * 0.6);
//     lightCurvePath.quadraticBezierTo(
//         size.width * 0.7, size.height * 0.2, size.width, size.height * 0.3);
//     lightCurvePath.lineTo(size.width, 0);
//     lightCurvePath.lineTo(0, 0);
//     lightCurvePath.close();
//     canvas.drawPath(lightCurvePath, lightCurvePaint);

//     // Darker bottom curve
//     final Paint darkCurvePaint = Paint()
//       ..color = const Color(0xFF9E2528)
//       ..style = PaintingStyle.fill;
//     final Path darkCurvePath = Path();
//     darkCurvePath.moveTo(size.width * 0.5, size.height);
//     darkCurvePath.quadraticBezierTo(
//         size.width * 0.8, size.height * 0.7, size.width, size.height * 0.8);
//     darkCurvePath.lineTo(size.width, size.height);
//     darkCurvePath.close();
//     canvas.drawPath(darkCurvePath, darkCurvePaint);
//   }

//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => false;
// }
import 'package:locomo_app/models/route.dart';

import 'package:locomo_app/services/database_helper.dart';
import 'package:locomo_app/services/connectivity_service.dart';

import 'search_results.dart';
import 'package:flutter/material.dart';
import 'package:locomo_app/services/map_service.dart';
import 'package:locomo_app/services/route_service.dart';
import 'package:locomo_app/models/station_model.dart';
import 'package:flutter/services.dart';
import 'package:locomo_app/widgets/MainScaffold.dart' as widgets;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';

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
  List<String> _allLocations = [];
  List<TrotroStation> _allStations = []; // Add this line to store all stations
  String? _selectedOrigin;
  String? _selectedDestination;
  final TextEditingController _controller =
      TextEditingController(); // Budget controller
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<CompositeRoute> _compositeRoutes = [];

  @override
  void initState() {
    super.initState();
    // Pre-fill the origin and destination if provided
    _loadLocations();
  }

  Future<void> _loadLocations() async {
  final locationString = await MapService.getUserLocation();
  final stations = await RouteService.getAllStationsAndStops();

  if (locationString == null) {
    debugPrint("User location is null. Cannot determine closest station.");
    return;
  }

  final parts = locationString.split(',');
  final double userLat = double.parse(parts[0]);
  final double userLng = double.parse(parts[1]);

  setState(() {
    _allLocations = stations.map((s) => s.name).toList();
    _selectedOrigin = _findClosest(stations, userLat, userLng);
    _selectedDestination = _findClosest(stations, userLat, userLng);
  });
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
                    DropdownButtonFormField<String>(
                      value: _selectedOrigin,
                      decoration: const InputDecoration(labelText: 'Origin'),
                      items: _allLocations
                          .map((loc) => DropdownMenuItem(
                                value: loc,
                                child: Text(loc),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedOrigin = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value:
                          _selectedDestination, // Fix: use _selectedDestination instead of _selectedOrigin
                      decoration:
                          const InputDecoration(labelText: 'Destination'),
                      items: _allLocations
                          .map((loc) => DropdownMenuItem(
                                value: loc,
                                child: Text(loc),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedDestination =
                          val), // Fix: update _selectedDestination
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
                          final origin = _selectedOrigin;
                          final destination = _selectedDestination;

                          if (origin == null || destination == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      "Please select both origin and destination")),
                            );
                            return;
                          }

                          try {
                            // Use the composite route search that includes walking segments.
                            final compositeRoutes =
                                await RouteService.searchCompositeRoutes(
                              origin: origin,
                              destination: destination,
                              preference:
                                  'lowest_fare', // or get it from your dropdown
                              budget: double.tryParse(_controller.text.trim()),
                            );

                            if (compositeRoutes.isEmpty) {
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
                                'routes': compositeRoutes
                                    .map((r) => r.toJson())
                                    .toList(),
                                'timestamp': DateTime.now().toIso8601String(),
                              },
                            );

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TravelResultsPage(
                                  results:
                                      compositeRoutes.cast<CompositeRoute>(),
                                  origin: origin,
                                  destination: destination,
                                  onSaveRoute: _saveRouteToFavorites,
                                ),
                              ),
                            );
                          } catch (e) {
                            // Check if we're offline and try to load from local database
                            final isOnline =
                                await ConnectivityService().isConnected();

                            if (!isOnline) {
                              // Try to load from local database
                              final offlineRoutes =
                                  await DatabaseHelper().getOfflineRoutes();
                              final matchingRoutes = offlineRoutes
                                  .where((route) =>
                                      route['origin'] == origin &&
                                      route['destination'] == destination)
                                  .toList();

                              if (matchingRoutes.isNotEmpty) {
                                // Use the most recent matching route
                                final routeData = matchingRoutes
                                    .first['routeData'] as Map<String, dynamic>;
                                final routesJson =
                                    routeData['routes'] as List<dynamic>;

                                // Convert JSON back to CompositeRoute objects
                                final compositeRoutes = routesJson
                                    .map(
                                        (json) => CompositeRoute.fromJson(json))
                                    .toList();

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TravelResultsPage(
                                      results: compositeRoutes
                                          .cast<CompositeRoute>(),
                                      origin: origin,
                                      destination: destination,
                                      onSaveRoute: _saveRouteToFavorites,
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          "No routes found. Please check your internet connection.")),
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text("Error searching for routes: $e")),
                              );
                            }
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

  String _findClosest(
      List<TrotroStation> stations, double userLat, double userLng) {
    double _toRadians(double degree) => degree * (pi / 180);

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

    return stations.isNotEmpty ? stations.first.name : '';
  }

  // Save a route to the user's favorites
  Future<void> _saveRouteToFavorites(
      String origin, String destination, double fare) async {
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
