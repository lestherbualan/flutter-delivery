import 'package:delivery/model/order.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class ScheduleDeliveryScreen extends StatefulWidget {
  const ScheduleDeliveryScreen({super.key});

  @override
  State<ScheduleDeliveryScreen> createState() => _ScheduleDeliveryScreenState();
}

class _ScheduleDeliveryScreenState extends State<ScheduleDeliveryScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  DatabaseReference orderRef = FirebaseDatabase.instance.ref("order");
  DatabaseReference userRef = FirebaseDatabase.instance.ref("user");
  List<Order> orderList = [];
  List<String> orderKey = [];
  List<Map<dynamic, dynamic>> driverList = [];

  Future<void> getScheduledOrder() async {
    DatabaseEvent event = await orderRef.once();
    Map<Object?, Object?> data = event.snapshot.value as Map<Object?, Object?>;
    print(data);
    data.forEach((key, value) {
      Map<String, dynamic> orderData = (value as Map<Object?, Object?>).map(
        (k, v) => MapEntry(k as String, v),
      );
      //print(orderData['uid']);
      if ((orderData['uid'] == user!.uid) && (orderData['isScheduled'] == true)) {
        setState(() {
          orderList.add(Order.fromMap(orderData));
          orderKey.add(key.toString());
        });
      }
    });
  }

  Future<void> fetchDriverList() async {
    DataSnapshot snapshot = await userRef.get();
    userRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        Map<dynamic, dynamic>? data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          List<Map<dynamic, dynamic>> userList = [];
          data.forEach((key, value) {
            if (value['isRider'] == true) {
              userList.add(Map<dynamic, dynamic>.from(value));
            }
          });
          setState(() {
            driverList = userList;
          });
        }
      } else {
        print('No data available.');
      }
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getScheduledOrder();
    fetchDriverList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Delivery'),
      ),
      body: ListView.builder(
        itemCount: orderList.length, // Example number of items
        itemBuilder: (BuildContext context, int index) {
          final order = orderList[index];
          Map<String, dynamic>? driver;
          for (var element in driverList) {
            //print(element);
            if (element['uid'] == order.driverId) {
              driver = element.cast<String, dynamic>();
              break;
            }
          }
          return Dismissible(
            key: Key(index.toString()),
            background: Container(
              color: Colors.red,
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 15.0),
                  child: Icon(
                    Icons.delete_outline_outlined,
                    size: 30.0,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
            secondaryBackground: Container(
              color: Colors.red,
              child: const Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(right: 15.0),
                  child: Icon(
                    Icons.delete_outline_outlined,
                    size: 30.0,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
            onDismissed: (direction) {},
            confirmDismiss: (direction) {
              return showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Confirm'),
                    content: const Text('Are you sure you want to proceed?'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                      ),
                      TextButton(
                        child: const Text('Confirm'),
                        onPressed: () async {
                          Navigator.of(context).pop(true);
                          DatabaseReference orderRef = FirebaseDatabase.instance.ref("order/${orderKey[index]}");
                          DatabaseReference proposalRef = FirebaseDatabase.instance.ref("proposal/${orderKey[index]}");
                          orderRef.remove();
                          proposalRef.remove();

                          // print(order);
                          // print(orderKey[index]);
                        },
                      ),
                    ],
                  );
                },
              );
            },
            child: ListTile(
              title: Text('Driver Name: ${driver?['displayName'] ?? 'No Driver Assigned'}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Text('Status: ${order.status}'), Text('Schedule: ${order.date}')],
              ),
              onTap: () {
                // Add your onTap logic here
                //print('Tapped on item $index');
              },
            ),
          );
        },
      ),
    );
  }
}
