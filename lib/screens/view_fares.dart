// This screen shows all the train fares in the system
// We can see both station-to-station and stop-to-stop fares
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewFaresScreen extends StatelessWidget {
  const ViewFaresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('All Fares'),
          backgroundColor: const Color(0xFFC32E31),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Station → Station'),
              Tab(text: 'Stop → Stop'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _FareList(fareType: 'station_to_station'),
            _FareList(fareType: 'stop_to_stop'),
          ],
        ),
      ),
    );
  }
}

// This widget shows a list of fares for either stations or stops
class _FareList extends StatelessWidget {
  final String fareType;

  const _FareList({required this.fareType});

  @override
  Widget build(BuildContext context) {
    // Get the fares from Firebase
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('fares').doc(fareType).get(),
      builder: (context, snapshot) {
        // Show loading spinner while getting data
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;

        // Show message if no fares found
        if (data == null || data.isEmpty) {
          return const Center(child: Text('No fares found.'));
        }

        final fareKeys = data.keys.toList();

        // Show each fare in a list
        return ListView.separated(
          itemCount: fareKeys.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final key = fareKeys[index];
            final fare = data[key];

            return ListTile(
              title: Text(key.replaceAll('_', ' → ')),
              subtitle: Text('Fare: GHS ${fare.toString()}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteFare(context, key),
              ),
            );
          },
        );
      },
    );
  }

  // Ask user if they really want to delete a fare
  void _deleteFare(BuildContext context, String key) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Fare'),
        content: Text('Are you sure you want to delete fare for "$key"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    // If user confirms, delete the fare from Firebase
    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('fares').doc(fareType).update({key: FieldValue.delete()});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fare for "$key" deleted.')),
      );
    }
  }
}
