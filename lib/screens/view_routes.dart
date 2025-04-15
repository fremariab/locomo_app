// This screen shows all the train routes in the system
// We can see where each route starts, ends, and what stops it has
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewRoutesScreen extends StatelessWidget {
  const ViewRoutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Routes'),
        backgroundColor: const Color(0xFFC32E31),
      ),
      // Get live updates of routes from Firebase
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('routes').snapshots(),
        builder: (context, snapshot) {
          // Show loading spinner while getting data
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          // Show message if no routes found
          if (docs.isEmpty) {
            return const Center(child: Text('No routes found'));
          }

          // Show each route in a list
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final route = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;

              return ListTile(
                title: Text(route['routeName'] ?? 'Unnamed Route'),
                subtitle: Text(
                  'From: ${route['origin']} → ${route['destination']}\nStops: ${(route['stops'] as List).join(', ')}\nFare: ${route['fare'] ?? 'N/A'}'
                ),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteRoute(context, docId),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Ask user if they really want to delete a route
  void _deleteRoute(BuildContext context, String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Route'),
        content: const Text('Are you sure you want to delete this route?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    // If user confirms, delete the route from Firebase
    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('routes').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Route deleted.')));
    }
  }
}
