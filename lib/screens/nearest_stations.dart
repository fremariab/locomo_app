import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:locomo_app/widgets/MainScaffold.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:locomo_app/services/firebase_service.dart';
import 'package:locomo_app/services/location_service.dart';
import 'package:locomo_app/services/map_downloader.dart';
import 'dart:io' show Platform;
import 'package:latlong2/latlong.dart' as ll;

class NearestStationsScreen extends StatefulWidget {
  const NearestStationsScreen({Key? key}) : super(key: key);

  @override
  NearestStationsScreenState createState() => NearestStationsScreenState();
}

class NearestStationsScreenState extends State<NearestStationsScreen> {
  // Define colors inline
  static const Color primaryRed = Color(0xFFC33939);
  static const Color white = Colors.white;
  static const Color lightGrey = Color(0xFFEEEEEE);
  static const Color darkGrey = Color(0xFF616161);
  static const Color iconGrey = Color(0xFF757575);
  static const Color textPrimary = Colors.black87;

  // Define text styles inline
  static const TextStyle subheading = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  // Google Maps controller
  final Completer<GoogleMapController> _controller = Completer();

  // Current location
  loc.LocationData? _currentLocation;
  final loc.Location _locationService = loc.Location();

  // Map camera position
  CameraPosition? _initialCameraPosition;

  Future<void> _initializeCameraPosition() async {
    await _getCurrentLocation(); // update _currentLocation

    if (_currentLocation != null) {
      _initialCameraPosition = CameraPosition(
        target:
            LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
        zoom: 15,
      );
    }
  }

  // Markers for stations
  final Set<Marker> _markers = {};

  // For directions
  Set<Polyline> _polylines = {};
  List<LatLng> _directionPoints = [];

  // For offline map
  bool _isMapDownloading = false;
  bool _isOfflineMode = false;

  // Reference to Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Google Maps API key
  String? _mapsApiKey;

  @override
  void initState() {
    super.initState();
    _mapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];

    // Initialize location first, then camera
    _initLocationService().then((_) async {
      await _getCurrentLocation(); // Ensure we have location
      if (_currentLocation != null) {
        setState(() {
          _initialCameraPosition = CameraPosition(
            target: LatLng(
                _currentLocation!.latitude!, _currentLocation!.longitude!),
            zoom: 15,
          );
        });
        _loadStationsFromFirestore();
      }
    });
  }

  // Initialize location services and check permissions
  Future<void> _initLocationService() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      status = await Permission.location.request();
      if (!status.isGranted) {
        _showPermissionDeniedDialog();
        return;
      }
    }

    // Enable location services
    bool serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationService.requestService();
      if (!serviceEnabled) {
        _showPermissionDeniedDialog();
        return;
      }
    }

    _locationService.changeSettings(
      accuracy: loc.LocationAccuracy.high,
      interval: 10000,
    );

    // Listen to location updates
    _locationService.onLocationChanged.listen((loc.LocationData location) {
      if (mounted) {
        setState(() {
          _currentLocation = location;
          _updateCurrentLocationMarker();
        });
      }
    });

    // Get initial location
    await _getCurrentLocation();
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    try {
      var status = await Permission.location.status;
      if (!status.isGranted) {
        status = await Permission.location.request();
        if (!status.isGranted) {
          _showPermissionDeniedDialog();
          return;
        }
      }

      var location = await _locationService.getLocation();

      if (mounted &&
          location != null &&
          location.latitude != null &&
          location.longitude != null) {
        setState(() {
          _currentLocation = location;

          // Also update the initial camera position to prevent default to Google HQ
          _initialCameraPosition = CameraPosition(
            target: LatLng(location.latitude!, location.longitude!),
            zoom: 15,
          );

          // Move camera to current location
          _moveCameraToCurrentLocation();

          // Update markers
          _updateCurrentLocationMarker();
        });
      } else {
        print("Invalid location data received");
      }
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  // Move camera to current location
  Future<void> _moveCameraToCurrentLocation() async {
    try {
      // First get fresh location
      await _getCurrentLocation();

      if (_currentLocation == null ||
          _currentLocation!.latitude == null ||
          _currentLocation!.longitude == null) {
        print("Invalid location data");
        return;
      }

      final GoogleMapController controller = await _controller.future;

      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
                _currentLocation!.latitude!, _currentLocation!.longitude!),
            zoom: 15,
          ),
        ),
      );

      // Update the current location marker
      _updateCurrentLocationMarker();
    } catch (e) {
      print("Error moving camera: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't update location: ${e.toString()}")),
      );
    }
  }

  Future<void> _findNearbyStations() async {
    try {
      print("_findNearbyStations() called");
      _showLoadingDialog('Finding nearby stations...');

      final locData = await LocationService.instance.getCurrentLocation();
      print("Current location: ${locData?.latitude}, ${locData?.longitude}");

      if (locData == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to get current location')),
        );
        return;
      }

      final nearbyStations = await FirebaseService().getNearbyStations(
        locData.latitude!,
        locData.longitude!,
        1000.0,
      );

      print("Nearby stations count: ${nearbyStations.length}");
      Navigator.pop(context);

      if (nearbyStations.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No stations found nearby')),
        );
        return;
      }

      // Clear existing markers except current location
      setState(() {
        _markers.removeWhere(
            (marker) => marker.markerId.value != 'current_location');
      });

      // Add markers for nearby stations
      for (var station in nearbyStations) {
        LatLng? position;

        if (station['coordinates'] is Map) {
          position = LatLng(
            station['coordinates']['lat'],
            station['coordinates']['lng'],
          );
        } else if (station['location'] is GeoPoint) {
          final geo = station['location'] as GeoPoint;
          position = LatLng(geo.latitude, geo.longitude);
        } else if (station.containsKey('lat') && station.containsKey('lng')) {
          position = LatLng(station['lat'], station['lng']);
        }

        if (position == null) continue;

        final marker = Marker(
          markerId: MarkerId(station['id']),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: station['name'] ?? 'Unknown Station',
            snippet: '${station['distance']?.toStringAsFixed(2)} km away',
          ),
        );

        setState(() {
          _markers.add(marker);
        });
      }

      // Zoom to show all markers
      await _fitBoundsForNearestStations(
          nearbyStations, LatLng(locData.latitude!, locData.longitude!));
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      print("Error finding nearby stations: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error finding nearby stations')),
      );
    }
  }

// In NearestStationsScreen
  Future<void> _downloadMapAsPdf() async {
    final scaffold = ScaffoldMessenger.of(context);

    try {
      // 1. Check permissions
      if (!await _checkStoragePermission()) return;

      // 2. Get location if needed
      if (_currentLocation == null) {
        await _getCurrentLocation();
        if (_currentLocation == null) {
          throw Exception('Could not get current location');
        }
      }

      // 3. Download with progress
      _showLoadingDialog('Downloading map...');
      final path = await MapDownloader.downloadMapForLocation(
        location: ll.LatLng(
            _currentLocation!.latitude!, _currentLocation!.longitude!),
        fileName: 'trotro_map',
        radius: 300.0,
        minZoom: 12,
        maxZoom: 13,
      );

      // 4. Show result
      Navigator.pop(context); // Dismiss loading
      _showDownloadSuccess(path);
    } catch (e) {
      Navigator.pop(context); // Dismiss loading if still showing
      _showDownloadError(e.toString());
    }
  }

// Helper methods
  Future<bool> _checkStoragePermission() async {
    if (!Platform.isAndroid) return true;

    if (await Permission.manageExternalStorage.isGranted) return true;

    var status = await Permission.manageExternalStorage.request();
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }

    return false;
  }

  void _showDownloadSuccess(String path) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Map saved to:\n${path.split('/').last}'),
        duration: Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OPEN',
          onPressed: () => OpenFile.open(path),
        ),
      ),
    );
  }

  void _showDownloadError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Download failed: $error')),
    );
    debugPrint('Download error: $error');
  }

// Update current location marker
  void _updateCurrentLocationMarker() async {
    if (_currentLocation != null) {
      final currentLocationMarker = Marker(
        markerId: const MarkerId('current_location'),
        position:
            LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
        // Use a built-in marker with a blue hue
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Your Location'),
      );

      setState(() {
        // Remove previous current location marker if exists
        _markers.removeWhere(
            (marker) => marker.markerId.value == 'current_location');

        // Add the new marker
        _markers.add(currentLocationMarker);
      });
    }
  }

  Future<bool> _checkAndRequestPermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) return true;

      var status = await Permission.manageExternalStorage.request();
      if (status.isGranted) return true;

      if (status.isPermanentlyDenied) {
        await openAppSettings();
      }

      return false;
    }
    return true; // iOS and others
  }

  // Load stations from Firestore
  Future<void> _loadStationsFromFirestore() async {
    try {
      final stationsSnapshot =
          await _firestore.collection('trotro_stations').get();

      // Clear existing markers except current location
      _markers
          .removeWhere((marker) => marker.markerId.value != 'current_location');

      for (var doc in stationsSnapshot.docs) {
        final data = doc.data();
        LatLng? position;

        // Handle all coordinate formats
        if (data['coordinates'] is Map) {
          position = LatLng(
            data['coordinates']['lat'],
            data['coordinates']['lng'],
          );
        } else if (data['location'] is GeoPoint) {
          final geo = data['location'] as GeoPoint;
          position = LatLng(geo.latitude, geo.longitude);
        } else if (data.containsKey('lat') && data.containsKey('lng')) {
          position = LatLng(data['lat'], data['lng']);
        }

        if (position == null) continue;

        final marker = Marker(
          markerId: MarkerId(doc.id),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: data['name'] ?? 'Unknown Station',
            snippet: data['description'] ?? 'Trotro Station',
          ),
          onTap: () {
            if (_currentLocation != null) {
              _getDirectionsToStation(
                LatLng(
                    _currentLocation!.latitude!, _currentLocation!.longitude!),
                position!,
              );
            }
          },
        );

        setState(() {
          _markers.add(marker);
        });
      }
    } catch (e) {
      print("Error loading stations: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading stations: ${e.toString()}')),
      );
    }
  }

  // Get station marker icon
  Future<BitmapDescriptor> _getStationMarkerIcon() async {
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  }

  // Helper method to convert asset image to bytes for custom marker
  Future<Uint8List> _getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    return data.buffer.asUint8List();
  }

  // Show station details modal
  void _showStationDetails(String stationId, Map<String, dynamic> stationData) {
    // Get coordinates based on the data structure
    double latitude, longitude;
    if (stationData.containsKey('lat') && stationData.containsKey('lng')) {
      latitude = stationData['lat'];
      longitude = stationData['lng'];
    } else if (stationData.containsKey('coordinates')) {
      final coordinates = stationData['coordinates'];
      latitude = coordinates['lat'];
      longitude = coordinates['lng'];
    } else if (stationData.containsKey('location') &&
        stationData['location'] is GeoPoint) {
      final GeoPoint location = stationData['location'];
      latitude = location.latitude;
      longitude = location.longitude;
    } else {
      // Default to Accra if location is missing
      latitude = 5.6037;
      longitude = -0.1870;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stationData['name'] ?? 'Unknown Station',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              stationData['description'] ?? 'Trotro Station',
              style: const TextStyle(color: darkGrey),
            ),
            const SizedBox(height: 16),
            if (stationData['routes'] != null) ...[
              const Text('Available Routes:', style: subheading),
              const SizedBox(height: 8),
              ...List.generate(
                (stationData['routes'] as List).length,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_bus,
                          color: iconGrey, size: 16),
                      const SizedBox(width: 8),
                      Text(stationData['routes'][index]),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Get directions to this station
                  if (_currentLocation != null) {
                    Navigator.pop(context);
                    _getDirectionsToStation(
                      LatLng(_currentLocation!.latitude!,
                          _currentLocation!.longitude!),
                      LatLng(latitude, longitude),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Unable to get current location')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryRed,
                  foregroundColor: white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Get Directions'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Get directions to a station - Using custom implementation instead of the library
  Future<void> _getDirectionsToStation(
      LatLng origin, LatLng destination) async {
    try {
      setState(() {
        // Clear previous directions
        _polylines.clear();
      });

      // Show loading indicator
      // _showLoadingDialog('Getting directions...');

      if (_mapsApiKey == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Maps API key not configured')),
        );
        return;
      }

      // Get directions using Google Directions API directly
      final String url = 'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&mode=driving'
          '&key=$_mapsApiKey';

      final response = await http.get(Uri.parse(url));

      // Hide loading dialog
      Navigator.pop(context);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == 'OK') {
          // Get route
          final route = data['routes'][0];

          // Get encoded polyline
          final encodedPolyline = route['overview_polyline']['points'];

          // Decode polyline points
          final points = _decodePolyline(encodedPolyline);

          // Create polyline
          final polyline = Polyline(
            polylineId: const PolylineId('route'),
            color: primaryRed,
            points: points,
            width: 5,
          );

          setState(() {
            _polylines.add(polyline);
            _directionPoints = points;
          });

          // Adjust camera to show the entire route
          _fitPolylineIntoMap(points);

          // Show route information
          final distance = route['legs'][0]['distance']['text'];
          final duration = route['legs'][0]['duration']['text'];

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Distance: $distance • Duration: $duration')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Could not find directions to this station')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      // Hide loading dialog if showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      print("Error getting directions: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error getting directions')),
      );
    }
  }

  // Decode polyline points
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

      double latitude = lat / 1E5;
      double longitude = lng / 1E5;
      points.add(LatLng(latitude, longitude));
    }
    return points;
  }

  // Fit polyline into map view
  Future<void> _fitPolylineIntoMap(List<LatLng> points) async {
    if (points.isEmpty) return;

    double minLat = points[0].latitude;
    double maxLat = points[0].latitude;
    double minLng = points[0].longitude;
    double maxLng = points[0].longitude;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final GoogleMapController controller = await _controller.future;

    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100, // padding
      ),
    );
  }

  // Get and parse JSON
  Future<Map<String, dynamic>> _getJsonFromApi(String url) async {
    final response = await http.get(Uri.parse(url));
    return json.decode(response.body);
  }

  // Show nearest stations
  Future<void> _showNearestStations() async {
    if (_currentLocation == null) {
      await _getCurrentLocation();
      if (_currentLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to get current location')),
        );
        return;
      }
    }

    try {
      _showLoadingDialog('Finding nearest stations...');

      // Get current location
      final currentLatLng = LatLng(
        _currentLocation!.latitude!,
        _currentLocation!.longitude!,
      );

      // Query Firestore for stations
      final stationsSnapshot =
          await _firestore.collection('trotro_stations').get();

      // Calculate distance to each station
      List<Map<String, dynamic>> stationsWithDistance = [];

      for (var doc in stationsSnapshot.docs) {
        final data = doc.data();

        // Extract station coordinates based on the data structure
        double stationLat, stationLng;

        if (data.containsKey('lat') && data.containsKey('lng')) {
          stationLat = data['lat'];
          stationLng = data['lng'];
        } else if (data.containsKey('coordinates')) {
          stationLat = data['coordinates']['lat'];
          stationLng = data['coordinates']['lng'];
        } else if (data.containsKey('location') &&
            data['location'] is GeoPoint) {
          final GeoPoint location = data['location'];
          stationLat = location.latitude;
          stationLng = location.longitude;
        } else {
          continue; // Skip stations with invalid coordinates
        }

        // Calculate distance
        final distance = Geolocator.distanceBetween(
          currentLatLng.latitude,
          currentLatLng.longitude,
          stationLat,
          stationLng,
        );

        stationsWithDistance.add({
          'id': doc.id,
          'data': data,
          'distance': distance,
          'location': LatLng(stationLat, stationLng),
        });
      }

      // Sort by distance
      stationsWithDistance.sort((a, b) =>
          (a['distance'] as double).compareTo(b['distance'] as double));

      // Take the nearest 5 stations
      final nearestStations = stationsWithDistance.take(5).toList();

      // Hide loading dialog
      Navigator.pop(context);

      if (nearestStations.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No stations found nearby')),
        );
        return;
      }

      // Highlight nearest stations
      setState(() {
        // Clear previous polylines
        _polylines.clear();

        // Update markers to highlight nearest stations
        _markers.removeWhere((marker) =>
            marker.markerId.value != 'current_location' &&
            !nearestStations
                .any((station) => station['id'] == marker.markerId.value));
      });

      // Fit map bounds to show all nearest stations and current location
      await _fitBoundsForNearestStations(nearestStations, currentLatLng);

      // Show bottom sheet with list of nearest stations
      _showNearestStationsBottomSheet(nearestStations);
    } catch (e) {
      // Hide loading dialog if showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      print("Error finding nearest stations: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error finding nearest stations')),
      );
    }
  }

  // Fit map bounds to show nearest stations

  Future<void> _fitBoundsForNearestStations(
      List<Map<String, dynamic>> stations, LatLng currentLocation) async {
    if (stations.isEmpty) return;

    final GoogleMapController controller = await _controller.future;

    // Create list of points to include in bounds
    List<LatLng> points = [currentLocation];

    for (var station in stations) {
      LatLng? position;

      if (station['coordinates'] is Map) {
        position = LatLng(
          station['coordinates']['lat'],
          station['coordinates']['lng'],
        );
      } else if (station['location'] is GeoPoint) {
        final geo = station['location'] as GeoPoint;
        position = LatLng(geo.latitude, geo.longitude);
      } else if (station.containsKey('lat') && station.containsKey('lng')) {
        position = LatLng(station['lat'], station['lng']);
      }

      if (position != null) {
        points.add(position);
      }
    }

    // Calculate bounds from points
    double minLat = points[0].latitude;
    double maxLat = points[0].latitude;
    double minLng = points[0].longitude;
    double maxLng = points[0].longitude;

    for (final point in points) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    final bounds = LatLngBounds(
      northeast: LatLng(maxLat, maxLng),
      southwest: LatLng(minLat, minLng),
    );

    controller.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100), // 100px padding
    );
  }

  // Show bottom sheet with list of nearest stations
  void _showNearestStationsBottomSheet(List<Map<String, dynamic>> stations) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Text(
                      'Nearest Trotro Stations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${stations.length} found',
                      style: const TextStyle(color: darkGrey),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: stations.length,
                  itemBuilder: (context, index) {
                    final station = stations[index];
                    final data = station['data'] as Map<String, dynamic>;
                    final distance =
                        (station['distance'] as double) / 1000; // Convert to km

                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: lightGrey,
                        child: Icon(Icons.train, color: primaryRed),
                      ),
                      title: Text(data['name'] ?? 'Unknown Station',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${distance.toStringAsFixed(2)} km away'),
                      trailing: IconButton(
                        icon: const Icon(Icons.directions, color: primaryRed),
                        onPressed: () {
                          Navigator.pop(context);
                          // Get directions to this station
                          if (_currentLocation != null) {
                            final location = station['location'] as LatLng;
                            _getDirectionsToStation(
                              LatLng(_currentLocation!.latitude!,
                                  _currentLocation!.longitude!),
                              location,
                            );
                          }
                        },
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        // Show station details
                        _showStationDetails(station['id'], data);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Download map for offline use
  Future<void> _downloadOfflineMap() async {
    try {
      if (_currentLocation == null) {
        await _getCurrentLocation();
        if (_currentLocation == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to get current location')),
          );
          return;
        }
      }

      setState(() {
        _isMapDownloading = true;
      });

      // Show downloading dialog
      _showLoadingDialog('Downloading map for offline use...');

      // Here you would integrate with a map tile downloader or Google Maps offline API
      // For this example, we'll simulate downloading by caching some essential assets

      // Cache map tiles for this region (would require a real map tile provider)
      await Future.delayed(const Duration(seconds: 3));

      // Cache station data from Firestore
      final stationsSnapshot =
          await _firestore.collection('trotro_stations').get();
      final List<Map<String, dynamic>> stationData = [];

      for (var doc in stationsSnapshot.docs) {
        stationData.add({
          'id': doc.id,
          ...doc.data(),
        });
      }

      // Store station data in local storage
      // In a real app, use shared_preferences, hive, or another local storage solution
      // For this example, we'll use the cache manager to store a JSON file

      final cacheManager = DefaultCacheManager();
      await cacheManager.putFile(
        'offline_stations.json',
        Uint8List.fromList(stationData.toString().codeUnits),
        key: 'offline_stations.json',
        fileExtension: 'json',
      );

      // Hide loading dialog
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      setState(() {
        _isMapDownloading = false;
        _isOfflineMode = true; // Automatically switch to offline mode
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Map downloaded for offline use')),
      );
    } catch (e) {
      // Hide loading dialog if showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      setState(() {
        _isMapDownloading = false;
      });

      print("Error downloading offline map: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error downloading offline map')),
      );
    }
  }

  // Toggle offline mode
  void _toggleOfflineMode() {
    setState(() {
      _isOfflineMode = !_isOfflineMode;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            _isOfflineMode ? 'Offline mode enabled' : 'Online mode enabled'),
      ),
    );

    // If switching to online mode, refresh data
    if (!_isOfflineMode) {
      _loadStationsFromFirestore();
    }
  }

  void _showPermissionDeniedSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Storage permission required to download maps'),
        action: SnackBarAction(
          label: 'SETTINGS',
          onPressed: () => openAppSettings(),
        ),
      ),
    );
  }

  // Show location permission denied dialog
  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
            'This app needs location permission to show your position on the map and find nearby stations.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryRed,
              foregroundColor: white,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // Show loading dialog
  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryRed),
            ),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  // Zoom in method for map
  Future<void> _zoomIn() async {
    if (_controller.isCompleted) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.zoomIn());
    }
  }

  // Zoom out method for map
  Future<void> _zoomOut() async {
    if (_controller.isCompleted) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.zoomOut());
    }
  }

  // Scale bar widget
  Widget _buildScaleBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 2,
            color: darkGrey,
          ),
          const SizedBox(width: 4),
          const Text(
            '200m',
            style: TextStyle(fontSize: 10, color: darkGrey),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (_controller.isCompleted) {
      _controller.future.then((controller) => controller.dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 1, // Index for "Explore"
      child: SafeArea(
        child: Column(
          children: [
            // Custom app bar
            Container(
              color: primaryRed,
              padding: const EdgeInsets.only(
                bottom: 16.0,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Explore',
                        style: TextStyle(
                          color: white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Spacer to balance layout
                ],
              ),
            ),

            // Map section
            Expanded(
              child: Stack(
                children: [
                  // Google Map
                  GoogleMap(
                    initialCameraPosition: _initialCameraPosition ??
                        const CameraPosition(
                          target: LatLng(0, 0),
                          zoom: 2,
                        ),
                    onMapCreated: (GoogleMapController controller) {
                      _controller.complete(controller);
                      if (_currentLocation != null) {
                        controller.animateCamera(CameraUpdate.newLatLng(
                          LatLng(_currentLocation!.latitude!,
                              _currentLocation!.longitude!),
                        ));
                      }
                    },
                    markers: _markers,
                    polylines: _polylines,
                    myLocationEnabled: false, // We're handling this manually
                    zoomControlsEnabled: false,
                    zoomGesturesEnabled: true, // Make sure this is enabled
                    scrollGesturesEnabled: true, // Enable panning
                    rotateGesturesEnabled: true, // Enable rotation
                    tiltGesturesEnabled: true, // Enable tilting
                    mapType: MapType.normal,
                    // Handle offline mode
                    indoorViewEnabled: !_isOfflineMode,
                    trafficEnabled: !_isOfflineMode,
                    buildingsEnabled: !_isOfflineMode,
                  ),
                  // Floating location button
                  Positioned(
                    bottom: 100,
                    right: 16,
                    child: FloatingActionButton(
                      backgroundColor: white,
                      elevation: 2,
                      onPressed: () async {
                        // Show loading indicator
                        final scaffold = ScaffoldMessenger.of(context);
                        scaffold.showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(width: 10),
                                Text("Updating location..."),
                              ],
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );

                        await _moveCameraToCurrentLocation();
                      },
                      child: const Icon(Icons.my_location, color: darkGrey),
                    ),
                  ),
                  // Zoom controls - NEW
                  Positioned(
                    bottom: 170,
                    right: 16,
                    child: Column(
                      children: [
                        FloatingActionButton.small(
                          heroTag: 'zoomIn',
                          backgroundColor: white,
                          elevation: 2,
                          onPressed: _zoomIn,
                          child: const Icon(Icons.add, color: darkGrey),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: 'zoomOut',
                          backgroundColor: white,
                          elevation: 2,
                          onPressed: _zoomOut,
                          child: const Icon(Icons.remove, color: darkGrey),
                        ),
                      ],
                    ),
                  ),

                  Positioned(
                    bottom: 230,
                    left: 16,
                    child: _buildScaleBar(),
                  ),

                  // Bottom buttons
                  // In your Stack widget, replace the existing bottom buttons Positioned widget with this:

                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      top: false,
                      child: Container(
                        color: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  _findNearbyStations();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryRed,
                                  foregroundColor: white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    children: const [
                                      Icon(Icons.train, size: 18),
                                      SizedBox(width: 8),
                                      Text('Trotro Stations Near Me'),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isMapDownloading
                                    ? null
                                    : _downloadMapAsPdf,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: white,
                                  foregroundColor: primaryRed,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    children: const [
                                      Icon(Icons.download, size: 18),
                                      SizedBox(width: 8),
                                      Text("Download Map"),
                                    ],
                                  ),
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
          ],
        ),
      ),
    );
  }
}
