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
          // Logo at top
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
          const SizedBox(height: 15), // Reduced from 20 to 15
          // Route information cards
          Image.asset(
            'assets/images/onb_image2.png',
            width: 300,
            height: 300,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.error, size: 50);
            },
          ),
          const SizedBox(height: 15), // Reduced from 20 to 15
          // Title and description
          const Text(
            'Stay Updated with\nReal-Time Information',
            textAlign: TextAlign.center,
           style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8), // Reduced from 10 to 8
          Padding(
            padding: const EdgeInsets.all(
                16.0), // Adjust the padding value as needed
            child:  const Text(
            'See which stations are near you and explore the country with ease!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xff656565)
            ),
          ),
          )
        ],
      ),
    );
  }
}