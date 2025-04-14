import 'package:flutter/material.dart';
import 'package:locomo_app/screens/nearest_stations.dart';
import 'package:locomo_app/screens/search.dart';
import 'package:locomo_app/screens/saved_locations.dart';
import 'package:locomo_app/screens/faqs.dart';
import 'package:locomo_app/screens/user_profile.dart';
import 'package:locomo_app/widgets/MainScaffold.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class RouteCard extends StatelessWidget {
  final String? label;
  final Color? labelColor;
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final String route;
  final String routeDetails;
  final int transferCount;
  final String price;
  final Color transferColor;

  const RouteCard({
    Key? key,
    this.label,
    this.labelColor,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.route,
    required this.routeDetails,
    required this.transferCount,
    required this.price,
    required this.transferColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // Label and star
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
 
              // In the build method, update the label handling:
              if (label != null && label!.isNotEmpty)
                Text(
                  label!,
                  style: TextStyle(
                    color: labelColor ?? Colors.black, // Provide default color
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const Icon(Icons.star_border, color: Colors.black54, size: 24),
            ],
          ),

          const SizedBox(height: 12),

          // Times
          Row(
            children: [
              Text(departureTime,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(width: 8),
              Text("• $duration •",
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xff656565))),
              const SizedBox(width: 8),
              Text(arrivalTime,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
            ],
          ),

          const SizedBox(height: 12),

          // Route
          Row(
            children: [
              const Icon(Icons.directions_bus_outlined,
                  size: 16, color: Colors.black54),
              const SizedBox(width: 8),
              Text(route, style: const TextStyle(fontSize: 12)),
            ],
          ),

          const SizedBox(height: 6),

          // Route details
          Row(
            children: [
              const Icon(Icons.directions_walk,
                  size: 16, color: Colors.black54),
              const SizedBox(width: 8),
              Text(routeDetails, style: const TextStyle(fontSize: 12)),
            ],
          ),

          const SizedBox(height: 12),

          // Bottom Row: Transfers + Price + Share
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Transfers
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

              // Price + Share
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
                      // Ask user to pick a contact from their list
                      final phone = await pickContactFromList(context);

                      if (phone != null) {
                        // Build SMS content with full route information
                        final msg = "Trotro Route Info:\n"
                            "Route: $route\n"
                            "Details: $routeDetails\n"
                            "Fare: $price\n"
                            "Departure: $departureTime\n"
                            "Arrival: $arrivalTime\n"
                            "Duration: $duration";

                        // Launch SMS app with prefilled message
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
    );
  }

  Future<String?> pickContactFromList(BuildContext context) async {
    // Ensure contact permission is granted before proceeding
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

    // Load contacts with phone numbers included
    final contacts = await FlutterContacts.getContacts(withProperties: true);

    // Show contacts in a scrollable bottom sheet for selection
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
}

Future<String?> pickContactPhoneNumber(BuildContext context) async {
  final status = await Permission.contacts.request();

  if (status != PermissionStatus.granted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contact permission denied')),
    );
    return null;
  }

  if (!await FlutterContacts.requestPermission()) {
    return null;
  }

  final contact = await FlutterContacts.openExternalPick();
  if (contact != null && contact.phones.isNotEmpty) {
    return contact.phones.first.number;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("No phone number found")),
  );
  return null;
}

Future<void> _shareRouteViaSMS(String message, String phoneNumber) async {
  // Construct SMS URI with prefilled body
  final Uri smsUri = Uri(
    scheme: 'sms',
    path: phoneNumber,
    queryParameters: {'body': message},
  );

  // Open the device's SMS app
  if (await canLaunchUrl(smsUri)) {
    await launchUrl(smsUri);
  } else {
    throw 'Could not launch SMS';
  }
}

class TravelResultsPage extends StatelessWidget {
  final List<dynamic> results;

  const TravelResultsPage({Key? key, required this.results}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 0,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFFC32E31),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Results',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          centerTitle: false,
        ),
        body: results.isEmpty
            ? const Center(child: Text("No routes found"))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final route = results[index];

                  // Calculate duration text
                  final duration = route['time'] != null
                      ? '${route['time']} min'
                      : 'Unknown duration';

                  // Build route details text with walking info if available
                  String routeDetails = route['details'] ?? 'Direct route';
                  if (route['originWalking'] != null ||
                      route['destinationWalking'] != null) {
                    routeDetails += ' (with walking segments)';
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: RouteCard(
                      label: index == 0 ? 'Recommended' : null,
                      labelColor: index == 0 ? Colors.green[700] : null,
                      departureTime: route['departure_time'] ?? 'N/A',
                      arrivalTime: route['arrival_time'] ?? 'N/A',
                      duration: duration,
                      route: '${route['origin']} → ${route['destination']}',
                      routeDetails: routeDetails,
                      transferCount: route['transfers'] ?? 0,
                      price: route['fare'] != null
                          ? 'GHS ${route['fare'].toStringAsFixed(2)}'
                          : 'GHS 0.00',
                      transferColor: Colors.red,
                    ),
                  );
                }
                // itemBuilder: (context, index) {
                //   final route = results[index];

                //   return Padding(
                //     padding: const EdgeInsets.only(bottom: 12.0),
                //     child: RouteCard(
                //       label: index == 0 ? 'Recommended' : null,
                //       labelColor: index == 0 ? Colors.green[700] : null,
                //       departureTime: route['departure_time'] ?? 'N/A',
                //       arrivalTime: route['arrival_time'] ?? 'N/A',
                //       duration: '${route['time']} min',
                //       route: '${route['origin']} → ${route['destination']}',
                //       routeDetails: route['details'] ?? 'Direct route',
                //       transferCount: route['transfers'] ?? 0,
                //       // price: 'GHS ${route['fare'].toString()}',
                //       price: route['fare'] != null
                //           ? 'GHS ${route['fare']}'
                //           : 'GHS 0.00',

                //       transferColor: Colors.red,
                //     ),
                //   );
                // },
                ),
      ),
    );
  }
}

class MainScaffold extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final Widget? floatingActionButton;

  const MainScaffold({
    Key? key,
    required this.currentIndex,
    required this.child,
    this.floatingActionButton,
  }) : super(key: key);

  void _onTabTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget page;
    switch (index) {
      case 0:
        page = const TravelHomePage();
        break;
      case 1:
        page = const NearestStationsScreen();
        break;
      case 2:
        page = const SavedLocationsScreen();
        break;
      case 3:
        page = const FAQScreen();
        break;
      case 4:
        page = const UserProfileScreen();
        break;
      default:
        page = const TravelHomePage();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _onTabTapped(context, index),
        selectedItemColor: const Color(0xFFC32E31),
        unselectedItemColor: const Color(0xFFD9D9D9),
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Favourites'),
          BottomNavigationBarItem(icon: Icon(Icons.help), label: 'Help'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
