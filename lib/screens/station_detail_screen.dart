import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:locomo_app/models/station_model.dart';

class StationDetailScreen extends StatefulWidget {
  final TrotroStation station;

  const StationDetailScreen({
    Key? key,
    required this.station,
  }) : super(key: key);

  @override
  State<StationDetailScreen> createState() => _StationDetailScreenState();
}

class _StationDetailScreenState extends State<StationDetailScreen> {
  GoogleMapController? _mapController;
  late LatLng _stationLocation;
  final Set<Marker> _markers = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  void _initializeMap() {
    try {
      _stationLocation = LatLng(
        widget.station.latitude,
        widget.station.longitude,
      );

      // Only show the marker for this station
      _markers.add(
        Marker(
          markerId: MarkerId(widget.station.id),
          position: _stationLocation,
          infoWindow: InfoWindow(title: widget.station.name),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize map: ${e.toString()}';
      });
    }
  }

  String _formatStationId(String rawId) {
    return rawId
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.station.name)),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.station.name),
        backgroundColor: const Color(0xFFC32E31),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 300,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _stationLocation,
                zoom: 14,
              ),
              markers: _markers,
              onMapCreated: (controller) {
                _mapController = controller;
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
          ),
          Expanded(
            child: _buildConnectionsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionsList() {
    final connections = widget.station.connections;

    if (connections == null || connections.isEmpty) {
      return const Center(
        child: Text('No connections available'),
      );
    }

    return ListView.builder(
      itemCount: connections.length,
      itemBuilder: (context, index) {
        final connection = connections[index];
        final formattedName =
            _formatStationId(connection['stationId']?.toString() ?? 'Unknown');

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.directions_bus, color: Color(0xFFC32E31)),
            title: Text(formattedName),
            subtitle: Text(
              'Fare: GHS${connection['fare']?.toString() ?? 'N/A'} • '
              '${connection['direct'] == true ? "Direct" : "Transfer"}',
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
