import 'package:delivery/map_app/map_initializer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import '../delivery/schedule_delivery_screen.dart';
import '../home_screen/home_screen.dart';
import 'package:delivery/map_app/map_display.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final MapInitializer _mapInitializer;

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  bool isDropdownVisible = false;

  // Variables to hold data received from MapDisplay
  String startingPoint = '';
  String endPoint = '';
  double distance = 0.0;

  // Function to update data received from MapDisplay
  void updateMapData(String start, String end, double dist) {
    setState(() {
      startingPoint = start;
      endPoint = end;
      distance = dist;
    });
  }

  Future<void> _selectDateAndTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          selectedDate = pickedDate;
          selectedTime = pickedTime;
          print(selectedDate);
          print(selectedTime);
        });
      }
    }
  }

  void toggleDropdownVisibility() {
    setState(() {
      isDropdownVisible = !isDropdownVisible;
    });
  }

  @override
  void initState() {
    super.initState();
    // Initialize MapInitializer widget here
    _mapInitializer = MapInitializer(
      onUpdate: updateMapData,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(child: _mapInitializer),
            // avatar
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () {
                  toggleDropdownVisibility();
                },
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.account_circle,
                    size: 40.0,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            if (isDropdownVisible)
              Positioned(
                top: 60, // Adjust position as needed
                right: 10, // Adjust position as needed
                child: Container(
                  width: 180,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 3,
                        offset:
                            const Offset(0, 2), // changes position of shadow
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Add your dropdown items here
                      ListTile(
                        leading: const Icon(
                          Icons.person,
                          size: 25.0,
                          color: Colors.black,
                        ),
                        title: const Text('Profile'),
                        onTap: () {
                          // Implement action for dropdown item 1
                          toggleDropdownVisibility(); // Close dropdown after action
                        },
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.calendar_month,
                          size: 25.0,
                          color: Colors.black,
                        ),
                        title: const Text(
                          'Scheduled Delivery',
                          style: TextStyle(fontSize: 12.0),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ScheduleDeliveryScreen()),
                          );
                          // Implement action for dropdown item 2
                          toggleDropdownVisibility(); // Close dropdown after action
                        },
                      ),
                    ],
                  ),
                ),
              ),
            // rectangular container
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 300,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10.0),
                    topRight: Radius.circular(10.0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Column(
                          children: [
                            Text(
                              'Starting Point: $startingPoint',
                              style: const TextStyle(color: Colors.black),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'End Point: $endPoint',
                              style: const TextStyle(color: Colors.black),
                            ),
                            Text(
                              'Distance: ${distance.toStringAsFixed(2)} km',
                              style: const TextStyle(color: Colors.black),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ), //
                    Expanded(
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: <Widget>[
                          Container(
                            width: 160,
                            height: 80,
                            margin: const EdgeInsets.only(right: 10.0),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed: null,
                                    icon: Image.asset(
                                      'assets/images/Motorcycle.png',
                                      width: 150.0,
                                      height: 100.0,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                          Container(
                            width: 160,
                            height: 80,
                            margin: const EdgeInsets.only(right: 10.0),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed: null,
                                    icon: Image.asset(
                                      'assets/images/Car.png',
                                      width: 150.0,
                                      height: 100.0,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                          Container(
                            width: 160,
                            height: 80,
                            margin: const EdgeInsets.only(right: 10.0),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed: null,
                                    icon: Image.asset(
                                      'assets/images/Bicycle.png',
                                      width: 150.0,
                                      height: 100.0,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                          // Add more containers as needed
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ), // Adjust spacing between ListView and buttons
                    Row(
                      children: [
                        Expanded(
                          // Order Now Button occupies all available space
                          child: TextButton(
                            onPressed: () {
                              // Add functionality for the "Order Now" button
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.all(15.0),
                            ),
                            child: const Text(
                              'Order Now',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                            width: 10), // Add spacing between buttons
                        TextButton(
                          onPressed: () {
                            _selectDateAndTime();
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black54,
                            padding:
                                const EdgeInsets.only(top: 15.0, bottom: 15.0),
                          ),
                          child: const Icon(
                            Icons.timer,
                            size: 30.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
