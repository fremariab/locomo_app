import 'package:flutter/material.dart';
import 'package:locomo_app/screens/nearest_stations.dart';
import 'package:locomo_app/screens/faqs.dart';
import 'package:locomo_app/screens/saved_locations.dart';
import 'package:locomo_app/screens/user_profile.dart';
import 'package:locomo_app/screens/search.dart';
import 'package:locomo_app/widgets/MainScaffold.dart';

class SavedLocationsScreen extends StatefulWidget {
  const SavedLocationsScreen({Key? key}) : super(key: key);

  @override
  _SavedLocationsScreenState createState() => _SavedLocationsScreenState();
}

class _SavedLocationsScreenState extends State<SavedLocationsScreen> {
  int _currentIndex = 1;

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

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 2, // Tab index for "Favourites"
      floatingActionButton: FloatingActionButton(
        backgroundColor: white,
        elevation: 2,
        onPressed: () {
          // Handle add new location
        },
        child: const Icon(Icons.add, color: darkGrey),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Bar
              Container(
                color: primaryRed,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top,
                  bottom: 16.0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: white),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Favourites',
                          style: TextStyle(
                            color: white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // To balance the layout
                  ],
                ),
              ),

              // List of Saved Locations
              Container(
                color: white,
                child: ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    StationListItem(
                      name: 'Set home address',
                      icon: Icons.home,
                      iconColor: darkGrey,
                      onTap: () {},
                    ),
                    StationListItem(
                      name: 'Set work address',
                      icon: Icons.work,
                      iconColor: darkGrey,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Embedded StationListItem Widget
class StationListItem extends StatelessWidget {
  final String name;
  final String? distance;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;

  const StationListItem({
    Key? key,
    required this.name,
    this.distance,
    required this.icon,
    this.iconColor,
    required this.onTap,
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
            const Icon(Icons.chevron_right, color: iconGrey),
          ],
        ),
      ),
    );
  }
}
