// This screen shows all the train stations in the system
// We can see their names, locations, and which region they're in
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewStationsScreen extends StatelessWidget {
  const ViewStationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Stations'),
        backgroundColor: const Color(0xFFC32E31),
      ),
      // Get live updates of stations from Firebase
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('stations').snapshots(),
        builder: (context, snapshot) {
          // Show loading spinner while getting data
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          // Show message if no stations found
          if (docs.isEmpty) {
            return const Center(child: Text('No stations found'));
          }

          // Show each station in a list
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final station = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;

              return ListTile(
                title: Text(station['name'] ?? 'Unnamed'),
                subtitle: Text("Lat: ${station['coordinates']['lat']}, Lng: ${station['coordinates']['lng']}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      onPressed: () => _editStationDialog(context, docId, station),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteStation(context, docId),
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

  // Ask user if they really want to delete a station
  void _deleteStation(BuildContext context, String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Station'),
        content: const Text('Are you sure you want to delete this station?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    // If user confirms, delete the station from Firebase
    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('stations').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Station deleted.')));
    }
  }

  // Show a dialog to edit a station's details
  void _editStationDialog(BuildContext context, String docId, Map<String, dynamic> station) {
    // Create controllers with the current station data
    final nameController = TextEditingController(text: station['name']);
    final latController = TextEditingController(text: station['coordinates']['lat'].toString());
    final lngController = TextEditingController(text: station['coordinates']['lng'].toString());
    final regionController = TextEditingController(text: station['region']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Station'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _inputField('Name', nameController),
              _inputField('Latitude', latController, isNumber: true),
              _inputField('Longitude', lngController, isNumber: true),
              _inputField('Region', regionController),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              // Save the updated station data to Firebase
              await FirebaseFirestore.instance.collection('stations').doc(docId).update({
                'name': nameController.text.trim(),
                'coordinates.lat': double.tryParse(latController.text) ?? 0.0,
                'coordinates.lng': double.tryParse(lngController.text) ?? 0.0,
                'region': regionController.text.trim(),
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Station updated.')));
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
