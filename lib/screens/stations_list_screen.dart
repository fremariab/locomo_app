// stations_list_screen.dart
import 'package:flutter/material.dart';
import 'package:locomo_app/models/station_model.dart';
import 'package:locomo_app/services/route_service.dart';
import 'package:locomo_app/screens/station_detail_screen.dart';

class StationsListScreen extends StatelessWidget {
  const StationsListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Stations'),
        backgroundColor: const Color(0xFFC32E31),
      ),
      body: FutureBuilder<List<TrotroStation>>(
        future: RouteService.getAllStationsAndStops(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final stations = snapshot.data ?? [];
          
          return ListView.builder(
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
          );
        },
      ),
    );
  }
}