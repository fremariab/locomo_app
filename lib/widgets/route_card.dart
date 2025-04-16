import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:locomo_app/services/favorites_service.dart';
import 'package:locomo_app/models/route_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:locomo_app/screens/route_details_screen.dart'; 

class RouteCard extends StatelessWidget {
  final String? label;
  final Color? labelColor;
  final String duration;
  final String route;
  final String routeDetails;
  final int transferCount;
  final String price;
  final Color transferColor;
  final Map<String, dynamic>? originWalking;
  final Map<String, dynamic>? destinationWalking;
  final RouteModel routeData;

  const RouteCard({
    Key? key,
    this.label,
    this.labelColor,
    required this.duration,
    required this.route,
    required this.routeDetails,
    required this.transferCount,
    required this.price,
    required this.transferColor,
    this.originWalking,
    this.destinationWalking,
    required this.routeData,
  }) : super(key: key);

 String _getWalkingInfo(Map<String, dynamic>? walkingData) {
  if (walkingData == null) return '';
  
  try {
    // Try different possible structures from Google Maps API
    if (walkingData.containsKey('text')) {
      // Direct distance/duration format
      return walkingData['text'];
    } else if (walkingData.containsKey('routes')) {
      // Full directions response format
      final routes = walkingData['routes'] as List;
      if (routes.isEmpty) return '';
      
      final legs = routes.first['legs'] as List;
      if (legs.isEmpty) return '';
      
      final leg = legs.first;
      final distance = leg['distance']?['text'] ?? '';
      final duration = leg['duration']?['text'] ?? '';
      
      return '$distance ($duration)';
    }
  } catch (e) {
    debugPrint('Error parsing walking info: $e');
  }
  
  return '';
}

  String calculateArrivalTime(String duration) {
    try {
      final minutes = int.tryParse(duration.split(' ').first) ?? 0;
      final now = DateTime.now();
      final arrival = now.add(Duration(minutes: minutes));
      return _formatTime(arrival);
    } catch (e) {
      return 'Later';
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final period = time.hour < 12 ? 'AM' : 'PM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    final currentTime = _formatTime(DateTime.now());
    final arrivalTime = calculateArrivalTime(duration);
    final favoritesService = Provider.of<FavoritesService>(context);
    final isFavorite = favoritesService.isFavorite(routeData);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RouteDetailsScreen(route: routeData),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0XFFF7f7f7),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff656565).withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (label != null && label!.isNotEmpty)
                  Text(
                    label!,
                    style: TextStyle(
                      color: labelColor ?? Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.star : Icons.star_border,
                    color: isFavorite ? Colors.amber : Colors.black54,
                    size: 24,
                  ),
                  onPressed: () {
                    if (isFavorite) {
                      favoritesService.removeFavorite(routeData);
                    } else {
                      favoritesService.addFavorite(routeData);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  currentTime,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 8),
                Text("• $duration •",
                    style:
                        const TextStyle(fontSize: 12, color: Color(0xff656565))),
                const SizedBox(width: 8),
                Text(
                  'Arrives at $arrivalTime',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (originWalking != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.directions_walk,
                        size: 16, color: Colors.black54),
                    const SizedBox(width: 8),
                    Text(
                      'From origin: ${_getWalkingInfo(originWalking)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                const Icon(Icons.directions_bus_outlined,
                    size: 16, color: Colors.black54),
                const SizedBox(width: 8),
                Text(route, style: const TextStyle(fontSize: 12)),
              ],
            ),
            if (destinationWalking != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    const Icon(Icons.directions_walk,
                        size: 16, color: Colors.black54),
                    const SizedBox(width: 8),
                    Text(
                      'To destination: ${_getWalkingInfo(destinationWalking)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.directions_bus, size: 16, color: Colors.black54),
                const SizedBox(width: 8),
                Text(routeDetails, style: const TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: transferColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '$transferCount ${transferCount == 1 ? 'Transfer' : 'Transfers'}',
                        style: TextStyle(
                            color: transferColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                      const Icon(Icons.keyboard_arrow_down,
                          size: 16, color: Colors.black54),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(price,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const Text('One-way',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xff656565))),
                      ],
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () async {
                        final phone = await pickContactFromList(context);
                        if (phone != null) {
                          final msg = "Trotro Route Info:\n"
                              "Route: ${routeData.origin} → ${routeData.destination}\n"
                              "Details: $routeDetails\n"
                              "Fare: $price\n"
                              "Current Time: $currentTime\n"
                              "Arrival Time: $arrivalTime\n"
                              "Duration: $duration";
                          await _shareRouteViaSMS(msg, phone);
                        }
                      },
                      child:
                          const Icon(Icons.share_rounded, color: Colors.black54),
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
  Future<String?> pickContactFromList(BuildContext context) async {
    final status = await Permission.contacts.status;
    if (!status.isGranted) {
      final result = await Permission.contacts.request();
      if (!result.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Contact permission denied")),
        );
        return null;
      }
    }

    final contacts = await FlutterContacts.getContacts(withProperties: true);

    return showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text("Select a contact to share route with",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  final contact = contacts[index];
                  final phone = contact.phones.isNotEmpty
                      ? contact.phones.first.number
                      : null;

                  return ListTile(
                    title: Text(contact.displayName),
                    subtitle:
                        phone != null ? Text(phone) : const Text("No number"),
                    onTap: () {
                      Navigator.pop(context, phone);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _shareRouteViaSMS(String message, String phoneNumber) async {
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: {'body': message},
    );

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      throw 'Could not launch SMS';
    }
  }
}