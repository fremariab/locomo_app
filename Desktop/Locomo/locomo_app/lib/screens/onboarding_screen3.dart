import 'package:flutter/material.dart';

class OnboardingScreen3 extends StatelessWidget {
  const OnboardingScreen3({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Logo at top
          const Padding(
            padding: EdgeInsets.only(top: 15.0), // Reduced from 20 to 15
            child: Center(
              child: Text(
                'LOCOMO',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 15), // Reduced from 20 to 15
          // Route information cards
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate the maximum height available for route cards
                final availableHeight = constraints.maxHeight;
                // Calculate height for each card - reduce slightly to prevent overflow
                final cardHeight = (availableHeight / 4) - 1; // Subtract 1 pixel to prevent overflow
                
                return SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildRouteCard('Circle', '7 major routes', '7:00-7:40 AM', cardHeight),
                      const SizedBox(height: 14), // Reduced from 15 to 14
                      _buildRouteCard('Madina', '5 major routes', '7:00-7:00 PM', cardHeight),
                      const SizedBox(height: 14), // Reduced from 15 to 14
                      _buildRouteCard('Lapaz', '8 major routes', '5:30-5:30 PM', cardHeight),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 15), // Reduced from 20 to 15
          // Title and description
          const Text(
            'Stay Updated with\nReal-Time Information',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8), // Reduced from 10 to 8
          const Text(
            'Find the quickest routes and destinations to beat traffic and enhance your train travels!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(String location, String routes, String hours, double height) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // Reduced vertical padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Location image (placeholder)
          Container(
            width: 58, // Reduced from 60 to 58
            height: 58, // Reduced from 60 to 58
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                location[0],
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Location details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  location,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$routes • Peak hours: $hours',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          // Action buttons
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bookmark_border,
                  size: 16,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}