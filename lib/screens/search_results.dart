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
              if (label != null)
                Text(
                  label!,
                  style: TextStyle(
                    color: labelColor,
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

                  // 📲 SHARE ICON
                  GestureDetector(
                    onTap: () async {
                      final phone = await pickContactFromList(context);
                      if (phone != null) {
                        final msg =
                            "🚐 Route: $route\nDetails: $routeDetails\nFare: $price";
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
    if (!await FlutterContacts.requestPermission()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permission denied")),
      );
      return null;
    }

    final contacts = await FlutterContacts.getContacts(withProperties: true);

    return showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: contacts.length,
          itemBuilder: (context, index) {
            final contact = contacts[index];
            final phone =
                contact.phones.isNotEmpty ? contact.phones.first.number : null;

            return ListTile(
              title: Text(contact.displayName),
              subtitle: phone != null ? Text(phone) : const Text("No number"),
              onTap: () {
                Navigator.pop(context, phone);
              },
            );
          },
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

class TravelResultsPage extends StatelessWidget {
  const TravelResultsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 0, // Search is selected
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFFC32E31),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Results',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Papaye Osu • Pent Hostel, Madina',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          centerTitle: false,
        ),
        body: Column(
          children: [
            // Filter Buttons
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  // Sort Button
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFC32E31),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.sort, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Sort: Cheapest Route',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),

            // Route Cards
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const SizedBox(height: 8),

                  // Cheapest Route Card (Recommended)
                  // Cheapest Route Card (Recommended)
                  Column(
                    children: [
                      // Recommended Label only for first card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: const BoxDecoration(
                          color: Color(0xFFC32E31),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: const [
                            Text(
                              'RECOMMENDED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(
                              Icons.info_outline,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                      // Use RouteCard with special styling for bottom border radius
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        child: RouteCard(
                          label: 'Cheapest',
                          labelColor: Colors.green[700],
                          departureTime: '6:15 AM',
                          arrivalTime: '7:05 AM',
                          duration: '50m',
                          route: 'Osu → Madina Direct',
                          routeDetails: 'RE Junction, Osu → UPSA Junction',
                          transferCount: 0,
                          price: 'GHS 5.50',
                          transferColor: Colors.red,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Fastest Route Card
                  RouteCard(
                    label: 'Fastest',
                    labelColor: Colors.green[700],
                    departureTime: '6:15 AM',
                    arrivalTime: '6:55 AM',
                    duration: '40m',
                    route: 'Osu → 37 → Madina',
                    routeDetails: 'Walk 10 min to Ako-Adjei',
                    transferCount: 1,
                    price: 'GHS 6.00',
                    transferColor: Colors.red,
                  ),

                  const SizedBox(height: 8),

                  // Third Route Card
                  RouteCard(
                    label: null,
                    departureTime: '6:15 AM',
                    arrivalTime: '7:20 AM',
                    duration: '1h5m',
                    route: 'Osu → Circle → UPSA',
                    routeDetails: 'Walk 5 min to RE Junction',
                    transferCount: 2,
                    price: 'GHS 7.50',
                    transferColor: Colors.red,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
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
