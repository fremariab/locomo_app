import 'package:flutter/material.dart';
import 'package:locomo_app/models/route_model.dart';

class RouteDetailsScreen extends StatelessWidget {
  final RouteModel route;

  const RouteDetailsScreen({Key? key, required this.route}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeaderSection(),
            const Divider(height: 32),
            
            // Transfers Section
            _buildTransfersSection(),
            const Divider(height: 32),
            
            // Price Section
            _buildPriceSection(),
            const Divider(height: 32),
            
            // Timeline Section
            _buildTimelineSection(),
          ],
        ),
      ),
    );
  }
  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fastest',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${route.departureTime} → ${route.duration} → ${route.arrivalTime}',
          style: const TextStyle(fontSize: 16),
        ),
        Text(
          '${route.origin} → ${route.destination}',
          style: const TextStyle(fontSize: 16),
        ),
        if (route.walkingInfo != null) 
          Text(
            'Walk ${route.walkingInfo}',
            style: const TextStyle(fontSize: 16),
          ),
      ],
    );
  }

  Widget _buildTransfersSection() {
    return ExpansionTile(
      title: const Text('Transfers ▼', style: TextStyle(fontSize: 16)),
      children: route.transfers.map((transfer) => ListTile(
        leading: const Icon(Icons.directions_bus),
        title: Text(transfer.description),
        subtitle: Text('${transfer.duration} min'),
      )).toList(),
    );
  }

  Widget _buildPriceSection() {
    return Center(
      child: Text(
        'GHS ${route.price.toStringAsFixed(2)}',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTimelineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trip Timeline',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...route.timeline.map((step) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.circle, size: 12),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.time,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(step.description),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}