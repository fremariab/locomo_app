import 'package:flutter/material.dart';

class OnboardingScreen3 extends StatelessWidget {
  const OnboardingScreen3({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Show app logo at the top
          Padding(
            padding: const EdgeInsets.only(top: 5.0),
            child: Center(
              child: Image.asset(
                'assets/images/locomologo2.png',
                width: 100,
                height: 100,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.error, size: 50);
                },
              ),
            ),
          ),

          const SizedBox(height: 15),

          // Show image representing live updates or route cards
          Image.asset(
            'assets/images/onb_image2.png',
            width: 300,
            height: 300,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.error, size: 50);
            },
          ),

          const SizedBox(height: 15),

          // Heading text
          const Text(
            'Stay Updated with\nReal-Time Information',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),

          const SizedBox(height: 8),

          // Description text under the heading
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: const Text(
              'See which stations are near you and explore the country with ease!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xff656565),
              ),
            ),
          )
        ],
      ),
    );
  }
}
