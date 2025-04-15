import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:locomo_app/screens/nearest_stations.dart';
import 'package:locomo_app/screens/faqs.dart';
import 'package:locomo_app/screens/user_profile.dart';
import 'package:locomo_app/screens/search.dart';
import 'package:locomo_app/screens/trip_details.dart';
import 'package:locomo_app/widgets/MainScaffold.dart';
import 'package:locomo_app/services/database_helper.dart';
import 'package:locomo_app/services/connectivity_service.dart';
import 'package:locomo_app/models/route.dart';

class SavedLocationsScreen extends StatefulWidget {
  const SavedLocationsScreen({Key? key}) : super(key: key);

  @override
  _SavedLocationsScreenState createState() => _SavedLocationsScreenState();
}

class _SavedLocationsScreenState extends State<SavedLocationsScreen> {
  int _currentIndex = 1;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _favoriteRoutes = [];
  bool _isOnline = true;

  // Colors
  static const Color primaryRed = Color(0xFFC32E31);
  static const Color white = Colors.white;
  static const Color darkGrey = Color(0xFF656565);
  static const Color lightGrey = Color(0xFFD9D9D9);
  static const Color iconGrey = Color(0xFF656565);
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.black54;

  // Styles
  static const TextStyle subheading = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12.0,
    color: textSecondary,
  );

  // Get the current user's ID
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadFavoriteRoutes();
    
    // Listen for connectivity changes
    ConnectivityService().connectivityStream.listen((isOnline) {
      setState(() {
        _isOnline = isOnline;
      });
      
      // If we're back online, sync any unsynced routes
      if (_isOnline) {
        _syncUnsyncedRoutes();
      }
    });
  }

  // Check if we're online
  Future<void> _checkConnectivity() async {
    final isConnected = await ConnectivityService().isConnected();
    setState(() {
      _isOnline = isConnected;
    });
  }

  // Load favorite routes from local database and Firestore
  Future<void> _loadFavoriteRoutes() async {
    if (currentUserId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // First, load from local database
      final localRoutes = await DatabaseHelper().getFavoriteRoutes(currentUserId!);
      
      setState(() {
        _favoriteRoutes = localRoutes;
        _isLoading = false;
      });
      
      // If we're online, also load from Firestore and merge
      if (_isOnline) {
        final snapshot = await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('favorite_routes')
            .orderBy('createdAt', descending: true)
            .get();

        final firestoreRoutes = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'origin': data['origin'] ?? '',
            'destination': data['destination'] ?? '',
            'fare': data['fare'] ?? 0.0,
            'createdAt': data['createdAt'],
            'synced': 1,
          };
        }).toList();
        
        // Merge Firestore routes with local routes, avoiding duplicates
        final mergedRoutes = List<Map<String, dynamic>>.from(_favoriteRoutes);
        
        for (final route in firestoreRoutes) {
          if (!mergedRoutes.any((r) => r['id'] == route['id'])) {
            mergedRoutes.add(route);
          }
        }
        
        setState(() {
          _favoriteRoutes = mergedRoutes;
        });
      }
    } catch (e) {
      debugPrint('Error loading favorite routes: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Sync unsynced routes to Firestore
  Future<void> _syncUnsyncedRoutes() async {
    if (currentUserId == null || !_isOnline) return;
    
    try {
      final unsyncedRoutes = await DatabaseHelper().getUnsyncedFavoriteRoutes();
      
      for (final route in unsyncedRoutes) {
        // Check if this route already exists in Firestore
        final existingRoutes = await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('favorite_routes')
            .doc(route['id'])
            .get();
            
        if (!existingRoutes.exists) {
          // Add to Firestore
          await _firestore
              .collection('users')
              .doc(currentUserId)
              .collection('favorite_routes')
              .doc(route['id'])
              .set({
            'origin': route['origin'],
            'destination': route['destination'],
            'fare': route['fare'],
            'createdAt': FieldValue.serverTimestamp(),
            'userId': currentUserId,
          });
          
          // Mark as synced in local database
          await DatabaseHelper().markFavoriteRouteAsSynced(route['id']);
        }
      }
      
      // Reload routes after syncing
      _loadFavoriteRoutes();
    } catch (e) {
      debugPrint('Error syncing routes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFFC32E31),
          elevation: 0,
          title: const Text(
            'Favorite Routes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          centerTitle: false,
          actions: [
            if (!_isOnline)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Icon(
                  Icons.cloud_off,
                  color: Colors.white,
                ),
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : currentUserId == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.account_circle,
                          size: 80,
                          color: Color(0xFFD9D9D9),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Please sign in to view your favorite routes',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF656565),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            // Navigate to sign in screen
                            // This would depend on your app's authentication flow
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC32E31),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : _favoriteRoutes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.star_border,
                              size: 80,
                              color: Color(0xFFD9D9D9),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No favorite routes yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF656565),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const TravelHomePage(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFC32E31),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Search Routes',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _favoriteRoutes.length,
                        itemBuilder: (context, index) {
                          final route = _favoriteRoutes[index];
                          final bool isSynced = route['synced'] == 1;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${route['origin']} → ${route['destination']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  if (!isSynced && _isOnline)
                                    const Icon(
                                      Icons.sync,
                                      color: Colors.orange,
                                      size: 16,
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                'GHS ${(route['fare'] as double).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Color(0xFF656565),
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                color: Colors.red,
                                onPressed: () => _deleteFavoriteRoute(route['id']),
                              ),
                              onTap: () {
                                // Navigate to trip details page instead of search page
                                if (route['routeData'] != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TripDetailsScreen(
                                        route: CompositeRoute.fromMap(route['routeData']),
                                        isFromFavorites: true,
                                      ),
                                    ),
                                  );
                                } else {
                                  // Fallback to search page if route data is not available
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TravelHomePage(
                                        initialOrigin: route['origin'],
                                        initialDestination: route['destination'],
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
      ),
    );
  }

  // Delete a favorite route
  Future<void> _deleteFavoriteRoute(String routeId) async {
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to manage your favorites'),
          backgroundColor: Color(0xFFC32E31),
        ),
      );
      return;
    }

    try {
      // Delete from local database first
      await DatabaseHelper().deleteFavoriteRoute(routeId);
      
      // If online, also delete from Firestore
      if (_isOnline) {
        await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('favorite_routes')
            .doc(routeId)
            .delete();
      }

      setState(() {
        _favoriteRoutes.removeWhere((route) => route['id'] == routeId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Route removed from favorites'),
          backgroundColor: Color(0xFFC32E31),
        ),
      );
    } catch (e) {
      debugPrint('Error deleting favorite route: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove route: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show dialog to add a new saved location
  void _showAddLocationDialog(BuildContext context) {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    String selectedType = 'home';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Saved Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name (e.g. Home, Work)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'home', child: Text('Home')),
                DropdownMenuItem(value: 'work', child: Text('Work')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (value) {
                selectedType = value!;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && addressController.text.isNotEmpty) {
                _addSavedLocation(
                  nameController.text,
                  addressController.text,
                  selectedType,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Add a new saved location to Firebase
  Future<void> _addSavedLocation(String name, String address, String type) async {
    if (currentUserId == null) return;

    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('saved_locations')
        .add({
      'name': name,
      'address': address,
      'type': type,
      'createdAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location saved successfully')),
    );
  }
}

// Widget for displaying a saved location
class StationListItem extends StatelessWidget {
  final String name;
  final String? distance;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const StationListItem({
    Key? key,
    required this.name,
    this.distance,
    required this.icon,
    this.iconColor,
    required this.onTap,
    this.onDelete,
  }) : super(key: key);

  static const Color lightGrey = Color(0xFFD9D9D9);
  static const Color iconGrey = Color(0xFF656565);
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.black54;

  static const TextStyle subheading = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12.0,
    color: textSecondary,
  );

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: lightGrey, width: 1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor ?? Color(0xFFC32E31),
              size: 24.0,
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: subheading),
                  if (distance != null) Text(distance!, style: caption),
                ],
              ),
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onDelete,
              )
            else
              const Icon(Icons.chevron_right, color: iconGrey),
          ],
        ),
      ),
    );
  }
}

// Widget for displaying a favorite route
class RouteListItem extends StatelessWidget {
  final String origin;
  final String destination;
  final String fare;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const RouteListItem({
    Key? key,
    required this.origin,
    required this.destination,
    required this.fare,
    required this.onTap,
    this.onDelete,
  }) : super(key: key);

  static const Color lightGrey = Color(0xFFD9D9D9);
  static const Color iconGrey = Color(0xFF656565);
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.black54;

  static const TextStyle subheading = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12.0,
    color: textSecondary,
  );

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: lightGrey, width: 1),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.directions_bus,
              color: Color(0xFFC32E31),
              size: 24.0,
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$origin → $destination', style: subheading),
                  Text('Fare: GHS $fare', style: caption),
                ],
              ),
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onDelete,
              )
            else
              const Icon(Icons.chevron_right, color: iconGrey),
          ],
        ),
      ),
    );
  }
}
