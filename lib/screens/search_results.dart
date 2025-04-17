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

class RouteCard extends StatefulWidget {
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
    this.onSaveRoute,
    this.routeData,
  }) : super(key: key);

  @override
  State<RouteCard> createState() => _RouteCardState();
}

class _RouteCardState extends State<RouteCard> {
  bool _isSaved = false;

  void _handleSave() {
    final fare = double.tryParse(widget.price.replaceAll('GHS ', '')) ?? 0.0;
    widget.onSaveRoute?.call(
      widget.route.split(' → ')[0],
      widget.route.split(' → ')[1],
      fare,
    );
    setState(() {
      _isSaved = true;
    });
  }

  String _formatTimeWithAMPM(String timeString) {
    if (timeString.isEmpty ||
        timeString.contains('AM') ||
        timeString.contains('PM') ||
        timeString == 'Now' ||
        timeString == 'Later') {
      return timeString;
    }

    try {
      final parts = timeString.split(':');
      if (parts.length != 2) return timeString;

      int hour = int.parse(parts[0]);
      final minutes = parts[1];
      final isAM = hour < 12;

      if (hour == 0) {
        hour = 12;
      } else if (hour > 12) {
        hour -= 12;
      }

      return '$hour:$minutes ${isAM ? 'AM' : 'PM'}';
    } catch (_) {
      return timeString;
    }
  }

  String get formattedDepartureTime =>
      _formatTimeWithAMPM(widget.departureTime);

  String get formattedArrivalTime => _formatTimeWithAMPM(widget.arrivalTime);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.routeData != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TripDetailsScreen(
                route: widget.routeData!,
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
                    widget.label ??
                        '', // even if null, fallback to empty string
                    style: TextStyle(
                      color: widget.labelColor ?? Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _handleSave,
                  child: Icon(
                    _isSaved ? Icons.star : Icons.star_border,
                    color: _isSaved ? Colors.amber : Colors.black54,
                    size: 24,
                  ),
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
                  child: Text(
                    "• ${widget.duration} •",
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xff656565),
                    ),
                  ),
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
                    widget.route,
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
                    widget.routeDetails,
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
                      color: widget.transferColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            '${widget.transferCount} ${widget.transferCount == 1 ? 'Transfer' : 'Transfers'}',
                            style: TextStyle(
                              color: widget.transferColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1, // optional for extra safety
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
                    Text(widget.price,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    // 1️⃣ Ask user to pick a contact
                    final phone = await pickContactFromList(context);
                    if (phone == null || widget.routeData == null) return;

                    // 2️⃣ Build a simple SMS body
                    final totalFare =
                        widget.routeData!.totalFare.toStringAsFixed(2);
                    final origin = widget.routeData!.origin;
                    final destination = widget.routeData!.destination;
                    final steps = widget.routeData!.segments
                        .map((s) => "${s.description} (${s.fare} GHS)")
                        .join("\n");
                    final message = '''
Route from $origin → $destination
$steps

Total fare: $totalFare GHS
''';

                    // 3️⃣ Launch SMS
                    await _shareRouteViaSMS(message, phone);
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
  // 1️⃣ Ask for permission
  final granted = await FlutterContacts.requestPermission();
  if (!granted) {
    // Show a dialog explaining why we need it, with a “Go to Settings” button
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Contacts Permission'),
        content: const Text(
          'We need access to your contacts in order to share routes. '
          'Please enable Contacts permission in Settings.'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.of(ctx).pop();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
    return null;
  }

  // 2️⃣ Load all contacts with phone data
  final contacts = await FlutterContacts.getContacts(withProperties: true);

  // 3️⃣ Show a fixed-height bottom sheet
  return showModalBottomSheet<String>(
    context: context,
    builder: (_) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Select a contact to share route with",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (context, i) {
                final c = contacts[i];
                final phone =
                    c.phones.isNotEmpty ? c.phones.first.number : null;
                return ListTile(
                  title: Text(c.displayName),
                  subtitle:
                      phone != null ? Text(phone) : const Text("No number"),
                  onTap: () => Navigator.pop(context, phone),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

  /// If you still want a full‑screen picker via FlutterContacts UI:
  Future<String?> pickContactPhoneNumber(BuildContext context) async {
    // Already requested permission above; you can skip here or repeat:
    final granted = await FlutterContacts.requestPermission();
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Contact permission denied")),
      );
      return null;
    }

    // Launch the platform’s native picker
    final contact = await FlutterContacts.openExternalPick();
    if (contact != null && contact.phones.isNotEmpty) {
      return contact.phones.first.number;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("No phone number found")),
    );
    return null;
  }

  /// Sends the SMS via the platform’s default messaging app
  Future<void> _shareRouteViaSMS(String message, String phoneNumber) async {
    final uri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: {'body': message},
    );
    if (!await canLaunchUrl(uri)) {
      throw 'Could not launch SMS';
    }
    await launchUrl(uri);
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
              tooltip: "Sort By",
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
                  final hours = route.totalDuration ~/ 60;
                  final minutes = route.totalDuration % 60;
                  final duration =
                      hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

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
