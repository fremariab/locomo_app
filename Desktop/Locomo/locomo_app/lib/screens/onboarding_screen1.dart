import 'package:flutter/material.dart';

class OnboardingScreen1 extends StatelessWidget {
  const OnboardingScreen1({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Logo at top
          const Padding(
            padding: EdgeInsets.only(top: 15.0),
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
          const SizedBox(height: 15),
          // Map with stations
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Map background (placeholder in this example)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'Map View',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    
                    // Central highlighted marker - Osu Elwak
                    Positioned(
                      left: constraints.maxWidth * 0.2,
                      top: constraints.maxHeight * 0.3,
                      child: _buildStationBox('Osu - Elwak', 'Budget: GHC 15', true),
                    ),
                    
                    // Papaye marker - top right
                    Positioned(
                      right: constraints.maxWidth * 0.1,
                      top: constraints.maxHeight * 0.25,
                      child: _buildStationBox('Papaye', 'GHC 3'),
                    ),
                    
                    // SSNIT marker - right side
                    Positioned(
                      right: constraints.maxWidth * 0.05,
                      top: constraints.maxHeight * 0.4,
                      child: _buildStationBox('SSNIT', 'GHC 4'),
                    ),
                    
                    // Prisons marker - bottom right
                    Positioned(
                      right: constraints.maxWidth * 0.15,
                      top: constraints.maxHeight * 0.55,
                      child: _buildStationBox('Prisons', 'GHC 5'),
                    ),
                    
                    // 37 Station marker - bottom
                    Positioned(
                      right: constraints.maxWidth * 0.2,
                      bottom: constraints.maxHeight * 0.1,
                      child: _buildStationBox('37 Station', 'GHC 3'),
                    ),
                    
                    // Connection lines for visual effect (optional)
                    CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: ConnectionPainter(),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 15),
          // Title and description
          const Text(
            'Your Journey,\nPerfectly Planned',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Effortlessly create and organize your dream trips. Start exploring now!',
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

  Widget _buildStationBox(String title, String price, [bool isHighlighted = false]) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: isHighlighted ? Border.all(color: Colors.red, width: 1) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isHighlighted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Route',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Text(
            price,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter to draw connection lines between stations
class ConnectionPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final dashPaint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    // Draw some connection lines (customize as needed)
    // Central point to Papaye
    canvas.drawLine(
      Offset(size.width * 0.3, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.25),
      dashPaint,
    );
    
    // Central point to SSNIT
    canvas.drawLine(
      Offset(size.width * 0.3, size.height * 0.35),
      Offset(size.width * 0.85, size.height * 0.4),
      paint,
    );
    
    // SSNIT to Prisons
    canvas.drawLine(
      Offset(size.width * 0.85, size.height * 0.42),
      Offset(size.width * 0.75, size.height * 0.55),
      dashPaint,
    );
    
    // Prisons to 37 Station
    canvas.drawLine(
      Offset(size.width * 0.75, size.height * 0.6),
      Offset(size.width * 0.7, size.height * 0.85),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}