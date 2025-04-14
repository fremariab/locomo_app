




import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:locomo_app/services/auth_service.dart';
import 'package:locomo_app/services/user_service.dart';

class SavedRoutesScreen extends StatefulWidget {
  const SavedRoutesScreen({Key? key}) : super(key: key);

  @override
  State<SavedRoutesScreen> createState() => _SavedRoutesScreenState();
}

class _SavedRoutesScreenState extends State<SavedRoutesScreen> {
  // Colors
  static const Color primaryRed = Color(0xFFC33939);
  static const Color white = Colors.white;
  static const Color lightGrey = Color(0xFFEEEEEE);
  static const Color darkGrey = Color(0xFF616161);
  static const Color textSecondary = Colors.black54;

  // Services
  final AuthService _authService = AuthService();
  final UserProfileService _userProfileService = UserProfileService();

  // State
  bool _isLoading = true;
  List<Map<String, dynamic>> _savedRoutes = [];

  @override
  void initState() {
    super.initState();
    _loadSavedRoutes();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _loadSavedRoutes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _authService.getCurrentUser()?.uid;
      if (userId != null) {
        final routes = await _userProfileService.getSavedRoutes(userId);
        setState(() {
          _savedRoutes = routes;
        });
      }
    } catch (e) {
      _showMessage('Error loading saved routes: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteRoute(String routeId) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Route?'),
        content: const Text('Are you sure you want to remove this saved route?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final userId = _authService.getCurrentUser()?.uid;
        if (userId != null) {
          final success = await _userProfileService.deleteRoute(userId, routeId);
          if (success) {
            _showMessage('Route deleted');
            _loadSavedRoutes();
          } else {
            _showMessage('Failed to delete route');
          }
        }
      } catch (e) {
        _showMessage('Error deleting route: ${e.toString()}');
      }
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    
    DateTime date;
    if (timestamp is DateTime) {
      date = timestamp;
    } else {
      // Assuming timestamp is from Firestore
      date = timestamp.toDate();
    }
    
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryRed,
        title: const Text('Saved Routes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedRoutes.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: _savedRoutes.length,
                  itemBuilder: (context, index) {
                    final route = _savedRoutes[index];
                    return _buildRouteCard(route);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.route_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No saved routes yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: darkGrey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Routes you save will appear here',
            style: TextStyle(
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> route) {
    // Extract route information
    final String routeId = route['id'] ?? '';
    final String origin = route['origin'] ?? 'Unknown Origin';
    final String destination = route['destination'] ?? 'Unknown Destination';
    final String departureDate = _formatDate(route['departureDate']);
    final String departureTime = route['departureTime'] ?? 'N/A';
    final String routeType = route['routeType'] ?? 'Route';
    final String price = route['price'] != null ? '₵${route['price']}' : 'N/A';
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    routeType,
                    style: const TextStyle(
                      color: primaryRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: darkGrey),
                  onPressed: () => _deleteRoute(routeId),
                  tooltip: 'Delete route',
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Origin to Destination
            Row(
              children: [
                const Icon(Icons.trip_origin, size: 16, color: primaryRed),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    origin,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            
            // Dotted line between origin and destination
            Row(
              children: [
                const SizedBox(width: 8),
                Container(
                  height: 16,
                  width: 1,
                  color: darkGrey.withOpacity(0.3),
                ),
                const SizedBox(width: 8),
                const Text(
                  'to',
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: primaryRed),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    destination,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Date, Time and Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: darkGrey),
                    const SizedBox(width: 4),
                    Text(
                      departureDate,
                      style: const TextStyle(color: textSecondary),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: darkGrey),
                    const SizedBox(width: 4),
                    Text(
                      departureTime,
                      style: const TextStyle(color: textSecondary),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.payments_outlined, size: 14, color: darkGrey),
                    const SizedBox(width: 4),
                    Text(
                      price,
                      style: const TextStyle(
                        color: primaryRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}