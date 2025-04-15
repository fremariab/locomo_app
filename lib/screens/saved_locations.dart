import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:locomo_app/screens/search.dart';
import 'package:locomo_app/screens/trip_details.dart';
import 'package:locomo_app/widgets/main_scaffold.dart';
import 'package:locomo_app/services/database_helper.dart';
import 'package:locomo_app/services/connectivity_service.dart';
import 'package:locomo_app/models/route.dart';

class SavedLocationsScreen extends StatefulWidget {
  const SavedLocationsScreen({super.key});

  @override
  _SavedLocationsScreenState createState() => _SavedLocationsScreenState();
}

class _SavedLocationsScreenState extends State<SavedLocationsScreen> {
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

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadFavoriteRoutes();
    
    ConnectivityService().connectivityStream.listen((isOnline) {
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
        });
      }
      
      if (_isOnline) {
        _syncUnsyncedRoutes();
      }
    });
  }

  Future<void> _checkConnectivity() async {
    final isConnected = await ConnectivityService().isConnected();
    if (mounted) {
      setState(() {
        _isOnline = isConnected;
      });
    }
  }

  Future<void> _loadFavoriteRoutes() async {
    if (_auth.currentUser?.uid == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final localRoutes = await DatabaseHelper().getFavoriteRoutes(_auth.currentUser!.uid);
      
      if (mounted) {
        setState(() {
          _favoriteRoutes = localRoutes;
          _isLoading = false;
        });
      }
      
      if (_isOnline) {
        final snapshot = await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
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
        
        final mergedRoutes = List<Map<String, dynamic>>.from(_favoriteRoutes);
        
        for (final route in firestoreRoutes) {
          if (!mergedRoutes.any((r) => r['id'] == route['id'])) {
            mergedRoutes.add(route);
          }
        }
        
        if (mounted) {
          setState(() {
            _favoriteRoutes = mergedRoutes;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading favorite routes: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _syncUnsyncedRoutes() async {
    if (_auth.currentUser?.uid == null || !_isOnline) return;
    
    try {
      final unsyncedRoutes = await DatabaseHelper().getUnsyncedFavoriteRoutes();
      
      for (final route in unsyncedRoutes) {
        final existingRoutes = await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .collection('favorite_routes')
            .doc(route['id'])
            .get();
            
        if (!existingRoutes.exists) {
          await _firestore
              .collection('users')
              .doc(_auth.currentUser!.uid)
              .collection('favorite_routes')
              .doc(route['id'])
              .set({
            'origin': route['origin'],
            'destination': route['destination'],
            'fare': route['fare'],
            'createdAt': FieldValue.serverTimestamp(),
            'userId': _auth.currentUser!.uid,
          });
          
          await DatabaseHelper().markFavoriteRouteAsSynced(route['id']);
        }
      }
      
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
            : _auth.currentUser == null
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

  Future<void> _deleteFavoriteRoute(String routeId) async {
    if (_auth.currentUser?.uid == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to manage your favorites'),
            backgroundColor: Color(0xFFC32E31),
          ),
        );
      }
      return;
    }

    try {
      await DatabaseHelper().deleteFavoriteRoute(routeId);
      
      if (_isOnline) {
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .collection('favorite_routes')
            .doc(routeId)
            .delete();
      }

      if (mounted) {
        setState(() {
          _favoriteRoutes.removeWhere((route) => route['id'] == routeId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Route removed from favorites'),
            backgroundColor: Color(0xFFC32E31),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting favorite route: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove route: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}