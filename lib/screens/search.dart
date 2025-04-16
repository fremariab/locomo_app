import 'package:locomo_app/models/route.dart';
import 'package:locomo_app/services/database_helper.dart';
import 'package:locomo_app/services/connectivity_service.dart';
import 'package:locomo_app/screens/station_detail_screen.dart';
import 'package:locomo_app/screens/search_results.dart' as search_results;
import 'package:flutter/material.dart';
import 'package:locomo_app/services/map_service.dart';
import 'package:locomo_app/services/route_service.dart';
import 'package:locomo_app/models/station_model.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:locomo_app/widgets/main_scaffold.dart';

class TravelHomePage extends StatefulWidget {
  final String? initialOrigin;
  final String? initialDestination;

  const TravelHomePage({
    super.key,
    this.initialOrigin,
    this.initialDestination,
  });

  @override
  State<TravelHomePage> createState() => _TravelHomePageState();
}

class _TravelHomePageState extends State<TravelHomePage> {
  List<TrotroStation> _allStations = [];
  String? _selectedOrigin;
  String? _selectedDestination;
  final TextEditingController _controller = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool useDartRouting =
      false; // Change to true to test local Dart-based routing
  String _selectedPreference = 'lowest_fare';

  @override
  void initState() {
    super.initState();
    _loadLocations();
    _loadAllStations();
  }

  Future<void> _loadAllStations() async {
    final stations = await RouteService.getAllStationsAndStops();
    if (mounted) {
      setState(() {
        _allStations = stations;
      });
    }
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

    if (mounted) {
      setState(() {
        _selectedOrigin = _findClosest(stations, userLat, userLng);
        _selectedDestination = _findClosest(stations, userLat, userLng);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
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
                      decoration: const InputDecoration(
                        labelText: 'Origin',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => setState(() => _selectedOrigin = val),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Destination',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) =>
                          setState(() => _selectedDestination = val),
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
                                fontWeight: FontWeight.w400,
                              ),
                              value: _selectedPreference,
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
                              onChanged: (value) {
                                setState(() {
                                  _selectedPreference = value ?? 'lowest_fare';
                                });
                              },
                            )),
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
                                    "Please select both origin and destination"),
                              ),
                            );
                            return;
                          }

                          try {
                            final routes =
                                await RouteService.findRouteDartBased(
                                    origin, destination);
                            if (routes.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      search_results.TravelResultsPage(
                                    results: routes,
                                    origin: origin,
                                    destination: destination,
                                    initialSortBy: _selectedPreference,
                                    onSaveRoute: _saveRouteToFavorites,
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      "No valid Trotro routes available for this trip. Try changing origin or destination."),
                                ),
                              );
                            }
                          } catch (e) {
                            debugPrint('❌ Error in Dart route finding: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text("Error finding route: $e")),
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
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StationsListScreen(
                                  stations: _allStations,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'See All',
                            style: TextStyle(
                              color: Color(0xFFC32E31),
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
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
                            onTap: () =>
                                _navigateToStationDetail('Shiashie Station'),
                          ),
                          const SizedBox(width: 12),
                          StationCard(
                            imagePath: 'assets/images/onboarding8.jpg',
                            stationName: 'Kaneshie Station',
                            onTap: () =>
                                _navigateToStationDetail('Kaneshie Station'),
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

  Future<void> _navigateToStationDetail(String stationName) async {
    try {
      final station = _allStations.firstWhere(
        (s) => s.name == stationName,
        orElse: () => TrotroStation.temporary(
          name: stationName,
          latitude: 0.0,
          longitude: 0.0,
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StationDetailScreen(station: station),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading station details: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _findClosest(
      List<TrotroStation> stations, double userLat, double userLng) {
    if (stations.isEmpty) return '';

    stations.sort((a, b) {
      final distA = a.distanceTo(userLat, userLng);
      final distB = b.distanceTo(userLat, userLng);
      return distA.compareTo(distB);
    });

    return stations.first.name;
  }

  Future<void> _saveRouteToFavorites(
      String origin, String destination, double fare) async {
    if (_auth.currentUser?.uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to save routes'),
          backgroundColor: Color(0xFFC32E31),
        ),
      );
      return;
    }

    try {
      final routeMap = {
        'segments': [],
        'totalFare': fare,
        'totalDuration': 0,
        'departureTime': 'Now',
        'arrivalTime': 'Later',
        'origin': origin,
        'destination': destination,
      };

      final existingRoutes = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
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

      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('favorite_routes')
          .add({
        'origin': origin,
        'destination': destination,
        'fare': fare,
        'routeData': routeMap,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': _auth.currentUser!.uid,
      });

      final routeId = DateTime.now().millisecondsSinceEpoch.toString();
      await DatabaseHelper().addFavoriteRoute(
        id: routeId,
        userId: _auth.currentUser!.uid,
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
  final VoidCallback? onTap;

  const StationCard({
    super.key,
    required this.imagePath,
    required this.stationName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                    Colors.black.withAlpha(178),
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RedCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint basePaint = Paint()
      ..color = const Color(0xFFB22A2D)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);

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

class StationsListScreen extends StatelessWidget {
  final List<TrotroStation> stations;

  const StationsListScreen({
    super.key,
    required this.stations,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Stations'),
        backgroundColor: const Color(0xFFC32E31),
      ),
      body: ListView.builder(
        itemCount: stations.length,
        itemBuilder: (context, index) {
          final station = stations[index];
          return ListTile(
            title: Text(station.name),
            subtitle: Text(station.description ?? ''),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StationDetailScreen(station: station),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
