// station_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:locomo_app/models/station_model.dart';

class StationDetailScreen extends StatelessWidget {
  final TrotroStation station;

  const StationDetailScreen({Key? key, required this.station}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(station.name),
        backgroundColor: const Color(0xFFC32E31),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (station.imageUrl != null)
              Image.network(
                station.imageUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 16),
            Text(
              station.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (station.description != null)
              Text(
                station.description!,
                style: const TextStyle(fontSize: 16),
              ),
            const SizedBox(height: 16),
            const Text(
              'Available Routes:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (station.routes != null && station.routes!.isNotEmpty)
              ...station.routes!.map((route) => ListTile(
                    title: Text(route),
                    leading: const Icon(Icons.directions_bus),
                  )),
            const SizedBox(height: 16),
            const Text(
              'Facilities:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (station.facilities != null && station.facilities!.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: station.facilities!
                    .map((facility) => Chip(
                          label: Text(facility),
                          backgroundColor: const Color(0xFFC32E31).withOpacity(0.1),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}