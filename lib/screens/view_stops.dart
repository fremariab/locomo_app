// This screen shows all the bus stops in the system
// We can see their names, locations, and which stations they're near
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewStopsScreen extends StatelessWidget {
  const ViewStopsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Stops'),
        backgroundColor: const Color(0xFFC32E31),
      ),
      // Get live updates of stops from Firebase
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('stops').snapshots(),
        builder: (context, snapshot) {
          // Show loading spinner while getting data
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          // Show message if no stops found
          if (docs.isEmpty) {
            return const Center(child: Text('No stops found'));
          }

          // Show each stop in a list
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final stop = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;

              return ListTile(
                title: Text(stop['name'] ?? 'Unnamed Stop'),
                subtitle: Text(
                  "Lat: ${stop['coordinates']['lat']}, Lng: ${stop['coordinates']['lng']}\nNearby Station: ${stop['nearbyStationId']}"
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      onPressed: () => _editStopDialog(context, docId, stop),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteStop(context, docId),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Ask user if they really want to delete a stop
  void _deleteStop(BuildContext context, String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Stop'),
        content: const Text('Are you sure you want to delete this stop?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    // If user confirms, delete the stop from Firebase
    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('stops').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stop deleted.')));
    }
  }

  // Show a dialog to edit a stop's details
  void _editStopDialog(BuildContext context, String docId, Map<String, dynamic> stop) {
    // Create controllers with the current stop data
    final nameController = TextEditingController(text: stop['name']);
    final latController = TextEditingController(text: stop['coordinates']['lat'].toString());
    final lngController = TextEditingController(text: stop['coordinates']['lng'].toString());
    final stationController = TextEditingController(text: stop['nearbyStationId']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Stop'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _inputField('Name', nameController),
              _inputField('Latitude', latController, isNumber: true),
              _inputField('Longitude', lngController, isNumber: true),
              _inputField('Nearby Station ID', stationController),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              // Save the updated stop data to Firebase
              await FirebaseFirestore.instance.collection('stops').doc(docId).update({
                'name': nameController.text.trim(),
                'coordinates.lat': double.tryParse(latController.text) ?? 0.0,
                'coordinates.lng': double.tryParse(lngController.text) ?? 0.0,
                'nearbyStationId': stationController.text.trim(),
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stop updated.')));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Helper function to create text input fields
  Widget _inputField(String label, TextEditingController controller, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
