import 'package:flutter/material.dart';
import 'package:locomo_app/screens/search.dart';
import 'package:locomo_app/screens/nearest_stations.dart';
import 'package:locomo_app/screens/saved_locations.dart';
import 'package:locomo_app/screens/faqs.dart';
import 'package:locomo_app/screens/user_profile.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final Widget? floatingActionButton;

  const MainScaffold({
    super.key,
    required this.currentIndex,
    required this.child,
    this.floatingActionButton,
  });

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
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}