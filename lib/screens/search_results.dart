import 'package:flutter/material.dart';
import 'package:locomo_app/screens/nearest_stations.dart';
import 'package:locomo_app/screens/search.dart';
import 'package:locomo_app/screens/saved_locations.dart';
import 'package:locomo_app/screens/faqs.dart';
import 'package:locomo_app/screens/user_profile.dart';
import 'package:locomo_app/screens/trip_details.dart';
import 'package:locomo_app/widgets/MainScaffold.dart' as widgets;
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:locomo_app/models/route.dart';

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
  final Function(String origin, String destination, double fare)? onSaveRoute;
  final CompositeRoute? routeData;

  RouteCard({
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
    this.onSaveRoute,
    this.routeData,
  }) : super(key: key);
  String _formatTimeWithAMPM(String timeString) {
    // If already formatted or empty, return as is
    if (timeString.isEmpty ||
        timeString.contains('AM') ||
        timeString.contains('PM') ||
        timeString == 'Now' ||
        timeString == 'Later') {
      return timeString;
    }

    try {
      // Assuming time format is HH:MM (24-hour)
      final parts = timeString.split(':');
      if (parts.length != 2)
        return timeString; // Return original if not in expected format

      int hour = int.parse(parts[0]);
      final minutes = parts[1];
      final isAM = hour < 12;

      // Convert to 12-hour format
      if (hour == 0) {
        hour = 12; // 00:00 becomes 12:00 AM
      } else if (hour > 12) {
        hour -= 12; // e.g., 13:00 becomes 1:00 PM
      }

      return '$hour:$minutes ${isAM ? 'AM' : 'PM'}';
    } catch (e) {
      // If parsing fails, return the original string
      return timeString;
    }
  }

  String get formattedDepartureTime => _formatTimeWithAMPM(departureTime);
  String get formattedArrivalTime => _formatTimeWithAMPM(arrivalTime);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (routeData != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TripDetailsScreen(
                route: routeData!,
              ),
            ),
          );
        }
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
            // Label and star
            Row(
              children: [
                Expanded(
                  child: Text(
                    label ?? '', // even if null, fallback to empty string
                    style: TextStyle(
                      color: labelColor ?? Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (onSaveRoute != null) {
                      final fare =
                          double.tryParse(price.replaceAll('GHS ', '')) ?? 0.0;
                      onSaveRoute!(
                          route.split(' → ')[0], route.split(' → ')[1], fare);
                    }
                  },
                  child: const Icon(Icons.star_border,
                      color: Colors.black54, size: 24),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Times
            // Times row - add Flexible widgets
            Row(
              children: [
                Text(formattedDepartureTime,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text("• $duration •",
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xff656565))),
                ),
                const SizedBox(width: 8),
                Text(formattedArrivalTime,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),

            // Route
            Row(
              children: [
                const Icon(Icons.directions_bus_outlined,
                    size: 16, color: Colors.black54),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    route,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

// Route details
            Row(
              children: [
                const Icon(Icons.directions_walk,
                    size: 16, color: Colors.black54),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    routeDetails,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Bottom Section: Transfers + Price + Share (wrapped safely)
            // Bottom Section
            Row(
              children: [
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: transferColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            '$transferCount ${transferCount == 1 ? 'Transfer' : 'Transfers'}',
                            style: TextStyle(
                                color: transferColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(price,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    // Share logic
                  },
                  child: const Icon(Icons.share_rounded, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
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

class TravelResultsPage extends StatefulWidget {
  final List<CompositeRoute> results;
  final String? origin;
  final String? destination;
  final Function(String origin, String destination, double fare)? onSaveRoute;

  final dynamic initialSortBy;

  const TravelResultsPage({
    Key? key,
    required this.results,
    this.origin,
    this.destination,
    required this.initialSortBy,
    this.onSaveRoute,
  }) : super(key: key);

  @override
  State<TravelResultsPage> createState() => _TravelResultsPageState();
}

class _TravelResultsPageState extends State<TravelResultsPage> {
  late String _sortBy;

  @override
  void initState() {
    super.initState();
    _sortBy = widget.initialSortBy;
  }
  // Default sort

  // Sort the results based on the selected criteria
  List<CompositeRoute> get sortedResults {
    final results = List<CompositeRoute>.from(widget.results);

    switch (_sortBy) {
      case 'lowest_fare':
        results.sort((a, b) => a.totalFare.compareTo(b.totalFare));
        break;
      case 'shortest_time':
        results.sort((a, b) => a.totalDuration.compareTo(b.totalDuration));
        break;
      case 'fewest_transfers':
        results.sort((a, b) => a.segments.length.compareTo(b.segments.length));
        break;
      case 'recommended':
      default:
        // Keep original order for recommended
        break;
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    return widgets.MainScaffold(
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
          actions: [
            // Sort button
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort, color: Colors.white),
              onSelected: (String value) {
                setState(() {
                  _sortBy = value;
                });
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'recommended',
                  child: Text('Recommended'),
                ),
                const PopupMenuItem<String>(
                  value: 'lowest_fare',
                  child: Text('Lowest Fare'),
                ),
                const PopupMenuItem<String>(
                  value: 'shortest_time',
                  child: Text('Shortest Time'),
                ),
                const PopupMenuItem<String>(
                  value: 'fewest_transfers',
                  child: Text('Fewest Transfers'),
                ),
              ],
            ),
          ],
        ),
        body: widget.results.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.directions_bus_outlined,
                      size: 64,
                      color: Color(0xFFC32E31),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "No routes found",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "We couldn't find any routes between these locations.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC32E31),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Try Again",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sortedResults.length,
                itemBuilder: (context, index) {
                  final route = sortedResults[index];

                  // Safely get the first and last segments
                  final firstSegment =
                      route.segments.isNotEmpty ? route.segments.first : null;
                  final lastSegment = route.segments.length > 1
                      ? route.segments.last
                      : firstSegment;

                  // Calculate duration text
                  final duration = '${(route.totalDuration / 60).round()} min';

                  // Build route details text
                  String routeDetails =
                      firstSegment?.description ?? 'Unknown route';
                  if (lastSegment != null && lastSegment != firstSegment) {
                    routeDetails += ' → ${lastSegment.description}';
                  }

                  // Build the route display text with null safety
                  final routeText =
                      '${route.origin ?? 'Unknown'} → ${route.destination ?? 'Unknown'}';

                  // Ensure departure and arrival times are not null
                  final departureTime = route.departureTime.isNotEmpty
                      ? route.departureTime
                      : 'Now';
                  final arrivalTime = route.arrivalTime.isNotEmpty
                      ? route.arrivalTime
                      : 'Later';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: RouteCard(
                      label: route.totalFare == 0
                          ? '🚶‍♂️ Walking Only'
                          : index == 0
                              ? 'Recommended'
                              : null,
                      labelColor: route.totalFare == 0
                          ? Colors.orange
                          : index == 0
                              ? Colors.green[700]
                              : null,
                      departureTime: departureTime,
                      arrivalTime: arrivalTime,
                      duration: duration,
                      route: routeText,
                      routeDetails: routeDetails,
                      transferCount: route.segments.length - 1,
                      price: route.totalFare == 0
                          ? 'Free'
                          : 'GHS ${route.totalFare.toStringAsFixed(2)}',
                      transferColor: Color(0xffc32e21),
                      onSaveRoute: widget.onSaveRoute,
                      routeData: route,
                    ),
                  );
                },
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
        page = const TravelHomePage(
          initialOrigin: null,
          initialDestination: null,
        );
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
        page = const TravelHomePage(
          initialOrigin: null,
          initialDestination: null,
        );
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
