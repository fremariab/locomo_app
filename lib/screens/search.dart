import 'search_results.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/services.dart';

class TravelHomePage extends StatelessWidget {
  TravelHomePage({Key? key}) : super(key: key);

  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section with red background
              Stack(
                children: [
                  CustomPaint(
                    size: Size(double.infinity, 225),
                    painter: RedCurvePainter(),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                   
                    child: Column(
                      children: [
                                                const SizedBox(height: 5),

                        Image.asset(
                          'assets/images/locomo_logo3.png',
                          width: 50,
                          height: 50,
                        ),

                        const SizedBox(height: 5),
                        // Title Text
                        const Text(
                          'What are your\ntravel plans?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Search Form Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Origin TextField
                    const TextField(
                      decoration: InputDecoration(
                        labelText: 'Origin',
                        labelStyle: TextStyle(
                          color: Color(0xFFD9D9D9),
                          fontWeight: FontWeight.w200, // Semi-bold weight
                          fontFamily: 'Poppins',
                          fontSize: 16,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFD9D9D9)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFD9D9D9)),
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFD9D9D9)),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFc32e31)),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFC32E31)),
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Destination TextField
                    const TextField(
                      decoration: InputDecoration(
                        labelText: 'Destination',
                        labelStyle: TextStyle(
                          color: Color(0xFFD9D9D9),
                          fontWeight: FontWeight.w200, // Semi-bold weight
                          fontFamily: 'Poppins',
                          fontSize: 16,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFD9D9D9)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFD9D9D9)),
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFD9D9D9)),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFc32e31)),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFC32E31)),
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        // Travel Preference TextField
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            iconEnabledColor: Color(0xFFFFFFFF),
                            focusColor: Color(0xFFFFFFFF),
                            dropdownColor: Color(0xFFd9d9d9),
                            iconDisabledColor: Color(0xFFFFFFFF),
                            decoration: InputDecoration(
                              labelText: 'Travel Preference',
                              labelStyle: TextStyle(
                                color: Color(0xFFD9D9D9),
                                fontWeight: FontWeight.w200,
                                fontFamily: 'Poppins',
                                fontSize: 16,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color(0xFFD9D9D9)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color(0xFFD9D9D9)),
                              ),
                              border: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color(0xFFD9D9D9)),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color(0xFFc32e31)),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color(0xFFC32E31)),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400,
                            ),
                            value: 'none', // default value
                            items: [
                              DropdownMenuItem(
                                value: 'none',
                                child: Text('None'),
                              ),
                              DropdownMenuItem(
                                value: 'shortest_time',
                                child: Text('Shortest Time'),
                              ),
                              DropdownMenuItem(
                                value: 'lowest_fare',
                                child: Text('Lowest Fare'),
                              ),
                              DropdownMenuItem(
                                value: 'fewest_transfers',
                                child: Text('Fewest Transfers'),
                              ),
                            ],
                            onChanged: (String? newValue) {},
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Budget TextField
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: _controller,
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+(\.\d{0,2})?')),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Budget',
                              labelStyle: TextStyle(
                                color: Color(0xFFD9D9D9),
                                fontWeight: FontWeight.w200,
                                fontFamily: 'Poppins',
                                fontSize: 16,
                              ),
                              prefixText: 'GHC ',
                              enabledBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color(0xFFD9D9D9)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color(0xFFD9D9D9)),
                              ),
                              border: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color(0xFFD9D9D9)),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color(0xFFc32e31)),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color(0xFFC32E31)),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Search Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const TravelResultsPage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC32E31),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Search',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.normal,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    // Divider
                    const Divider(
                      color: Color(0xFFD9D9D9),
                    ),
                    const SizedBox(height: 16),

                    // Explore Stations Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Explore Stations',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'See All',
                            style: TextStyle(
                              color: Color(0xFFC32E31),
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    // Station Cards
                    SizedBox(
                      height: 180,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          // Shiashie Station Card
                          StationCard(
                            imagePath: 'assets/images/onboarding11.png',
                            stationName: 'Shiashie Station',
                          ),
                          const SizedBox(width: 12),
                          // Kaneshie Station Card
                          StationCard(
                            imagePath: 'assets/images/onboarding8.jpg',
                            stationName: 'Kaneshie Station',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedLabelStyle: TextStyle(
          color: Color(0xFFC32E31),
          fontWeight: FontWeight.w500,
          fontSize: 12,
          fontFamily: 'Poppins',
        ),
        unselectedLabelStyle: TextStyle(
          color: Color(0xFFC32E31),
          fontWeight: FontWeight.w500,
          fontSize: 12,
          fontFamily: 'Poppins',
        ),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFFC32E31),
        unselectedItemColor: Color(0xFFD9D9D9),
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'Favourites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.help),
            label: 'Help',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class StationCard extends StatelessWidget {
  final String imagePath;
  final String stationName;

  const StationCard({
    Key? key,
    required this.imagePath,
    required this.stationName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 180,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Station Image
          Image.asset(
            imagePath,
            fit: BoxFit.cover,
          ),
          // Overlay Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
          // Station Name
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Text(
              stationName,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }
}

class RedCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Base color
    final Paint basePaint = Paint()
      ..color = const Color(0xFFB22A2D)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);

    // Lighter curved shape
    final Paint lightCurvePaint = Paint()
      ..color = const Color(0xFFC32E31)
      ..style = PaintingStyle.fill;

    final Path lightCurvePath = Path();
    lightCurvePath.moveTo(0, size.height * 0.6);
    lightCurvePath.quadraticBezierTo(
        size.width * 0.7, size.height * 0.2, size.width, size.height * 0.3);
    lightCurvePath.lineTo(size.width, 0);
    lightCurvePath.lineTo(0, 0);
    lightCurvePath.close();

    canvas.drawPath(lightCurvePath, lightCurvePaint);

    // Darker curved shape
    final Paint darkCurvePaint = Paint()
      ..color = const Color(0xFF9E2528)
      ..style = PaintingStyle.fill;

    final Path darkCurvePath = Path();
    darkCurvePath.moveTo(size.width * 0.5, size.height);
    darkCurvePath.quadraticBezierTo(
        size.width * 0.8, size.height * 0.7, size.width, size.height * 0.8);
    darkCurvePath.lineTo(size.width, size.height);
    darkCurvePath.close();

    canvas.drawPath(darkCurvePath, darkCurvePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
