import 'dart:async';
import 'dart:convert';
import 'dart:math' show pi, sin, cos, sqrt, atan2;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:locomo_app/widgets/main_scaffold.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:open_file/open_file.dart';
import 'package:locomo_app/services/firebase_service.dart';
import 'package:locomo_app/services/location_service.dart';
import 'package:locomo_app/services/map_downloader.dart';
import 'dart:io' show Platform;
import 'package:latlong2/latlong.dart' as ll;
import 'package:locomo_app/widgets/MainScaffold.dart';


class NearestStationsScreen extends StatefulWidget {
  const NearestStationsScreen({super.key});

  @override
  NearestStationsScreenState createState() => NearestStationsScreenState();
}

class NearestStationsScreenState extends State<NearestStationsScreen> {
  // Define colors inline
  static const Color primaryRed = Color(0xFFC32e21);
  static const Color white = Colors.white;
  static const Color lightGrey = Color(0xFFEEEEEE);
  static const Color darkGrey = Color(0xFF656565);
  static const Color iconGrey = Color(0xFFd9d9d9);
  static const Color textPrimary = Colors.black87;

  // Google Maps controller
  final Completer<GoogleMapController> _controller = Completer();

  // Current location
  loc.LocationData? _currentLocation;
  final loc.Location _locationService = loc.Location();

  // Map camera position
  CameraPosition? _initialCameraPosition;

  // Markers for stations
  final Set<Marker> _markers = {};

  // For directions
  final Set<Polyline> _polylines = {};
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
      await _getCurrentLocation();
      if (_currentLocation != null && mounted) {
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
        if (mounted) _showPermissionDeniedDialog();
        return;
      }
    }

    // Enable location services
    bool serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationService.requestService();
      if (!serviceEnabled) {
        if (mounted) _showPermissionDeniedDialog();
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
          if (mounted) _showPermissionDeniedDialog();
          return;
        }
      }

      var location = await _locationService.getLocation();

      if (mounted && location.latitude != null && location.longitude != null) {
        setState(() {
          _currentLocation = location;
          _initialCameraPosition = CameraPosition(
            target: LatLng(location.latitude!, location.longitude!),
            zoom: 15,
          );
          _moveCameraToCurrentLocation();
          _updateCurrentLocationMarker();
        });
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  // Move camera to current location
  Future<void> _moveCameraToCurrentLocation() async {
    try {
      await _getCurrentLocation();

      if (_currentLocation == null ||
          _currentLocation!.latitude == null ||
          _currentLocation!.longitude == null) {
        debugPrint("Invalid location data");
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

      _updateCurrentLocationMarker();
    } catch (e) {
      debugPrint("Error moving camera: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't update location: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> _findNearbyStations() async {
    try {
      debugPrint("_findNearbyStations() called");
      _showLoadingDialog('Finding nearby stations...');

      final locData = await LocationService.instance.getCurrentLocation();
      debugPrint(
          "Current location: ${locData?.latitude}, ${locData?.longitude}");

      if (locData == null) {
        if (mounted) Navigator.pop(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to get current location')),
          );
        }
        return;
      }

      final nearbyStations = await FirebaseService().getNearbyStations(
        locData.latitude!,
        locData.longitude!,
        1000.0,
      );

      debugPrint("Nearby stations count: ${nearbyStations.length}");
      if (mounted) Navigator.pop(context);

      if (nearbyStations.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No stations found nearby')),
          );
        }
        return;
      }

      // Clear existing markers except current location
      if (mounted) {
        setState(() {
          _markers.removeWhere(
              (marker) => marker.markerId.value != 'current_location');
        });
      }

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

        if (mounted) {
          setState(() {
            _markers.add(marker);
          });
        }
      }

      // Zoom to show all markers
      await _fitBoundsForNearestStations(
          nearbyStations, LatLng(locData.latitude!, locData.longitude!));
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      debugPrint("Error finding nearby stations: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error finding nearby stations')),
        );
      }
    }
  }

  Future<void> _downloadMapAsPdf() async {
    try {
      if (!await _checkStoragePermission()) return;

      setState(() {
        _isMapDownloading = true;
      });

      _showLoadingDialog('Preparing map download...');

      if (_currentLocation == null) {
        await _getCurrentLocation();
        if (_currentLocation == null) {
          if (mounted) Navigator.pop(context);
          throw Exception('Could not get current location');
        }
      }

      // Get nearby stations first
      final nearbyStations = await FirebaseService().getNearbyStations(
        _currentLocation!.latitude!,
        _currentLocation!.longitude!,
        1000.0, // 1km radius
      );

      // Convert to LatLng list
      final stationPoints = nearbyStations.map((station) {
        if (station['coordinates'] is Map) {
          return LatLng(
            station['coordinates']['lat'],
            station['coordinates']['lng'],
          );
        } else if (station['location'] is GeoPoint) {
          final geo = station['location'] as GeoPoint;
          return LatLng(geo.latitude, geo.longitude);
        }
        return LatLng(0, 0); // fallback
      }).toList();

      // Download the map
      final path = await MapDownloader.downloadStationsMap(
        stations: stationPoints,
        fileName: 'trotro_map',
      );

      if (mounted) {
        Navigator.pop(context);
        _showDownloadSuccess(path);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showDownloadError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isMapDownloading = false;
        });
      }
    }
  }

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
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Map downloaded successfully!',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Text('Saved to: ${path.split('/').last}'),
        ],
      ),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: 'OPEN',
        textColor: white,
        onPressed: () => OpenFile.open(path),
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );
}

void _showDownloadError(String error) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Download failed: ${error.split('\n').first}'),
      duration: const Duration(seconds: 5),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );
  debugPrint('Download error: $error');
}
  void _updateCurrentLocationMarker() {
    if (_currentLocation == null) return;

    final currentLocationMarker = Marker(
      markerId: const MarkerId('current_location'),
      position:
          LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      infoWindow: const InfoWindow(title: 'Your Location'),
    );

    if (mounted) {
      setState(() {
        _markers.removeWhere(
            (marker) => marker.markerId.value == 'current_location');
        _markers.add(currentLocationMarker);
      });
    }
  }

  Future<void> _loadStationsFromFirestore() async {
    try {
      final stationsSnapshot = await _firestore.collection('stations').get();

      // Clear existing markers except current location
      if (mounted) {
        setState(() {
          _markers.removeWhere(
              (marker) => marker.markerId.value != 'current_location');
        });
      }

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

        if (mounted) {
          setState(() {
            _markers.add(marker);
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading stations: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading stations: ${e.toString()}')),
        );
      }
    }
  }

  void _showStationDetails(String stationId, Map<String, dynamic> stationData) {
    if (!mounted) return;

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
              const Text('Available Routes:',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  )),
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

  Future<void> _getDirectionsToStation(
      LatLng origin, LatLng destination) async {
    try {
      if (mounted) {
        setState(() {
          _polylines.clear();
        });
      }

      if (_mapsApiKey == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google Maps API key not configured')),
          );
        }
        return;
      }

      final String url = 'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&mode=driving'
          '&key=$_mapsApiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final route = data['routes'][0];
          final encodedPolyline = route['overview_polyline']['points'];
          final points = _decodePolyline(encodedPolyline);

          final polyline = Polyline(
            polylineId: const PolylineId('route'),
            color: primaryRed,
            points: points,
            width: 5,
          );

          if (mounted) {
            setState(() {
              _polylines.add(polyline);
              _directionPoints = points;
            });
          }

          _fitPolylineIntoMap(points);

          final distance = route['legs'][0]['distance']['text'];
          final duration = route['legs'][0]['duration']['text'];

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Distance: $distance • Duration: $duration')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Could not find directions to this station')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      debugPrint("Error getting directions: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error getting directions')),
        );
      }
    }
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

      double latitude = lat / 1E5;
      double longitude = lng / 1E5;
      points.add(LatLng(latitude, longitude));
    }
    return points;
  }

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
        100,
      ),
    );
  }

  Future<void> _fitBoundsForNearestStations(
      List<Map<String, dynamic>> stations, LatLng currentLocation) async {
    if (stations.isEmpty) return;

    final GoogleMapController controller = await _controller.future;
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
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  void _showPermissionDeniedDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
            'This app needs location permission to show your position on the map and find nearby stations.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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

  void _showLoadingDialog(String message) {
  if (!mounted) return;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryRed),
          ),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
  Future<void> _zoomIn() async {
    if (_controller.isCompleted) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.zoomIn());
    }
  }

  Future<void> _zoomOut() async {
    if (_controller.isCompleted) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.zoomOut());
    }
  }

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
      currentIndex: 1,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              color: primaryRed,
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    
                    child: Center(
                      child: const Text(
                        'Explore',
                        style: TextStyle(
                          color: white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
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
                    myLocationEnabled: false,
                    zoomControlsEnabled: false,
                    zoomGesturesEnabled: true,
                    scrollGesturesEnabled: true,
                    rotateGesturesEnabled: true,
                    tiltGesturesEnabled: true,
                    mapType: MapType.normal,
                    indoorViewEnabled: !_isOfflineMode,
                    trafficEnabled: !_isOfflineMode,
                    buildingsEnabled: !_isOfflineMode,
                  ),
                  Positioned(
                    bottom: 100,
                    right: 16,
                    child: FloatingActionButton(
                      backgroundColor: white,
                      elevation: 2,
                      onPressed: _moveCameraToCurrentLocation,
                      child: const Icon(Icons.my_location, color: darkGrey),
                    ),
                  ),
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
                                onPressed: _findNearbyStations,
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
                                child: _isMapDownloading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  primaryRed),
                                        ),
                                      )
                                    : FittedBox(
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
