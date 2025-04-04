import 'package:flutter/material.dart';
import 'dart:async';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onComplete;
  
  const WelcomeScreen({super.key, required this.onComplete});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancel the timer when widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/locomo_logo.png',
            width: 200,
            height: 200,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.error, size: 50);
            },
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: 200,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(seconds: 2),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  backgroundColor: const Color(0xFFD9D9D9),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC32E31)),
                  minHeight: 5,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}