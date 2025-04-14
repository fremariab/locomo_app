import 'search_results.dart';
import 'package:flutter/material.dart';
import 'package:locomo_app/services/map_service.dart';
import 'package:locomo_app/services/route_service.dart';
import 'package:flutter/services.dart';
import 'package:locomo_app/widgets/MainScaffold.dart' as widgets;

class TravelHomePage extends StatefulWidget {
  const TravelHomePage({Key? key}) : super(key: key);

  @override
  State<TravelHomePage> createState() => _TravelHomePageState();
}

class _TravelHomePageState extends State<TravelHomePage> {
  final TextEditingController originController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  final TextEditingController _controller =
      TextEditingController(); // Budget controller

  @override
  Widget build(BuildContext context) {
    return widgets.MainScaffold(
      currentIndex: 0,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CustomPaint(
                    size: const Size(double.infinity, 225),
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
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: originController,
                      decoration: const InputDecoration(
                        labelText: 'Origin',
                        labelStyle: TextStyle(
                          color: Color(0xFFD9D9D9),
                          fontWeight: FontWeight.w200,
                          fontFamily: 'Poppins',
                          fontSize: 16,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFD9D9D9)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFD9D9D9)),
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: destinationController,
                      decoration: const InputDecoration(
                        labelText: 'Destination',
                        labelStyle: TextStyle(
                          color: Color(0xFFD9D9D9),
                          fontWeight: FontWeight.w200,
                          fontFamily: 'Poppins',
                          fontSize: 16,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFD9D9D9)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFD9D9D9)),
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            iconEnabledColor: Colors.white,
                            dropdownColor: const Color(0xFFd9d9d9),
                            decoration: const InputDecoration(
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
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400,
                            ),
                            value: 'lowest_fare',
                            items: const [
                              DropdownMenuItem(
                                  value: 'none', child: Text('None')),
                              DropdownMenuItem(
                                  value: 'shortest_time',
                                  child: Text('Shortest Time')),
                              DropdownMenuItem(
                                  value: 'lowest_fare',
                                  child: Text('Lowest Fare')),
                              DropdownMenuItem(
                                  value: 'fewest_transfers',
                                  child: Text('Fewest Transfers')),
                            ],
                            onChanged: (value) {},
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: _controller,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+(\.\d{0,2})?')),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Budget',
                              prefixText: 'GHC ',
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
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        // onPressed: () async {
                        //   final origin = originController.text.trim();
                        //   final destination = destinationController.text.trim();

                        //   if (origin.isEmpty || destination.isEmpty) {
                        //     ScaffoldMessenger.of(context).showSnackBar(
                        //       const SnackBar(
                        //           content: Text(
                        //               "Please enter both origin and destination")),
                        //     );
                        //     return;
                        //   }
                        //   try {
                        //     // Optional: Fetch and print directions from Google
                        //     final directions = await MapService.getDirections(
                        //       origin: origin,
                        //       destination: destination,
                        //     );

                        //     final steps = directions?['routes']?[0]?['legs']?[0]
                        //         ?['steps'];
                        //     if (steps != null) {
                        //       for (var step in steps) {
                        //         print(step['html_instructions']);
                        //       }
                        //     }

                        //     // Get selected preference from dropdown if applicable
                        //     final preference =
                        //         'lowest_fare'; // Hardcoded for now, or update from a controller/state

                        //     // Parse budget
                        //     final budgetText = _controller.text.trim();
                        //     final budget = budgetText.isNotEmpty
                        //         ? double.tryParse(budgetText)
                        //         : null;

                        //     // Fetch route suggestions from backend
                        //     final routes = await RouteService.searchRoutes(
                        //       origin: origin,
                        //       destination: destination,
                        //       preference: preference,
                        //       budget: budget,
                        //     );

                        //     if (routes.isEmpty) {
                        //       ScaffoldMessenger.of(context).showSnackBar(
                        //         const SnackBar(
                        //             content:
                        //                 Text("No suggested routes found.")),
                        //       );
                        //       return;
                        //     }

                        //     // Navigate to TravelResultsPage with the results
                        //     Navigator.push(
                        //       context,
                        //       MaterialPageRoute(
                        //         builder: (_) =>
                        //             TravelResultsPage(results: routes),
                        //       ),
                        //     );
                        //   } catch (e) {
                        //     ScaffoldMessenger.of(context).showSnackBar(
                        //       SnackBar(content: Text("Error: $e")),
                        //     );
                        //   }
                        // },
                        onPressed: () async {
                          final origin = originController.text.trim();
                          final destination = destinationController.text.trim();

                          if (origin.isEmpty || destination.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      "Please enter both origin and destination")),
                            );
                            return;
                          }

                          try {
                            // Use the composite route search that includes walking segments.
                            final compositeRoutes =
                                await RouteService.searchCompositeRoutes(
                              origin: origin,
                              destination: destination,
                              preference:
                                  'lowest_fare', // or get it from your dropdown
                              budget: double.tryParse(_controller.text.trim()),
                            );

                            if (compositeRoutes.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text("No suggested routes found.")),
                              );
                              return;
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    TravelResultsPage(results: compositeRoutes),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: $e")),
                            );
                          }
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
                    const Divider(color: Color(0xFFD9D9D9)),
                    const SizedBox(height: 16),
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
                    SizedBox(
                      height: 180,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          StationCard(
                            imagePath: 'assets/images/onboarding11.png',
                            stationName: 'Shiashie Station',
                          ),
                          const SizedBox(width: 12),
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
          Image.asset(
            imagePath,
            fit: BoxFit.cover,
          ),
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
                fontFamily: 'Poppins',
              ),
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
    // Base color background
    final Paint basePaint = Paint()
      ..color = const Color(0xFFB22A2D)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);

    // Light red curve
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

    // Darker bottom curve
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
