import 'package:flutter/material.dart';

class TravelResultsPage extends StatelessWidget {
  const TravelResultsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFFC32E31),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Results',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Papaye Osu • Pent Hostel, Madina',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset(
                'assets/images/locomo_logo3.png',
                width: 30,
                height: 30,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.error, size: 50);
                },
              ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Sort Button
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFC32E31)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.sort, color: Color(0xFFC32E31), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Sort: Cheapest Route',
                          style: TextStyle(
                            color: Color(0xFFC32E31),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                
                // // Stops Button
                // Expanded(
                //   child: Container(
                //     height: 40,
                //     decoration: BoxDecoration(
                //       color: Colors.white,
                //       borderRadius: BorderRadius.circular(4),
                //       border: Border.all(color: const Color(0xFFC32E31)),
                //     ),
                //     child: const Center(
                //       child: Text(
                //         'Stops',
                //         style: TextStyle(
                //           color: Color(0xFFC32E31),
                //           fontSize: 12,
                //           fontWeight: FontWeight.w500,
                //         ),
                //       ),
                //     ),
                //   ),
                // ),
                // const SizedBox(width: 8),
                
                // // Departure Button
                // Expanded(
                //   child: Container(
                //     height: 40,
                //     decoration: BoxDecoration(
                //       color: Colors.white,
                //       borderRadius: BorderRadius.circular(4),
                //       border: Border.all(color: const Color(0xFFC32E31)),
                //     ),
                //     child: const Center(
                //       child: Text(
                //         'Departure',
                //         style: TextStyle(
                //           color: Color(0xFFC32E31),
                //           fontSize: 12,
                //           fontWeight: FontWeight.w500,
                //         ),
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
          
          // Recommended Label
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFC32E31),
            child: Row(
              children: const [
                Text(
                  'RECOMMENDED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 6),
                Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
          
          // Route Cards
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(0),
              children: [
                // Cheapest Route Card
                RouteCard(
                  label: 'Cheapest',
                  departureTime: '6:15 AM',
                  arrivalTime: '7:05 AM',
                  duration: '50m',
                  route: 'Osu → Madina Direct',
                  routeDetails: 'RE Junction, Osu → UPSA Junction',
                  transferCount: 0,
                  price: 'GHS 5.50',
                ),
                
                // Fastest Route Card
                RouteCard(
                  label: 'Fastest',
                  departureTime: '6:15 AM',
                  arrivalTime: '6:55 AM',
                  duration: '40m',
                  route: 'Osu → 37 → Madina',
                  routeDetails: 'Walk 10 min to Ako-Adjei',
                  transferCount: 1,
                  price: 'GHS 6.00',
                ),
                
                // Third Route Card
                RouteCard(
                  label: null,
                  departureTime: '6:15 AM',
                  arrivalTime: '7:20 AM',
                  duration: '1h5m',
                  route: 'Osu → Circle → UPSA',
                  routeDetails: 'Walk 5 min to RE Junction',
                  transferCount: 2,
                  price: 'GHS 7.50',
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: '',
          ),
        ],
      ),
    );
  }
}

class RouteCard extends StatelessWidget {
  final String? label;
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final String route;
  final String routeDetails;
  final int transferCount;
  final String price;

  const RouteCard({
    Key? key,
    this.label,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.route,
    required this.routeDetails,
    required this.transferCount,
    required this.price,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row with label and favorite button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Label (Cheapest, Fastest, etc.)
              label != null
                  ? Text(
                      label!,
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : const SizedBox(),
              // Favorite button
              const Icon(
                Icons.star_border,
                color: Colors.black54,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Times row
          Row(
            children: [
              // Departure time
              Text(
                departureTime,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              
              // Duration
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Text(
                      duration,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 50,
                      height: 1,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
              
              // Arrival time
              Text(
                arrivalTime,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              
              const Spacer(),
              
              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Text(
                    'One-way',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Route information
          Row(
            children: [
              const Icon(
                Icons.directions_bus_outlined,
                color: Colors.black54,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                route,
                style: const TextStyle(
                  fontSize: 12,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 6),
          
          // Route details
          Row(
            children: [
              const Icon(
                Icons.directions_walk,
                color: Colors.black54,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                routeDetails,
                style: const TextStyle(
                  fontSize: 12,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Transfers indicator
          if (transferCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$transferCount ${transferCount == 1 ? 'Transfer' : 'Transfers'} →',
                style: TextStyle(
                  color: Colors.red[800],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}