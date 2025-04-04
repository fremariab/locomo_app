import 'package:flutter/material.dart';

class OnboardingScreen1 extends StatelessWidget {
  const OnboardingScreen1({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Column(
        children: [
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
          const SizedBox(height: 15),
          // Map with stations
          Image.asset(
            'assets/images/onb_image.png',
            width: 300,
            height: 300,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.error, size: 50);
            },
          ),
          const SizedBox(height: 15),
          // Title and description
          const Text(
            'Your Journey,\nPerfectly Planned',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.all(
                16.0), // Adjust the padding value as needed
            child: const Text(
              'Effortlessly create and organize your dream trips. Start exploring now!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Poppins',
                color: Color(0xff656565),
              ),
            ),
          )
        ],
      ),
    );
  }
}
