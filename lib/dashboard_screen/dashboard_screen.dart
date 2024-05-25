import 'package:delivery/authentication_screen/login_screen.dart';
import 'package:delivery/dashboard_screen/profile_screen.dart';
import 'package:delivery/map_app/map_initializer.dart';
import 'package:delivery/model/order.dart';
import 'package:delivery/model/proposal.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../delivery/schedule_delivery_screen.dart';
import '../home_screen/home_screen.dart';
import 'package:delivery/map_app/map_display.dart';

import '../model/review.dart';

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
  final DatabaseReference _userRef = FirebaseDatabase.instance.ref('user');
  final DatabaseReference _proposalRef = FirebaseDatabase.instance.ref('proposal').push();
  List<Map<dynamic, dynamic>> _userList = [];

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
  int rate = 25;

  Color _motorBG = Colors.white;
  Color _carBG = Colors.white;
  Color _bikeBG = Colors.white;

  String imageFileUrl = '';
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final List<double> items = [
    1,
    2,
    5,
    10,
    15,
  ];
  double? selectedValue;

  // Function to update data received from MapDisplay
  void updateMapData(String start, String end, double dist, GeoPoint long, GeoPoint lat) {
    setState(() {
      startingPoint = start;
      endPoint = end;
      distance = dist;
      startingGeopoint = long;
      endingGeopoint = lat;
      rate = (rate + (5 * distance)).toInt();
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
    await ref.set(order.toJson()).then((value) => {print(ref.key)}).catchError((onError) => {print(onError)});

    return ref.key;
  }

  Future insertProposal(Proposal proposal) async {
    await _proposalRef
        .set(proposal.toJson())
        .then((value) => {print(_proposalRef.key)})
        .catchError((onError) => {print(onError)});

    return _proposalRef.key;
  }

  dropDownCallback(double? selectedValue) {
    if (selectedValue != null) {
      setState(() {
        netWeight = selectedValue;
      });
    }
  }

  Future insertReview(Review review) async {
    DatabaseReference reviewRef = FirebaseDatabase.instance.ref("review").push();
    int counter = 0;
    List driverReviewList = [];
    await reviewRef.set(review.toJson()).then((value) async {
      print(reviewRef.key);
      DatabaseReference newReviewRef = FirebaseDatabase.instance.ref("review");
      final reviewSnapshot = await newReviewRef.get();
      Map<dynamic, dynamic> reviews = reviewSnapshot.value as Map<dynamic, dynamic>;

      reviews.forEach((key, value) {
        if (value['driverId'] == review.driverId) {
          driverReviewList.add(value['rating']);
          counter++;
        }
      });
      int totalRating = driverReviewList.reduce((value, element) => value + element);

      double calculatedRating = totalRating / counter;
      calculatedRating = double.parse(calculatedRating.toStringAsFixed(2));

      DatabaseReference driver = FirebaseDatabase.instance.ref("user/${review.driverId}");
      driver.update({'driverRating': calculatedRating});
    }).catchError((onError) => {print(onError)});
  }

  Future getImageUrlFromFireStore() async {
    Reference ref = _storage.ref().child('profile_pictures/${user?.uid}.jpg');

    String imageUrl = await ref.getDownloadURL();
    setState(() {
      imageFileUrl = imageUrl;
    });
  }

  Future<void> _fetchUserList() async {
    DataSnapshot snapshot = await _userRef.get();
    _userRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        Map<dynamic, dynamic>? data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          List<Map<dynamic, dynamic>> userList = [];
          data.forEach((key, value) {
            if (value['isRider'] == true && value['online'] == true) {
              userList.add(Map<dynamic, dynamic>.from(value));
            }
          });
          userList.sort((a, b) => b['driverRating'].compareTo(a['driverRating']));
          setState(() {
            _userList = userList;
          });
        }
      } else {
        print('No data available.');
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // Initialize MapInitializer widget here
    _mapInitializer = MapInitializer(
      onUpdate: updateMapData,
    );
    getImageUrlFromFireStore();
    _fetchUserList();
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
                  padding: const EdgeInsets.all(3),
                  child: CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.transparent,
                    backgroundImage: imageFileUrl.isNotEmpty ? NetworkImage(imageFileUrl) : null,
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
                        offset: const Offset(0, 2), // changes position of shadow
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
                            MaterialPageRoute(builder: (context) => ProfileScreen()),
                          );
                        },
                      ),
                      // ListTile(
                      //   leading: const Icon(
                      //     Icons.calendar_month_outlined,
                      //     size: 25.0,
                      //     color: Colors.black,
                      //   ),
                      //   title: const Text(
                      //     'Scheduled Delivery',
                      //     style: TextStyle(fontSize: 12.0),
                      //   ),
                      //   onTap: () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(builder: (context) => ScheduleDeliveryScreen()),
                      //     );
                      //     // Implement action for dropdown item 2
                      //     toggleDropdownVisibility(); // Close dropdown after action
                      //   },
                      // ),
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
                                  MaterialPageRoute(builder: (context) => const LoginScreen()),
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
                                padding: const EdgeInsets.only(top: 11.0, bottom: 11.0),
                                child: Center(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        startingPoint.isNotEmpty ? startingPoint : 'Starting Location',
                                        style: const TextStyle(color: Colors.black),
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
                                padding: const EdgeInsets.only(top: 11.0, bottom: 11.0),
                                child: Center(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        endPoint.isNotEmpty ? endPoint : 'Ending Location',
                                        style: const TextStyle(color: Colors.black),
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
                                  .map((double item) => DropdownMenuItem<double>(
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
                                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                          width: MediaQuery.of(context).size.width * 0.4, // Adjust width as needed
                          decoration: BoxDecoration(
                            color: Colors.white60,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.black,
                            ),
                          ),
                          padding: const EdgeInsets.only(top: 11.0, bottom: 11.0),
                          child: Center(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  //(rate * (distance.round())).toString(),
                                  rate.toString(),
                                  style: const TextStyle(color: Colors.black, fontSize: 25.0, fontWeight: FontWeight.bold),
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
                                      'longitude': startingGeopoint.longitude.toString(),
                                      'latitude': startingGeopoint.latitude.toString()
                                    },
                                    endingGeoPoint: {
                                      'location': endPoint,
                                      'longitude': endingGeopoint.longitude.toString(),
                                      'latitude': endingGeopoint.latitude.toString()
                                    },
                                    distance: distance.toString(),
                                    status: 'PROPOSE',
                                    uid: user?.uid ?? "No UID",
                                    vehicleType: vehicleType,
                                    isScheduled: false,
                                    netWeight: netWeight!,
                                    driverId: '',
                                    rate: (rate * (distance.round())).toInt());
                                insertOrder(order).then((orderKey) async {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (BuildContext context) {
                                      DatabaseReference userRef = FirebaseDatabase.instance.ref('user');

                                      return AlertDialog(
                                        title: const Text('Available Drivers'),
                                        content: Container(
                                          width: double.maxFinite,
                                          child: ListView.builder(
                                            itemCount: _userList.length,
                                            itemBuilder: (BuildContext context, int index) {
                                              final drivers = _userList[index];
                                              return ListTile(
                                                leading: CircleAvatar(
                                                  backgroundImage:
                                                      drivers['profilePictureUrl'] != null && drivers['profilePictureUrl'] != ''
                                                          ? NetworkImage(drivers['profilePictureUrl'])
                                                          : null,
                                                ),
                                                title: Text(drivers['displayName']),
                                                subtitle: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    //Text(drivers['emailAddress']),
                                                    Text('Rating: ${drivers['driverRating']}'),
                                                  ],
                                                ),
                                                onTap: () {
                                                  Proposal proposal = Proposal(uid: drivers['uid'], orderId: orderKey);
                                                  insertProposal(proposal).then((value) {
                                                    //Navigator.pop(context);
                                                    DatabaseReference orderReference =
                                                        FirebaseDatabase.instance.ref('order/$orderKey');
                                                    orderReference.onValue.listen((DatabaseEvent event) {
                                                      final data = event.snapshot.value;
                                                      print(data);
                                                      if (data != null && data is Map<Object?, Object?>) {
                                                        final dynamic status = data['status'];
                                                        dynamic driverId = drivers['uid'];
                                                        dynamic orderId = data['key'];
                                                        dynamic userId = user?.uid;
                                                        String commentText = '';
                                                        if (status != null) {
                                                          print(status);
                                                          if (status == 'PROPOSE') {
                                                            showDialog(
                                                              context: context,
                                                              barrierDismissible: false,
                                                              builder: (BuildContext context) {
                                                                return const AlertDialog(
                                                                  content: Row(
                                                                    children: [
                                                                      CircularProgressIndicator(),
                                                                      SizedBox(width: 20),
                                                                      Text("Waiting for the driver to accept"),
                                                                    ],
                                                                  ),
                                                                );
                                                              },
                                                            );
                                                          }
                                                          if (status == 'ACCEPTED') {
                                                            print('driver id here');
                                                            print(data);
                                                            Navigator.pop(context);
                                                            showDialog(
                                                              context: context,
                                                              barrierDismissible: false,
                                                              builder: (BuildContext context) {
                                                                return const AlertDialog(
                                                                  content: Row(
                                                                    children: [
                                                                      CircularProgressIndicator(),
                                                                      SizedBox(width: 20),
                                                                      Text("Driver is on the way ..."),
                                                                    ],
                                                                  ),
                                                                );
                                                              },
                                                            );
                                                          }
                                                          if (status == 'COMPLETED') {
                                                            Navigator.pop(context);
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              const SnackBar(content: Text('Order is complete!')),
                                                            );
                                                            // Show the rating pop-up here
                                                            showDialog(
                                                              context: context,
                                                              barrierDismissible: false,
                                                              builder: (BuildContext context) {
                                                                int rating = 0; // Initialize the rating variable

                                                                return AlertDialog(
                                                                  title: const Text('Rate the driver'),
                                                                  content: Column(
                                                                    mainAxisSize: MainAxisSize.min,
                                                                    children: [
                                                                      const Text('Please rate the driver for this order:'),
                                                                      // Star rating widget
                                                                      RatingBar.builder(
                                                                        initialRating: rating.toDouble(),
                                                                        minRating: 1,
                                                                        direction: Axis.horizontal,
                                                                        allowHalfRating: false,
                                                                        itemCount: 5,
                                                                        itemSize: 40,
                                                                        itemBuilder: (context, _) => const Icon(
                                                                          Icons.star,
                                                                          color: Colors.amber,
                                                                        ),
                                                                        onRatingUpdate: (value) {
                                                                          rating = value.toInt(); // Update the rating value
                                                                        },
                                                                      ),
                                                                      const SizedBox(height: 20),
                                                                      // Text input for comments
                                                                      TextFormField(
                                                                        onChanged: (value) {
                                                                          setState(() {
                                                                            commentText = value;
                                                                          });
                                                                        },
                                                                        decoration: const InputDecoration(
                                                                          hintText: 'Add your comments (optional)',
                                                                          border: OutlineInputBorder(),
                                                                        ),
                                                                        maxLines: null,
                                                                        keyboardType: TextInputType.multiline,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  actions: <Widget>[
                                                                    TextButton(
                                                                      onPressed: () async {
                                                                        Review review = Review(
                                                                          driverId: driverId?.toString() ?? 'Unknown Driver',
                                                                          orderId: orderId ?? 'Unknown Order',
                                                                          rating: double.parse(rating?.toString() ?? '0.0'),
                                                                          userId: userId ?? 'Unknown User',
                                                                          message: commentText ?? 'No comment provided',
                                                                        );
                                                                        await insertReview(review).then((value) {
                                                                          Navigator.pop(context);
                                                                          Navigator.push(
                                                                            context,
                                                                            MaterialPageRoute(
                                                                                builder: (context) => const DashboardScreen()),
                                                                          );
                                                                          //Navigator.pop(context);
                                                                        });
                                                                      },
                                                                      child: const Text('Submit'),
                                                                    ),
                                                                  ],
                                                                );
                                                              },
                                                            );
                                                          }
                                                        } else {
                                                          print("Status not found in data.");
                                                        }
                                                      } else {
                                                        print("Data is null or not in the expected format.");
                                                      }
                                                    });
                                                  });
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                  // here
                                });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please fill in required data'),
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
                              'Book Now',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10), // Add spacing between buttons
                        OutlinedButton(
                          onPressed: () {
                            _selectDateAndTime();
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black54,
                            padding: const EdgeInsets.only(top: 15.0, bottom: 15.0),
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
