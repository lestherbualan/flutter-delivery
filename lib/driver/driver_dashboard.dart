import 'package:delivery/dashboard_screen/profile_screen.dart';
import 'package:delivery/driver/driver_actions.dart';
import 'package:delivery/model/order.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

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
                startingGeoPoint:
                    Map<String, dynamic>.from(orderData['startingGeoPoint']),
                endingGeoPoint:
                    Map<String, dynamic>.from(orderData['endingGeoPoint']),
                distance: orderData['distance'],
                uid: orderData['uid'],
                status: orderData['status'],
                date: orderData['date'],
                vehicleType: orderData['vehicleType'],
                name: orderData['name'],
                isScheduled: orderData['isScheduled'],
                netWeight: double.parse(orderData['netWeight'].toString()),
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

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDE1D5),
      body: SafeArea(
        child: Material(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, ${user?.displayName}!',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
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
                            child: const Icon(
                              Icons.account_circle_outlined,
                              size: 40.0,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: orderList.length,
                      itemBuilder: (context, index) {
                        Order orderInfo = orderList[index];
                        return ListTile(
                          title: Text('Order from ${orderInfo.uid}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Date: ${orderInfo.date}'),
                              Text('Status: ${orderInfo.status}'),
                              // Add more fields as needed
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => DriverActions(
                                      orderInformation: orderInfo)),
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
                          offset:
                              const Offset(0, 2), // changes position of shadow
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
                              MaterialPageRoute(
                                  builder: (context) => ProfileScreen()),
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
                            await _auth.signOut().then((value) => {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const LoginScreen()),
                                  )
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
    );
  }
}
