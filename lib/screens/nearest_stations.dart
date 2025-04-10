import 'package:flutter/material.dart';
import 'package:locomo_app/widgets/MainScaffold.dart';

class NearestStationsScreen extends StatefulWidget {
  const NearestStationsScreen({Key? key}) : super(key: key);

  @override
  NearestStationsScreenState createState() => NearestStationsScreenState();
}

class NearestStationsScreenState extends State<NearestStationsScreen> {
  // Define colors inline
  static const Color primaryRed = Color(0xFFC33939);
  static const Color white = Colors.white;
  static const Color lightGrey = Color(0xFFEEEEEE);
  static const Color darkGrey = Color(0xFF616161);
  static const Color iconGrey = Color(0xFF757575);
  static const Color textPrimary = Colors.black87;

  // Define text styles inline
  static const TextStyle subheading = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 1, // Index for "Explore"
      child: SafeArea(
        child: Column(
          children: [
            // Custom app bar
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
                        'Explore',
                        style: TextStyle(
                          color: white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Spacer to balance layout
                ],
              ),
            ),

            // Map section
            Expanded(
              child: Stack(
                children: [
                  // Map image background
                  Image.asset(
                    './assets/images/eb2694f5-9bf5-487c-a918-79ce6d7246a7.webp',
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: lightGrey,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.map, size: 48, color: darkGrey),
                              SizedBox(height: 16),
                              Text('Map View', style: subheading),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Floating location button
                  Positioned(
                    bottom: 100,
                    right: 16,
                    child: FloatingActionButton(
                      backgroundColor: white,
                      elevation: 2,
                      onPressed: () {
                        // Handle recenter location
                      },
                      child: const Icon(Icons.my_location, color: darkGrey),
                    ),
                  ),

                  // Bottom buttons
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                // Handle "Near Me"
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryRed,
                                foregroundColor: white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.train, size: 18),
                                  SizedBox(width: 8),
                                  Text('Trotro Stations Near Me'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                // Handle offline map
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: white,
                                foregroundColor: textPrimary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4.0),
                                  side: const BorderSide(color: lightGrey),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.download, size: 18),
                                  SizedBox(width: 8),
                                  Text('Offline Map'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
