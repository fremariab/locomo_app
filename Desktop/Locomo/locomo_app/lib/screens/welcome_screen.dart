import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Bus icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(
                Icons.directions_bus_outlined,
                size: 80,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            'LOCOMO',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 60),
          Container(
            width: 80,
            height: 4,
            color: const Color(0xFFBD3B36),
          ),
        ],
      ),
    );
  }
}