import 'package:delivery/dashboard_screen/profile_screen.dart';
import 'package:delivery/driver/driver_actions.dart';
import 'package:delivery/model/order.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../authentication_screen/login_screen.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({Key? key}) : super(key: key);

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class OrderEntry {
  final String key;
  final Order order;

  OrderEntry({required this.key, required this.order});
}

class _DriverDashboardState extends State<DriverDashboard> {
  DatabaseReference orderRef = FirebaseDatabase.instance.ref('order');
  List<Order> orderList = [];
  bool isDropdownVisible = false; // Added to control dropdown visibility
  Map<String, Order> sample = {};
  Map<String, Order> orders = {};
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user = FirebaseAuth.instance.currentUser;
  final DatabaseReference userRef = FirebaseDatabase.instance.ref('user');
  String imageFileUrl = '';
  final FirebaseStorage _storage = FirebaseStorage.instance;
  double completedCounter = 0;
  DateFormat formatter = DateFormat('yyyy-MM-dd hh:mm a');

  void toggleDropdownVisibility() {
    setState(() {
      isDropdownVisible = !isDropdownVisible;
    });
  }

  void fetchData() {
    DatabaseReference ordersRef = FirebaseDatabase.instance.ref('order');

    ordersRef.onValue.listen((DatabaseEvent event) {
      dynamic snapshotValue = event.snapshot.value;
      if (snapshotValue != null && snapshotValue is Map<dynamic, dynamic>) {
        snapshotValue.forEach((key, value) {
          dynamic orderData = value;
          if (orderData['status'] == 'ACTIVE') {
            setState(() {
              Order order = Order(
                key: key,
                startingGeoPoint: Map<String, dynamic>.from(orderData['startingGeoPoint']),
                endingGeoPoint: Map<String, dynamic>.from(orderData['endingGeoPoint']),
                distance: orderData['distance'],
                uid: orderData['uid'],
                status: orderData['status'],
                date: orderData['date'],
                vehicleType: orderData['vehicleType'],
                name: orderData['name'],
                isScheduled: orderData['isScheduled'],
                netWeight: double.parse(orderData['netWeight'].toString()),
                rate: orderData['rate'],
              );
              orderList.add(order);
            });
          }
        });
      } else {
        print("Snapshot value is not of type Map<String, dynamic>");
      }
    });
  }

  void fetchProposal() async {
    DatabaseReference proposalRef = FirebaseDatabase.instance.ref('proposal');
    final ref = FirebaseDatabase.instance.ref();
    orderList.clear();

    proposalRef.onValue.listen((DatabaseEvent event) {
      dynamic proposalSnapshotValue = event.snapshot.value;
      if (proposalSnapshotValue != null && proposalSnapshotValue is Map<dynamic, dynamic>) {
        proposalSnapshotValue.forEach((key, value) async {
          dynamic proposalData = value;
          if (proposalData['uid'] == user?.uid) {
            DataSnapshot orderDataSnapshot = await ref.child('order/${proposalData['orderId']}').get();
            dynamic orderData = orderDataSnapshot.value;
            if (orderDataSnapshot.exists) {
              //print(orderData.value);
              if (orderData['status'] == 'PROPOSE' || orderData['status'] == 'ACCEPTED') {
                setState(() {
                  Order order = Order(
                    key: orderDataSnapshot.key,
                    startingGeoPoint: Map<String, dynamic>.from(orderData['startingGeoPoint']),
                    endingGeoPoint: Map<String, dynamic>.from(orderData['endingGeoPoint']),
                    distance: orderData['distance'],
                    uid: orderData['uid'],
                    status: orderData['status'],
                    date: orderData['date'],
                    vehicleType: orderData['vehicleType'],
                    name: orderData['name'],
                    isScheduled: orderData['isScheduled'],
                    netWeight: double.parse(orderData['netWeight'].toString()),
                    rate: orderData['rate'],
                  );
                  orderList.add(order);
                });
              }

              if (orderData['status'] == 'COMPLETED') {
                setState(() {
                  completedCounter = completedCounter + 70;
                });
              }
            } else {
              print('No data available.');
            }
          }
        });
      }
    });
  }

  Future getImageUrlFromFireStore() async {
    Reference ref = _storage.ref().child('profile_pictures/${user?.uid}.jpg');

    String imageUrl = await ref.getDownloadURL();
    setState(() {
      imageFileUrl = imageUrl;
    });
  }

  Future getTotalEarning() async {
    Reference ref = _storage.ref().child('profile_pictures/${user?.uid}.jpg');

    String imageUrl = await ref.getDownloadURL();
    setState(() {
      imageFileUrl = imageUrl;
    });
  }

  Future setOnlineStatus() async {
    final DatabaseReference userStatusRef = userRef.child(user!.uid);
    final DatabaseReference connectedRef = FirebaseDatabase.instance.ref().child('.info/connected');
    print(connectedRef);
    connectedRef.onValue.listen((event) {
      final Object isConnected = event.snapshot.value ?? false;

      if (isConnected != null) {
        userStatusRef.update({'online': true});
        userStatusRef.onDisconnect().update({'online': false});
      }
    });
  }

  Future<void> _refresh() async {
    fetchProposal();
  }

  @override
  void initState() {
    super.initState();
    //fetchData();
    fetchProposal();
    getImageUrlFromFireStore();
    setOnlineStatus();

    // connectedRef.onValue.listen((event) {
    //   final Object isConnected = event.snapshot.value ?? false;

    //   if (isConnected != null) {
    //     userStatusRef.set({'online': true});
    //     userStatusRef.onDisconnect().set({'online': false});
    //   }
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDE1D5),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SafeArea(
          child: Material(
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome, ${user?.displayName}!',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const Text(
                                'Here is the list of orders:',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              toggleDropdownVisibility();
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              padding: const EdgeInsets.all(8),
                              child: CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.transparent,
                                backgroundImage: imageFileUrl.isNotEmpty ? NetworkImage(imageFileUrl) : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // dashboard money counter card
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Card(
                            margin: const EdgeInsets.all(5.0),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  const Text(
                                    'Earned',
                                    style: TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10.0),
                                  Text(
                                    completedCounter.toString(),
                                    style: const TextStyle(
                                      fontSize: 24.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Card(
                            margin: const EdgeInsets.all(5.0),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  const Text(
                                    'Pending Request',
                                    style: TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10.0),
                                  Text(
                                    orderList.length.toString(),
                                    style: const TextStyle(
                                      fontSize: 24.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Padding(
                      padding: EdgeInsets.only(left: 10.0),
                      child: Text('Pending for Acceptance:'),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: orderList.length,
                        itemBuilder: (context, index) {
                          Order orderInfo = orderList[index];
                          return ListTile(
                            title: Text('Order from ${orderInfo.name}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Date: ${formatter.format(DateTime.parse(orderInfo.date))}'),
                                Text('Weight: ${orderInfo.netWeight}kg      Vehicle Type: ${orderInfo.vehicleType}'),
                                // Add more fields as needed
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => DriverActions(orderInformation: orderInfo)),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
                // avatar dropdown
                if (isDropdownVisible)
                  Positioned(
                    top: 60, // Adjust position as needed
                    right: 10, // Adjust position as needed
                    child: Container(
                      width: 180,
                      height: 150,
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
                          ListTile(
                            leading: const Icon(
                              Icons.person_2_outlined,
                              size: 25.0,
                              color: Colors.black,
                            ),
                            title: const Text('Profile'),
                            onTap: () {
                              // Implement action for dropdown item 1
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => ProfileScreen()),
                              );
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
                              await _auth.signOut().then((value) {
                                DatabaseReference userStatusRef = userRef.child(user!.uid);
                                userStatusRef.update({'online': false});
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                                );
                              });
                              // Implement action for dropdown item 3
                              toggleDropdownVisibility(); // Close dropdown after action
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
