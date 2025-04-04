import 'package:flutter/material.dart';

class OnboardingScreen2 extends StatelessWidget {
  const OnboardingScreen2({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Logo at top
          const Padding(
            padding: EdgeInsets.only(top: 20.0),
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
          const SizedBox(height: 20),
          // Phone screens showing map feature
          Expanded(
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxHeight = constraints.maxHeight;
                  final maxWidth = constraints.maxWidth;
                  final phoneHeight = maxHeight * 0.8;
                  final phoneWidth = phoneHeight * 0.5;
                  
                  return SizedBox(
                    height: phoneHeight,
                    width: maxWidth,
                    child: Stack(
                      alignment: Alignment.center,
                      fit: StackFit.expand,
                      children: [
                        // Background
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        
                        // Left Phone
                        Positioned(
                          left: maxWidth * 0.15,
                          top: phoneHeight * 0.1,
                          child: Transform.rotate(
                            angle: -0.1,
                            child: _buildPhone(
                              width: phoneWidth,
                              height: phoneHeight * 0.7,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  const Spacer(),
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      color: Colors.white.withOpacity(0.8),
                                      child: const Center(
                                        child: Icon(
                                          Icons.pin_drop,
                                          color: Colors.red,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // Center Phone
                        Positioned(
                          child: _buildPhone(
                            width: phoneWidth,
                            height: phoneHeight * 0.8,
                            child: const Center(
                              child: Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                        
                        // Right Phone
                        Positioned(
                          right: maxWidth * 0.15,
                          top: phoneHeight * 0.1,
                          child: Transform.rotate(
                            angle: 0.1,
                            child: _buildPhone(
                              width: phoneWidth,
                              height: phoneHeight * 0.7,
                              child: Column(
                                children: [
                                  const Spacer(),
                                  Container(
                                    height: phoneHeight * 0.2,
                                    color: Colors.white.withOpacity(0.8),
                                    child: const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.directions_bus,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Station',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(flex: 2),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Title and description
          const Text(
            'Discover\nStations Nearby',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'See which stations are near you and explore the country with ease!',
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

  Widget _buildPhone({
    required double width,
    required double height,
    required Widget child,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Phone background
            Container(color: Colors.blue.shade100),
            // Phone content
            child,
          ],
        ),
      ),
    );
  }
}