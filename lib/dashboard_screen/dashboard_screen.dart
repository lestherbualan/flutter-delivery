import 'package:delivery/authentication_screen/login_screen.dart';
import 'package:delivery/commons/review_screen.dart';
import 'package:delivery/dashboard_screen/profile_screen.dart';
import 'package:delivery/dashboard_screen/search_screen.dart';
import 'package:delivery/map_app/map_controller.dart';
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
// import 'package:provider/provider.dart';
// import '../commons/sharedData.dart';
import '../delivery/schedule_delivery_screen.dart';
import '../home_screen/home_screen.dart';
import 'package:delivery/map_app/map_display.dart';
import 'package:showcaseview/showcaseview.dart';

import '../model/review.dart';
import '../model/user.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  late final MapInitializer _mapInitializer;
  late final MapDisplay _mapDisplay;
  late final MapTapController _mapTapController;
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
  int rate = 0;
  String? noteToRider;

  Color _motorBG = Colors.white;
  Color _carBG = Colors.white;
  Color _bikeBG = Colors.white;

  String imageFileUrl = '';
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // keys for the user guide.
  final GlobalKey _one = GlobalKey();
  final GlobalKey _two = GlobalKey();
  final GlobalKey _three = GlobalKey();
  final GlobalKey _four = GlobalKey();
  final GlobalKey _five = GlobalKey();
  final GlobalKey _six = GlobalKey();
  final GlobalKey _seven = GlobalKey();

  final Map<String, List<double>> vehicleWeightLimits = {
    'Motorcycle': [5, 15, 30, 40, 50],
    'Car': [50, 70, 85, 100],
    'Bike': [5, 7.5, 10],
  };

  List<double> items = [];

  double? selectedValue;

  int? _activeChip;
  int _rateFilterState = 0;
  int _chargeFilterState = 0;
  late GeoPoint sharedVar;

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

  // Logic for schedule order function e.g limit the user to use date and time that already passed.
  Future _selectDateAndTime() async {
    final DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      TimeOfDay initialTime = TimeOfDay.now();

      // If the selected date is not today, allow any time to be picked.
      if (pickedDate != DateTime(now.year, now.month, now.day)) {
        initialTime = const TimeOfDay(hour: 0, minute: 0); // Reset to midnight for other dates.
      }

      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
      );

      if (pickedTime != null) {
        // If the selected date is today and the time is in the past, reject the selection.
        if (pickedDate == DateTime(now.year, now.month, now.day) &&
            (pickedTime.hour < now.hour || (pickedTime.hour == now.hour && pickedTime.minute <= now.minute))) {
          // Show an error or return null
          print('Cannot select a time that has passed today');
          const snackBar = SnackBar(
            content: Text('Cannot select a time that has passed today'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red, // Optional customization
          );

          ScaffoldMessenger.of(context).showSnackBar(snackBar);
          return;
        }

        setState(() {
          selectedDate = pickedDate;
          selectedTime = pickedTime;
        });

        // Combine date and time
        selectedDate = selectedDate!.add(Duration(
          hours: selectedTime!.hour,
          minutes: selectedTime!.minute,
        ));

        print(selectedDate);
        print(selectedTime);

        return selectedDate;
      }
    }
  }

  void toggleDropdownVisibility() {
    setState(() {
      isDropdownVisible = !isDropdownVisible;
    });
  }

  // Function to push the data to firebase.
  Future insertOrder(Order order) async {
    await ref.set(order.toJson()).then((value) => {print(ref.key)}).catchError((onError) => {print(onError)});

    return ref.key;
  }

  // Function for pushing data to proposal table. this function is reused for basic order and scheduled order.
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

  // Function for the user to add review for the driver.
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

  // Getting the drivers that are online after the class is initialized.
  // see initState() function
  Future<void> _fetchUserList() async {
    DataSnapshot snapshot = await _userRef.get();
    _userRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        Map<dynamic, dynamic>? data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          List<Map<dynamic, dynamic>> userList = [];
          data.forEach((key, value) {
            if (value['isRider'] == true && value['online'] == true && value['isUserBooked'] == false) {
              //if(value['vehicle'] == )
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

  Future _fetchCurrentUserData() async {
    DatabaseReference currentUserRef = FirebaseDatabase.instance.ref('user/${user?.uid}');
    DataSnapshot currentUserSnapshot = await currentUserRef.get();

    return currentUserSnapshot.value;
  }

  Future<List<Map<dynamic, dynamic>>> checkDriverAvailability(List<Map<dynamic, dynamic>> userList, dynamic datetime) async {
    DatabaseReference _orderRef = FirebaseDatabase.instance.ref('order');
    DataSnapshot orderSnapshot = await _orderRef.get();

    DateTime requestedDateTime;
    if (datetime is String) {
      requestedDateTime = DateTime.parse(datetime);
    } else if (datetime is DateTime) {
      requestedDateTime = datetime;
    } else {
      throw ArgumentError("Invalid datetime type. Must be String or DateTime.");
    }

    List<Map<dynamic, dynamic>> availableDrivers = [];

    for (var userMap in userList) {
      bool isDriverAvailable = true;

      for (var child in orderSnapshot.children) {
        Map order = Map<dynamic, dynamic>.from(child.value as Map);

        if (order['driverId'] == userMap['uid']) {
          var orderDateRaw = order['date'];
          DateTime orderDateTime;

          if (orderDateRaw is String) {
            orderDateTime = DateTime.parse(orderDateRaw);
          } else if (orderDateRaw is DateTime) {
            orderDateTime = orderDateRaw;
          } else {
            continue;
          }

          if (orderDateTime == requestedDateTime) {
            isDriverAvailable = false;
            break;
          }
        }
      }

      if (isDriverAvailable) {
        availableDrivers.add(userMap);
      }
    }

    return availableDrivers;
  }

  @override
  void initState() {
    super.initState();
    // sharedVar = context.read<SharedData>().sharedVariable;
    // Initialize MapInitializer widget here

    setState(() {
      items = vehicleWeightLimits['Motorcycle']!;
    });
    _mapInitializer = MapInitializer(
      onUpdate: updateMapData,
    );

    getImageUrlFromFireStore();
    _fetchUserList();

    // getting current user that are logged for the user guide purposes.
    _fetchCurrentUserData().then((dynamic value) {
      if (value['firstOpen'] == true) {
        Future.delayed(const Duration(seconds: 3), () async {
          ShowCaseWidget.of(context).startShowCase([_one, _two, _three, _four, _five, _six, _seven]);
          DatabaseReference currentUserRef = FirebaseDatabase.instance.ref('user/${user?.uid}');
          currentUserRef.update({'firstOpen': false});
        });
      }
    });
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
                child: Showcase(
                  targetPadding: const EdgeInsets.all(1),
                  key: _seven,
                  title: 'Menu',
                  description: "If you want to edit your profile or logout in this app, you can do it here.",
                  tooltipBackgroundColor: Theme.of(context).primaryColor,
                  textColor: Colors.white,
                  targetShapeBorder: const CircleBorder(),
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
            ),
            if (isDropdownVisible)
              Positioned(
                top: 60, // Adjust position as needed
                right: 10, // Adjust position as needed
                child: Container(
                  width: 180,
                  height: 240,
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
                    // Profile Avatar dropdown happens here, each children refers to all items inside dropdown.
                    children: [
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
                      ListTile(
                        leading: const Icon(
                          Icons.calendar_month_outlined,
                          size: 25.0,
                          color: Colors.black,
                        ),
                        title: const Text('Scheduled Delivery List'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ScheduleDeliveryScreen()),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.calendar_month_outlined,
                          size: 25.0,
                          color: Colors.black,
                        ),
                        title: const Text('Reviews'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ReviewScreen()),
                          );
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
                          //style: TextStyle(fontSize: 12.0),
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
            // rectangular container view happens here.
            DraggableScrollableSheet(
              initialChildSize: 0.61,
              minChildSize: 0.2,
              maxChildSize: 0.61,
              snap: true,
              builder: (context, scrollController) => SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 10.0, bottom: 10.0),
                          child: Container(
                            width: 35.0, // Smaller width
                            height: 35.0, // Smaller height
                            decoration: const BoxDecoration(
                              color: Color(0xFFEDE1D5),
                              borderRadius: BorderRadius.all(Radius.circular(20.0)), // Half of width/height
                            ),
                            child: Center(
                              child: InkWell(
                                onTap: () {
                                  Navigator.pushReplacement(
                                      context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
                                },
                                child: Icon(
                                  Icons.refresh,
                                  color: Colors.black54,
                                  size: 30.0, // Adjust size to fit within the smaller container
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      height: 460,
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
                          // Showcase classes are refered to those user guide on the first open of the app.
                          Showcase(
                            targetPadding: const EdgeInsets.all(1),
                            key: _one,
                            title: 'Pick Up Point Address',
                            description: "Here shows the address of the first pin you choose as pick-up point.",
                            tooltipBackgroundColor: Theme.of(context).primaryColor,
                            textColor: Colors.white,
                            //targetShapeBorder: const CircleBorder(),
                            child: Container(
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
                          ),
                          const SizedBox(height: 2),
                          Showcase(
                            targetPadding: const EdgeInsets.all(1),
                            key: _two,
                            title: 'Drop off Point Address',
                            description: "Here shows the address of the last pin you choose as drop off.",
                            tooltipBackgroundColor: Theme.of(context).primaryColor,
                            textColor: Colors.white,
                            child: Container(
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
                          ),
                          const SizedBox(height: 2),
                          Showcase(
                            targetPadding: const EdgeInsets.all(1),
                            key: _three,
                            title: 'Travel Distance',
                            description: "Here shows the distance in kilometer for the rider to deliver.",
                            tooltipBackgroundColor: Theme.of(context).primaryColor,
                            textColor: Colors.white,
                            child: Text(
                              'Distance: ${distance.toStringAsFixed(2)} km',
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Expanded(
                            child: Showcase(
                              targetPadding: const EdgeInsets.all(1),
                              key: _four,
                              title: 'Vehicle Type',
                              description: "You can select your preferred vehicle depending on the item you want to be delivered",
                              tooltipBackgroundColor: Theme.of(context).primaryColor,
                              textColor: Colors.white,
                              child: Column(
                                children: [
                                  const Expanded(
                                    child: Center(
                                      child: Text("Choose Vehicles"),
                                    ),
                                  ),
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              if (_motorBG == Colors.white) {
                                                _motorBG = Colors.orange;
                                                _carBG = Colors.white;
                                                _bikeBG = Colors.white;
                                                vehicleType = 'Motorcycle';
                                                items = vehicleWeightLimits[vehicleType]!;
                                              } else {
                                                _motorBG = Colors.white;
                                              }
                                            });
                                          },
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                height: 80,
                                                margin: const EdgeInsets.symmetric(horizontal: 5.0),
                                                decoration: BoxDecoration(
                                                  color: _motorBG,
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: Colors.black),
                                                ),
                                                child: Center(
                                                  child: Transform.scale(
                                                    scale: 1.3,
                                                    child: Image.asset(
                                                      'assets/images/Motorcycle.png',
                                                      fit: BoxFit.contain,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 2), // Space between image and text
                                              const Text(
                                                'Motorcycle',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  //fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              if (_carBG == Colors.white) {
                                                _carBG = Colors.orange;
                                                _bikeBG = Colors.white;
                                                _motorBG = Colors.white;
                                                vehicleType = 'Car';
                                                items = vehicleWeightLimits[vehicleType]!;
                                              } else {
                                                _carBG = Colors.white;
                                              }
                                            });
                                          },
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                height: 80,
                                                margin: const EdgeInsets.symmetric(horizontal: 5.0),
                                                decoration: BoxDecoration(
                                                  color: _carBG,
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: Colors.black),
                                                ),
                                                child: Center(
                                                  child: Transform.scale(
                                                    scale: 1.2,
                                                    child: Image.asset(
                                                      'assets/images/Car.png',
                                                      fit: BoxFit.contain,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 2), // Space between image and text
                                              const Text(
                                                'Car',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  //fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              if (_bikeBG == Colors.white) {
                                                _bikeBG = Colors.orange;
                                                _carBG = Colors.white;
                                                _motorBG = Colors.white;
                                                vehicleType = 'Bike';
                                                items = vehicleWeightLimits[vehicleType]!;
                                              } else {
                                                _bikeBG = Colors.white;
                                              }
                                            });
                                          },
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                height: 80,
                                                margin: const EdgeInsets.symmetric(horizontal: 5.0),
                                                decoration: BoxDecoration(
                                                  color: _bikeBG,
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: Colors.black),
                                                ),
                                                child: Center(
                                                  child: Image.asset(
                                                    'assets/images/Bicycle.png',
                                                    fit: BoxFit.contain,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 2), // Space between image and text
                                              const Text(
                                                'Bicycle',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  //fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Showcase(
                                targetPadding: const EdgeInsets.all(1),
                                key: _five,
                                title: 'Package Weight',
                                description:
                                    "It's important that we know how much the item weight. You can select your item's estimated weight here.",
                                tooltipBackgroundColor: Theme.of(context).primaryColor,
                                textColor: Colors.white,
                                child: SizedBox(
                                  height: 60, // Adjust this value to reduce the height
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton2<double>(
                                      isExpanded: true,
                                      hint: Center(
                                        child: Text(
                                          'Package Weight',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Theme.of(context).hintColor,
                                          ),
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
                              ),
                              Showcase(
                                targetPadding: const EdgeInsets.all(1),
                                key: _six,
                                title: 'Amount payable',
                                description: "Rate is calculated depending on how far the item to be delivered.",
                                tooltipBackgroundColor: Theme.of(context).primaryColor,
                                textColor: Colors.white,
                                child: Stack(
                                  children: [
                                    Container(
                                      width: MediaQuery.of(context).size.width * 0.4, // Adjust width as needed
                                      decoration: BoxDecoration(
                                        color: Colors.white60,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.black,
                                        ),
                                      ),
                                      padding: const EdgeInsets.only(top: 20.0, bottom: 4.0),
                                      child: Center(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              //(rate * (distance.round())).toString(),
                                              rate.toString(),
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 25.0,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8.5, vertical: 4.5),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: Text(
                                          'Location Cost',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Theme.of(context).hintColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          GestureDetector(
                            onTap: () {
                              String? note;
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Note to your Rider'),
                                    content: TextFormField(
                                      onChanged: (value) {
                                        setState(() {
                                          note = value;
                                        });
                                      },
                                      decoration: const InputDecoration(
                                        hintText: 'Add note',
                                        border: OutlineInputBorder(),
                                      ),
                                      maxLines: null,
                                      keyboardType: TextInputType.multiline,
                                    ),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            noteToRider = note;
                                          });
                                          Navigator.pop(context);
                                        },
                                        child: const Text('Confirm'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white60,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.black,
                                ),
                              ),
                              padding: const EdgeInsets.only(top: 5.0, bottom: 5.0),
                              child: Padding(
                                padding: EdgeInsets.only(left: 15.0, right: 15.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'Note for your rider (Optional)',
                                          style: TextStyle(color: Colors.black),
                                        ),
                                        Visibility(
                                          visible: noteToRider?.isNotEmpty ?? false,
                                          child: Container(
                                            margin: const EdgeInsets.only(left: 5.0),
                                            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red[300]),
                                            width: 10,
                                            height: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Icon(
                                      Icons.edit,
                                      size: 25.0,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 10,
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
                                        rate: rate,
                                        isRated: false,
                                        noteToRider: noteToRider,
                                      );
                                      // By clicking Order Now button, this function triggers calling the insertOrder function.
                                      insertOrder(order).then((orderKey) async {
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (BuildContext context) {
                                            DatabaseReference userRef = FirebaseDatabase.instance.ref('user');

                                            return StatefulBuilder(builder: (listContext, setState) {
                                              // Showing the available driver pop up
                                              return AlertDialog(
                                                title: const Text('Available Riders'),
                                                content: Container(
                                                  width: double.maxFinite,
                                                  child: Stack(
                                                    children: [
                                                      Padding(
                                                        padding: const EdgeInsets.only(top: 8.0),
                                                        child: Row(
                                                          children: [
                                                            Padding(
                                                              padding: const EdgeInsets.only(left: 5, right: 5),
                                                              child: ActionChip(
                                                                avatar: _rateFilterState == 1
                                                                    ? const Icon(
                                                                        Icons.arrow_downward_outlined,
                                                                        color: Colors.black,
                                                                      )
                                                                    : const Icon(
                                                                        Icons.arrow_upward_outlined,
                                                                        color: Colors.black,
                                                                      ),
                                                                label: const Text('Rating'),
                                                                backgroundColor:
                                                                    _activeChip == 0 ? Colors.transparent : Colors.transparent,
                                                                onPressed: () {
                                                                  setState(() {
                                                                    _activeChip = 0;
                                                                    if (_rateFilterState == 0) {
                                                                      _userList.sort((a, b) {
                                                                        // Ensure that both maps have the 'driverSelfRating' key before comparing
                                                                        if (a.containsKey('driverRating') &&
                                                                            b.containsKey('driverRating')) {
                                                                          return b['driverRating'].compareTo(a['driverRating']);
                                                                        } else if (a.containsKey('driverRating')) {
                                                                          return -1; // a comes before b if only a has driverSelfRating
                                                                        } else if (b.containsKey('driverRating')) {
                                                                          return 1; // b comes before a if only b has driverSelfRating
                                                                        } else {
                                                                          return 0; // both are equal if neither has driverSelfRating
                                                                        }
                                                                      });
                                                                      _rateFilterState = 1;
                                                                    } else if (_rateFilterState == 1) {
                                                                      _userList.sort((a, b) {
                                                                        // Ensure that both maps have the 'driverRating' key before comparing
                                                                        if (a.containsKey('driverRating') &&
                                                                            b.containsKey('driverRating')) {
                                                                          return a['driverRating'].compareTo(b['driverRating']);
                                                                        } else if (a.containsKey('driverRating')) {
                                                                          return -1; // a comes before b if only a has driverRating
                                                                        } else if (b.containsKey('driverRating')) {
                                                                          return 1; // b comes before a if only b has driverRating
                                                                        } else {
                                                                          return 0; // both are equal if neither has driverRating
                                                                        }
                                                                      });
                                                                      _rateFilterState = 0;
                                                                    }
                                                                  });
                                                                  print(_userList);
                                                                },
                                                              ),
                                                            ),
                                                            Padding(
                                                              padding: const EdgeInsets.only(left: 5, right: 5),
                                                              child: ActionChip(
                                                                avatar: _chargeFilterState == 1
                                                                    ? const Icon(
                                                                        Icons.arrow_downward_outlined,
                                                                        color: Colors.black,
                                                                      )
                                                                    : const Icon(
                                                                        Icons.arrow_upward_outlined,
                                                                        color: Colors.black,
                                                                      ),
                                                                label: const Text('Charge'),
                                                                backgroundColor:
                                                                    _activeChip == 1 ? Colors.transparent : Colors.transparent,
                                                                onPressed: () {
                                                                  print(_chargeFilterState);
                                                                  setState(() {
                                                                    _activeChip = 1;
                                                                    if (_chargeFilterState == 0) {
                                                                      _userList.sort((a, b) {
                                                                        // Ensure that both maps have the 'driverSelfRating' key before comparing
                                                                        if (a.containsKey('driverSelfRating') &&
                                                                            b.containsKey('driverSelfRating')) {
                                                                          return b['driverSelfRating']
                                                                              .compareTo(a['driverSelfRating']);
                                                                        } else if (a.containsKey('driverSelfRating')) {
                                                                          return -1; // a comes before b if only a has driverSelfRating
                                                                        } else if (b.containsKey('driverSelfRating')) {
                                                                          return 1; // b comes before a if only b has driverSelfRating
                                                                        } else {
                                                                          return 0; // both are equal if neither has driverSelfRating
                                                                        }
                                                                      });
                                                                      _chargeFilterState = 1;
                                                                    } else if (_chargeFilterState == 1) {
                                                                      _userList.sort((a, b) {
                                                                        // Ensure that both maps have the 'driverRating' key before comparing
                                                                        if (a.containsKey('driverSelfRating') &&
                                                                            b.containsKey('driverSelfRating')) {
                                                                          return a['driverSelfRating']
                                                                              .compareTo(b['driverSelfRating']);
                                                                        } else if (a.containsKey('driverSelfRating')) {
                                                                          return -1; // a comes before b if only a has driverRating
                                                                        } else if (b.containsKey('driverSelfRating')) {
                                                                          return 1; // b comes before a if only b has driverRating
                                                                        } else {
                                                                          return 0; // both are equal if neither has driverRating
                                                                        }
                                                                      });
                                                                      _chargeFilterState = 0;
                                                                    }
                                                                  });
                                                                },
                                                              ),
                                                            )
                                                          ],
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding: const EdgeInsets.only(top: 50.0),
                                                        child: SizedBox(
                                                          width: double.maxFinite,
                                                          child: ListView.builder(
                                                            itemCount: _userList.length,
                                                            itemBuilder: (BuildContext context, int index) {
                                                              dynamic drivers;
                                                              print(order.vehicleType);
                                                              print(_userList[index]['vehicle']);
                                                              if (_userList[index]['vehicle'] == order.vehicleType) {
                                                                drivers = _userList[index];
                                                                return ListTile(
                                                                  leading: CircleAvatar(
                                                                    backgroundImage: drivers['profilePictureUrl'] != null &&
                                                                            drivers['profilePictureUrl'] != ''
                                                                        ? NetworkImage(drivers['profilePictureUrl'])
                                                                        : null,
                                                                  ),
                                                                  title: Text(drivers['displayName']),
                                                                  subtitle: Column(
                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                    children: [
                                                                      //Text(drivers['emailAddress']),
                                                                      Text('Rating : ${drivers['driverRating']}'),
                                                                      RatingBarIndicator(
                                                                        rating: double.parse(drivers['driverRating'].toString()),
                                                                        itemBuilder: (context, index) => const Icon(
                                                                          Icons.star,
                                                                          color: Colors.amber,
                                                                        ),
                                                                        itemCount: 5,
                                                                        itemSize: 15.0,
                                                                        direction: Axis.horizontal,
                                                                      ),
                                                                      Text('Charge : ${drivers['driverSelfRating'] ?? 0}')
                                                                    ],
                                                                  ),
                                                                  onTap: () {
                                                                    //Navigator.of(context).pop();
                                                                    showDialog(
                                                                      context: context,
                                                                      builder: (BuildContext context) {
                                                                        TextEditingController from =
                                                                            TextEditingController(text: startingPoint);
                                                                        TextEditingController to =
                                                                            TextEditingController(text: endPoint);
                                                                        TextEditingController weight = TextEditingController(
                                                                            text: order.netWeight.toString());
                                                                        TextEditingController vehicle =
                                                                            TextEditingController(text: order.vehicleType);
                                                                        TextEditingController note =
                                                                            TextEditingController(text: order.noteToRider);
                                                                        int reviewRate =
                                                                            order.rate + int.parse(drivers['driverSelfRating']);

                                                                        return AlertDialog(
                                                                          shape: RoundedRectangleBorder(
                                                                            borderRadius: BorderRadius.circular(20),
                                                                          ),
                                                                          content: SizedBox(
                                                                            width: 300, // Adjust width to fit the form
                                                                            child: Column(
                                                                              mainAxisSize: MainAxisSize.min,
                                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                                              children: [
                                                                                // const Text(
                                                                                //   "TIME:",
                                                                                //   style: TextStyle(
                                                                                //     fontWeight: FontWeight.bold,
                                                                                //     fontSize: 16,
                                                                                //   ),
                                                                                // ),
                                                                                // const SizedBox(height: 10),
                                                                                const Align(
                                                                                  alignment: Alignment.topLeft,
                                                                                  child: Text(
                                                                                    "FROM:",
                                                                                    style: TextStyle(
                                                                                      fontSize: 14,
                                                                                      fontWeight: FontWeight.w500,
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                const SizedBox(height: 5),
                                                                                TextField(
                                                                                  controller: from,
                                                                                  readOnly: true,
                                                                                  decoration: const InputDecoration(
                                                                                    border: OutlineInputBorder(),
                                                                                  ),
                                                                                ),
                                                                                const SizedBox(height: 10),
                                                                                const Align(
                                                                                  alignment: Alignment.topLeft,
                                                                                  child: Text(
                                                                                    "TO:",
                                                                                    style: TextStyle(
                                                                                      fontSize: 14,
                                                                                      fontWeight: FontWeight.w500,
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                const SizedBox(height: 5),
                                                                                TextField(
                                                                                  controller: to,
                                                                                  readOnly: true,
                                                                                  decoration: const InputDecoration(
                                                                                    border: OutlineInputBorder(),
                                                                                  ),
                                                                                ),
                                                                                const SizedBox(height: 10),
                                                                                const Align(
                                                                                  alignment: Alignment.topLeft,
                                                                                  child: Text(
                                                                                    "WEIGHT:",
                                                                                    style: TextStyle(
                                                                                      fontSize: 14,
                                                                                      fontWeight: FontWeight.w500,
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                const SizedBox(height: 5),
                                                                                TextField(
                                                                                  controller: weight,
                                                                                  readOnly: true,
                                                                                  decoration: const InputDecoration(
                                                                                    border: OutlineInputBorder(),
                                                                                  ),
                                                                                ),
                                                                                const SizedBox(height: 10),
                                                                                const Align(
                                                                                  alignment: Alignment.topLeft,
                                                                                  child: Text(
                                                                                    "VEHICLE USE:",
                                                                                    style: TextStyle(
                                                                                      fontSize: 14,
                                                                                      fontWeight: FontWeight.w500,
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                const SizedBox(height: 5),
                                                                                TextField(
                                                                                  controller: vehicle,
                                                                                  readOnly: true,
                                                                                  decoration: const InputDecoration(
                                                                                    border: OutlineInputBorder(),
                                                                                  ),
                                                                                ),
                                                                                const SizedBox(height: 10),
                                                                                const Align(
                                                                                  alignment: Alignment.topLeft,
                                                                                  child: Text(
                                                                                    "Note:",
                                                                                    style: TextStyle(
                                                                                      fontSize: 14,
                                                                                      fontWeight: FontWeight.w500,
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                const SizedBox(height: 5),
                                                                                TextField(
                                                                                  controller: note,
                                                                                  readOnly: true,
                                                                                  maxLines: 3,
                                                                                  decoration: const InputDecoration(
                                                                                    border: OutlineInputBorder(),
                                                                                  ),
                                                                                ),
                                                                                const SizedBox(height: 10),
                                                                                Row(
                                                                                  mainAxisAlignment:
                                                                                      MainAxisAlignment.spaceBetween,
                                                                                  children: [
                                                                                    const Text(
                                                                                      "TOTAL COST:",
                                                                                      style:
                                                                                          TextStyle(fontWeight: FontWeight.bold),
                                                                                    ),
                                                                                    Text(
                                                                                      reviewRate
                                                                                          .toString(), // Placeholder for total cost
                                                                                      style: const TextStyle(
                                                                                          fontSize: 30,
                                                                                          fontWeight: FontWeight.bold),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                          actions: [
                                                                            TextButton(
                                                                              onPressed: () {
                                                                                Navigator.of(context).pop(); // Close the dialog
                                                                              },
                                                                              child: const Text(
                                                                                "Cancel",
                                                                                style: TextStyle(color: Colors.red),
                                                                              ),
                                                                            ),
                                                                            TextButton(
                                                                              onPressed: () {
                                                                                // Add your action for "Proceed" here

                                                                                //Navigator.of(context).pop();
                                                                                //Navigator.of(listContext).pop();

                                                                                Proposal proposal = Proposal(
                                                                                    uid: drivers['uid'], orderId: orderKey);
                                                                                insertProposal(proposal).then((value) {
                                                                                  //Navigator.pop(context);
                                                                                  DatabaseReference orderReference =
                                                                                      FirebaseDatabase.instance
                                                                                          .ref('order/$orderKey');
                                                                                  orderReference.onValue
                                                                                      .listen((DatabaseEvent event) {
                                                                                    final data = event.snapshot.value;
                                                                                    print(data);
                                                                                    if (data != null &&
                                                                                        data is Map<Object?, Object?>) {
                                                                                      final dynamic status = data['status'];
                                                                                      dynamic driverId = drivers['uid'];
                                                                                      dynamic driverName = drivers['displayName'];
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
                                                                                                    Text(
                                                                                                        "Waiting for the rider to confirm"),
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
                                                                                                    Text(
                                                                                                        "Rider is on the way ..."),
                                                                                                  ],
                                                                                                ),
                                                                                              );
                                                                                            },
                                                                                          );
                                                                                        }
                                                                                        if (status == 'CANCELED') {
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
                                                                                                    Text(
                                                                                                        "Driver canceled the request!"),
                                                                                                  ],
                                                                                                ),
                                                                                              );
                                                                                            },
                                                                                          );
                                                                                          Future.delayed(
                                                                                              const Duration(seconds: 2), () {
                                                                                            Navigator.pop(
                                                                                                context); // Close the loading dialog
                                                                                            Navigator.pop(context);
                                                                                          });
                                                                                        }
                                                                                        if (status == 'COMPLETED') {
                                                                                          Navigator.pop(context);
                                                                                          ScaffoldMessenger.of(context)
                                                                                              .showSnackBar(
                                                                                            const SnackBar(
                                                                                                content:
                                                                                                    Text('Order is complete!')),
                                                                                          );
                                                                                          // Show the rating pop-up here
                                                                                          showDialog(
                                                                                            context: context,
                                                                                            barrierDismissible: false,
                                                                                            builder: (BuildContext context) {
                                                                                              int rating =
                                                                                                  0; // Initialize the rating variable

                                                                                              return AlertDialog(
                                                                                                title:
                                                                                                    const Text('Rate the Rider'),
                                                                                                content: Column(
                                                                                                  mainAxisSize: MainAxisSize.min,
                                                                                                  children: [
                                                                                                    const Text(
                                                                                                        'Please rate the rider for this delivery:'),
                                                                                                    // Star rating widget
                                                                                                    RatingBar.builder(
                                                                                                      initialRating:
                                                                                                          rating.toDouble(),
                                                                                                      minRating: 1,
                                                                                                      direction: Axis.horizontal,
                                                                                                      allowHalfRating: false,
                                                                                                      itemCount: 5,
                                                                                                      itemSize: 40,
                                                                                                      itemBuilder: (context, _) =>
                                                                                                          const Icon(
                                                                                                        Icons.star,
                                                                                                        color: Colors.amber,
                                                                                                      ),
                                                                                                      onRatingUpdate: (value) {
                                                                                                        rating = value
                                                                                                            .toInt(); // Update the rating value
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
                                                                                                      decoration:
                                                                                                          const InputDecoration(
                                                                                                        hintText:
                                                                                                            'Add your comments (optional)',
                                                                                                        border:
                                                                                                            OutlineInputBorder(),
                                                                                                      ),
                                                                                                      maxLines: null,
                                                                                                      keyboardType:
                                                                                                          TextInputType.multiline,
                                                                                                    ),
                                                                                                  ],
                                                                                                ),
                                                                                                actions: <Widget>[
                                                                                                  TextButton(
                                                                                                    onPressed: () async {
                                                                                                      Review review = Review(
                                                                                                        reviewerUserType:
                                                                                                            'Customer',
                                                                                                        driverId: driverId
                                                                                                                ?.toString() ??
                                                                                                            'Unknown Driver',
                                                                                                        driverName: driverName,
                                                                                                        orderId: orderKey ??
                                                                                                            'Unknown Order',
                                                                                                        rating: double.parse(
                                                                                                            rating?.toString() ??
                                                                                                                '0.0'),
                                                                                                        customerId: userId ??
                                                                                                            'Unknown User',
                                                                                                        customerName:
                                                                                                            user!.displayName ??
                                                                                                                '',
                                                                                                        message: commentText ??
                                                                                                            'No comment provided',
                                                                                                        timestamp: DateTime.now()
                                                                                                            .toString(),
                                                                                                      );
                                                                                                      await insertReview(review)
                                                                                                          .then((value) {
                                                                                                        Navigator.pop(context);
                                                                                                        Navigator.push(
                                                                                                          context,
                                                                                                          MaterialPageRoute(
                                                                                                              builder: (context) =>
                                                                                                                  const DashboardScreen()),
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
                                                                                      print(
                                                                                          "Data is null or not in the expected format.");
                                                                                    }
                                                                                  });
                                                                                });
                                                                              },
                                                                              child: const Text(
                                                                                "Proceed",
                                                                                style: TextStyle(color: Colors.green),
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        );
                                                                      },
                                                                    );
                                                                  },
                                                                );
                                                              }
                                                            },
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            });
                                          },
                                        ).then((value) {
                                          print('dialog is closed');
                                        });
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
                              const SizedBox(width: 10),
                              // Schedule Booking
                              OutlinedButton(
                                onPressed: () {
                                  // Select Date Function for schedule function. For Reference, see _selectDateAndTime function above.
                                  if (vehicleType.isNotEmpty &&
                                      netWeight != null &&
                                      (startingGeopoint.latitude != 0 &&
                                          startingGeopoint.longitude != 0 &&
                                          endingGeopoint.latitude != 0 &&
                                          endingGeopoint.longitude != 0)) {
                                    _selectDateAndTime().then((dateTime) {
                                      Order order = Order(
                                        name: user?.displayName ?? "No Name",
                                        date: dateTime.toString(),
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
                                        isScheduled: true,
                                        netWeight: netWeight!,
                                        driverId: '',
                                        rate: rate,
                                        isRated: false,
                                        noteToRider: noteToRider,
                                      );
                                      // By clicking Schedule Order button, this function triggers calling the insertOrder function. See insertOrder function above.
                                      if (dateTime != null) {
                                        checkDriverAvailability(_userList, dateTime).then((value) {
                                          _userList = value;
                                          insertOrder(order).then((orderKey) {
                                            showDialog(
                                              context: context,
                                              barrierDismissible: false,
                                              builder: (BuildContext context) {
                                                DatabaseReference userRef = FirebaseDatabase.instance.ref('user');

                                                return StatefulBuilder(builder: (context, setState) {
                                                  return AlertDialog(
                                                    title: const Text('Available Riders'),
                                                    content: Container(
                                                      width: double.maxFinite,
                                                      child: Stack(
                                                        children: [
                                                          Padding(
                                                            padding: const EdgeInsets.only(top: 8.0),
                                                            child: Row(
                                                              children: [
                                                                Padding(
                                                                  padding: const EdgeInsets.only(left: 5, right: 5),
                                                                  child: ActionChip(
                                                                    avatar: _rateFilterState == 1
                                                                        ? const Icon(
                                                                            Icons.arrow_upward_outlined,
                                                                            color: Colors.black,
                                                                          )
                                                                        : const Icon(
                                                                            Icons.arrow_downward_outlined,
                                                                            color: Colors.black,
                                                                          ),
                                                                    label: const Text('Rating'),
                                                                    backgroundColor: _activeChip == 0
                                                                        ? Colors.transparent
                                                                        : Colors.transparent,
                                                                    onPressed: () {
                                                                      setState(() {
                                                                        _activeChip = 0;
                                                                        if (_rateFilterState == 0) {
                                                                          _userList.sort((a, b) {
                                                                            // Ensure that both maps have the 'driverSelfRating' key before comparing
                                                                            if (a.containsKey('driverRating') &&
                                                                                b.containsKey('driverRating')) {
                                                                              return b['driverRating']
                                                                                  .compareTo(a['driverRating']);
                                                                            } else if (a.containsKey('driverRating')) {
                                                                              return -1; // a comes before b if only a has driverSelfRating
                                                                            } else if (b.containsKey('driverRating')) {
                                                                              return 1; // b comes before a if only b has driverSelfRating
                                                                            } else {
                                                                              return 0; // both are equal if neither has driverSelfRating
                                                                            }
                                                                          });
                                                                          _rateFilterState = 1;
                                                                        } else if (_rateFilterState == 1) {
                                                                          _userList.sort((a, b) {
                                                                            // Ensure that both maps have the 'driverRating' key before comparing
                                                                            if (a.containsKey('driverRating') &&
                                                                                b.containsKey('driverRating')) {
                                                                              return a['driverRating']
                                                                                  .compareTo(b['driverRating']);
                                                                            } else if (a.containsKey('driverRating')) {
                                                                              return -1; // a comes before b if only a has driverRating
                                                                            } else if (b.containsKey('driverRating')) {
                                                                              return 1; // b comes before a if only b has driverRating
                                                                            } else {
                                                                              return 0; // both are equal if neither has driverRating
                                                                            }
                                                                          });
                                                                          _rateFilterState = 0;
                                                                        }
                                                                      });
                                                                      print(_userList);
                                                                    },
                                                                  ),
                                                                ),
                                                                Padding(
                                                                  padding: const EdgeInsets.only(left: 5, right: 5),
                                                                  child: ActionChip(
                                                                    avatar: _chargeFilterState == 1
                                                                        ? const Icon(
                                                                            Icons.arrow_upward_outlined,
                                                                            color: Colors.black,
                                                                          )
                                                                        : const Icon(
                                                                            Icons.arrow_downward_outlined,
                                                                            color: Colors.black,
                                                                          ),
                                                                    label: const Text('Charge'),
                                                                    backgroundColor: _activeChip == 1
                                                                        ? Colors.transparent
                                                                        : Colors.transparent,
                                                                    onPressed: () {
                                                                      print(_chargeFilterState);
                                                                      setState(() {
                                                                        _activeChip = 1;
                                                                        if (_chargeFilterState == 0) {
                                                                          _userList.sort((a, b) {
                                                                            // Ensure that both maps have the 'driverSelfRating' key before comparing
                                                                            if (a.containsKey('driverSelfRating') &&
                                                                                b.containsKey('driverSelfRating')) {
                                                                              return b['driverSelfRating']
                                                                                  .compareTo(a['driverSelfRating']);
                                                                            } else if (a.containsKey('driverSelfRating')) {
                                                                              return -1; // a comes before b if only a has driverSelfRating
                                                                            } else if (b.containsKey('driverSelfRating')) {
                                                                              return 1; // b comes before a if only b has driverSelfRating
                                                                            } else {
                                                                              return 0; // both are equal if neither has driverSelfRating
                                                                            }
                                                                          });
                                                                          _chargeFilterState = 1;
                                                                        } else if (_chargeFilterState == 1) {
                                                                          _userList.sort((a, b) {
                                                                            // Ensure that both maps have the 'driverRating' key before comparing
                                                                            if (a.containsKey('driverSelfRating') &&
                                                                                b.containsKey('driverSelfRating')) {
                                                                              return a['driverSelfRating']
                                                                                  .compareTo(b['driverSelfRating']);
                                                                            } else if (a.containsKey('driverSelfRating')) {
                                                                              return -1; // a comes before b if only a has driverRating
                                                                            } else if (b.containsKey('driverSelfRating')) {
                                                                              return 1; // b comes before a if only b has driverRating
                                                                            } else {
                                                                              return 0; // both are equal if neither has driverRating
                                                                            }
                                                                          });
                                                                          _chargeFilterState = 0;
                                                                        }
                                                                      });
                                                                    },
                                                                  ),
                                                                )
                                                              ],
                                                            ),
                                                          ),
                                                          Padding(
                                                            padding: const EdgeInsets.only(top: 50.0),
                                                            child: SizedBox(
                                                              width: double.maxFinite,
                                                              child: ListView.builder(
                                                                itemCount: _userList.length,
                                                                itemBuilder: (BuildContext context, int index) {
                                                                  print(_userList[index]);
                                                                  dynamic drivers;
                                                                  if (_userList[index]['vehicle'] == order.vehicleType) {
                                                                    drivers = _userList[index];
                                                                    return ListTile(
                                                                      leading: CircleAvatar(
                                                                        backgroundImage: drivers['profilePictureUrl'] != null &&
                                                                                drivers['profilePictureUrl'] != ''
                                                                            ? NetworkImage(drivers['profilePictureUrl'])
                                                                            : null,
                                                                      ),
                                                                      title: Text(drivers['displayName']),
                                                                      subtitle: Column(
                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                        children: [
                                                                          //Text(drivers['emailAddress']),
                                                                          Text('Rating : ${drivers['driverRating']}'),
                                                                          RatingBarIndicator(
                                                                            rating:
                                                                                double.parse(drivers['driverRating'].toString()),
                                                                            itemBuilder: (context, index) => const Icon(
                                                                              Icons.star,
                                                                              color: Colors.amber,
                                                                            ),
                                                                            itemCount: 5,
                                                                            itemSize: 15.0,
                                                                            direction: Axis.horizontal,
                                                                          ),
                                                                          Text('Charge : ${drivers['driverSelfRating'] ?? 0}')
                                                                        ],
                                                                      ),
                                                                      onTap: () {
                                                                        Proposal proposal =
                                                                            Proposal(uid: drivers['uid'], orderId: orderKey);
                                                                        insertProposal(proposal).then((value) {
                                                                          //Navigator.pop(context);
                                                                          DatabaseReference orderReference =
                                                                              FirebaseDatabase.instance.ref('order/$orderKey');

                                                                          orderReference.update({'driverId': drivers['uid']});
                                                                          orderReference.onValue.listen((DatabaseEvent event) {
                                                                            final data = event.snapshot.value;
                                                                            print(data);
                                                                            if (data != null && data is Map<Object?, Object?>) {
                                                                              final dynamic status = data['status'];
                                                                              dynamic driverId = drivers['uid'];
                                                                              dynamic orderId = data['key'];
                                                                              dynamic userId = user?.uid;
                                                                              String commentText = '';

                                                                              Navigator.pop(context);
                                                                              Navigator.push(
                                                                                context,
                                                                                MaterialPageRoute(
                                                                                    builder: (context) =>
                                                                                        const DashboardScreen()),
                                                                              );

                                                                              if (status != null) {
                                                                                print(status);
                                                                              } else {
                                                                                print("Status not found in data.");
                                                                              }
                                                                            } else {
                                                                              print(
                                                                                  "Data is null or not in the expected format.");
                                                                            }
                                                                          });
                                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                                            const SnackBar(content: Text('Order Scheduled!')),
                                                                          );
                                                                        });
                                                                      },
                                                                    );
                                                                  }
                                                                },
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                });
                                              },
                                            );
                                          });
                                        });
                                      }
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
                                  foregroundColor: Colors.black54,
                                  padding: const EdgeInsets.only(top: 15.0, bottom: 15.0),
                                ),
                                child: const Icon(
                                  Icons.calendar_month,
                                  size: 30.0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
