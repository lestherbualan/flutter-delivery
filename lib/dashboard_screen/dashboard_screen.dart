import 'package:delivery/authentication_screen/login_screen.dart';
import 'package:delivery/dashboard_screen/profile_screen.dart';
import 'package:delivery/map_app/map_initializer.dart';
import 'package:delivery/model/order.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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
  User? user = FirebaseAuth.instance.currentUser;
  late final MapInitializer _mapInitializer;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  DatabaseReference ref = FirebaseDatabase.instance.ref("order").push();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  bool isDropdownVisible = false;

  // Variables to hold data received from MapDisplay
  String startingPoint = '';
  String endPoint = '';
  GeoPoint startingGeopoint = GeoPoint(latitude: 0, longitude: 0);
  GeoPoint endingGeopoint = GeoPoint(latitude: 0, longitude: 0);
  double distance = 0.0;
  String vehicleType = '';
  double? netWeight;

  Color _motorBG = Colors.white;
  Color _carBG = Colors.white;
  Color _bikeBG = Colors.white;

  final List<double> items = [
    1,
    2,
    5,
    10,
    15,
  ];
  double? selectedValue;

  // Function to update data received from MapDisplay
  void updateMapData(
      String start, String end, double dist, GeoPoint long, GeoPoint lat) {
    setState(() {
      startingPoint = start;
      endPoint = end;
      distance = dist;
      startingGeopoint = long;
      endingGeopoint = lat;
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

  Future insertOrder(Order order) async {
    await ref
        .set(order.toJson())
        .then((value) => {print(ref.key)})
        .catchError((onError) => {print(onError)});

    return ref.key;
  }

  dropDownCallback(double? selectedValue) {
    if (selectedValue != null) {
      setState(() {
        netWeight = selectedValue;
      });
    }
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
                    Icons.account_circle_outlined,
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
                          Icons.person_2_outlined,
                          size: 25.0,
                          color: Colors.black,
                        ),
                        title: const Text('Profile'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ProfileScreen()),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.calendar_month_outlined,
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
                      ListTile(
                        leading: const Icon(
                          Icons.logout_outlined,
                          size: 25.0,
                          color: Colors.black,
                        ),
                        title: const Text(
                          'Logout',
                          style: TextStyle(fontSize: 12.0),
                        ),
                        onTap: () async {
                          await _auth.signOut().then((value) => {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const LoginScreen()),
                                )
                              });
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
              height: 400,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFEDE1D5),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                // Adjust width as needed
                                decoration: BoxDecoration(
                                  color: Colors.white60,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.black,
                                  ),
                                ),
                                padding: const EdgeInsets.only(
                                    top: 11.0, bottom: 11.0),
                                child: Center(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        startingPoint.isNotEmpty
                                            ? startingPoint
                                            : 'Starting Location',
                                        style: const TextStyle(
                                            color: Colors.black),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white60,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.black,
                                  ),
                                ),
                                padding: const EdgeInsets.only(
                                    top: 11.0, bottom: 11.0),
                                child: Center(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        endPoint.isNotEmpty
                                            ? endPoint
                                            : 'Ending Location',
                                        style: const TextStyle(
                                            color: Colors.black),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Distance: ${distance.toStringAsFixed(2)} km',
                                style: const TextStyle(color: Colors.black),
                              ),
                            ],
                          ),
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
                            decoration: BoxDecoration(
                              color: _motorBG,
                              borderRadius: const BorderRadius.all(
                                Radius.circular(10),
                              ),
                              border: Border.all(
                                color: Colors.black,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        if (_motorBG == Colors.white) {
                                          _motorBG = Colors.orange;
                                          _carBG = Colors.white;
                                          _bikeBG = Colors.white;

                                          vehicleType = 'MOTOR';
                                        } else {
                                          _motorBG = Colors.white;
                                        }
                                      });
                                    },
                                    icon: Image.asset(
                                      'assets/images/Motorcycle.png',
                                      width: 150.0,
                                      height: 90.0,
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
                            decoration: BoxDecoration(
                              color: _carBG,
                              borderRadius: const BorderRadius.all(
                                Radius.circular(10),
                              ),
                              border: Border.all(
                                color: Colors.black,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        if (_carBG == Colors.white) {
                                          _carBG = Colors.orange;
                                          _bikeBG = Colors.white;
                                          _motorBG = Colors.white;

                                          vehicleType = 'CAR';
                                        } else {
                                          _carBG = Colors.white;
                                        }
                                      });
                                    },
                                    icon: Image.asset(
                                      'assets/images/Car.png',
                                      width: 150.0,
                                      height: 90.0,
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
                            decoration: BoxDecoration(
                              color: _bikeBG,
                              borderRadius: const BorderRadius.all(
                                Radius.circular(10),
                              ),
                              border: Border.all(
                                color: Colors.black,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        if (_bikeBG == Colors.white) {
                                          _bikeBG = Colors.orange;
                                          _carBG = Colors.white;
                                          _motorBG = Colors.white;

                                          vehicleType = 'BIKE';
                                        } else {
                                          _bikeBG = Colors.white;
                                        }
                                      });
                                    },
                                    icon: Image.asset(
                                      'assets/images/Bicycle.png',
                                      width: 150.0,
                                      height: 90.0,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          height: 60, // Adjust this value to reduce the height
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton2<double>(
                              isExpanded: true,
                              hint: Text(
                                'Select Package Weight in kg',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                              items: items
                                  .map(
                                      (double item) => DropdownMenuItem<double>(
                                            value: item,
                                            child: Text(
                                              '$item kg',
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ))
                                  .toList(),
                              value: netWeight,
                              onChanged: (double? value) {
                                setState(() {
                                  netWeight = value;
                                });
                              },
                              buttonStyleData: ButtonStyleData(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                height: 40,
                                width: 180,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.black,
                                  ),
                                  color: Colors.white60,
                                ),
                              ),
                              menuItemStyleData: const MenuItemStyleData(
                                height: 40,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width *
                              0.4, // Adjust width as needed
                          decoration: BoxDecoration(
                            color: Colors.white60,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.black,
                            ),
                          ),
                          padding:
                              const EdgeInsets.only(top: 11.0, bottom: 11.0),
                          child: const Center(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '70 PHP',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 25.0,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Row(
                      children: [
                        Expanded(
                          // Order Now Button occupies all available space
                          child: OutlinedButton(
                            onPressed: () {
                              if (vehicleType.isNotEmpty &&
                                  netWeight != null &&
                                  (startingGeopoint.latitude != 0 &&
                                      startingGeopoint.longitude != 0 &&
                                      endingGeopoint.latitude != 0 &&
                                      endingGeopoint.longitude != 0)) {
                                Order order = Order(
                                  name: user?.displayName ?? "No Name",
                                  date: DateTime.now().toString(),
                                  startingGeoPoint: {
                                    'location': startingPoint,
                                    'longitude':
                                        startingGeopoint.longitude.toString(),
                                    'latitude':
                                        startingGeopoint.latitude.toString()
                                  },
                                  endingGeoPoint: {
                                    'location': endPoint,
                                    'longitude':
                                        endingGeopoint.longitude.toString(),
                                    'latitude':
                                        endingGeopoint.latitude.toString()
                                  },
                                  distance: distance.toString(),
                                  status: 'ACTIVE',
                                  uid: user?.uid ?? "No UID",
                                  vehicleType: vehicleType,
                                  isScheduled: false,
                                  netWeight: netWeight!,
                                );
                                insertOrder(order).then((value) {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (BuildContext context) {
                                      return const AlertDialog(
                                        content: Row(
                                          children: [
                                            CircularProgressIndicator(),
                                            SizedBox(width: 20),
                                            Text(
                                                "Waiting for driver to accept..."),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                  DatabaseReference orderReference =
                                      FirebaseDatabase.instance
                                          .ref('order/${value}');

                                  orderReference.onValue
                                      .listen((DatabaseEvent event) {
                                    final data = event.snapshot.value;
                                    if (data != null &&
                                        data is Map<Object?, Object?>) {
                                      final dynamic status = data['status'];
                                      if (status != null) {
                                        print(status);
                                        if (status == 'ACCEPTED') {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'A driver accepted the order!')),
                                          );
                                        }
                                      } else {
                                        print("Status not found in data.");
                                      }
                                    } else {
                                      print(
                                          "Data is null or not in the expected format.");
                                    }
                                  });
                                });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Please fill in required data'),
                                    duration: Duration(milliseconds: 500),
                                  ),
                                );
                              }
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
                        OutlinedButton(
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
                            Icons.timer_outlined,
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
