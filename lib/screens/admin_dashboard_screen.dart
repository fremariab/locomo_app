import 'package:flutter/material.dart';
import 'admin_add_station.dart';
import 'admin_add_stop.dart';
import 'admin_add_route.dart';
import 'admin_add_fare.dart';
import 'view_stations.dart';
import 'view_stops.dart';
import 'view_routes.dart';
import 'view_fares.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: const Color(0xFFC32E31),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildButton(context, 'Add Station', const AdminAddStationScreen()),
            _buildButton(context, 'View Stations', const ViewStationsScreen()),
            const SizedBox(height: 12),
            _buildButton(context, 'Add Stop', const AdminAddStopScreen()),
            _buildButton(context, 'View Stops', const ViewStopsScreen()),
            const SizedBox(height: 12),
            _buildButton(context, 'Add Route', const AdminAddRouteScreen()),
            _buildButton(context, 'View Routes', const ViewRoutesScreen()),
            const SizedBox(height: 12),
            _buildButton(context, 'Add Fare', const AdminAddFareScreen()),
            _buildButton(context, 'View Fares', const ViewFaresScreen()),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String label, Widget screen) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFC32E31),
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => screen),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 18,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }
}
