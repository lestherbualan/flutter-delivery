import 'package:delivery/model/order.dart';
import 'package:delivery/model/review.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

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
          orderData['isRated'] = orderData['isRated'] as bool? ?? false;
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
        if (value['driverId'] == review.reviewerId) {
          driverReviewList.add(value['rating']);
          counter++;
        }
      });
      int totalRating = driverReviewList.reduce((value, element) => value + element);

      double calculatedRating = totalRating / counter;
      calculatedRating = double.parse(calculatedRating.toStringAsFixed(2));

      DatabaseReference driver = FirebaseDatabase.instance.ref("user/${review.reviewerId}");
      driver.update({'driverRating': calculatedRating});
    }).catchError((onError) => {print(onError)});
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
            child: Card(
              color: order.status == 'PENDING'
                  ? Colors.yellowAccent
                  : order.status == 'COMPLETED'
                      ? Colors.greenAccent
                      : order.status == 'CANCELED'
                          ? Colors.redAccent
                          : null,
              child: ListTile(
                title: Text('Driver Name: ${driver?['displayName'] ?? 'No Driver Assigned'}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status: ${order.status}'),
                    Text('Schedule: ${order.date}'),
                    if (!order.isRated) const Text('Not yet Rated')
                  ],
                ),
                onTap: () {
                  // Add your onTap logic here
                  //print('Tapped on item $index');
                  String commentText = '';
                  if (order.status == 'COMPLETED') {
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
                                Navigator.pop(context);
                              },
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                DatabaseReference orderRef = FirebaseDatabase.instance.ref("order/${orderKey[index]}");
                                orderRef.update({'isRated': true});

                                Review review = Review(
                                  reviewerId: driver?['uid'] ?? 'Unknown Driver',
                                  orderId: orderKey[index],
                                  rating: double.parse(rating.toString()),
                                  revieweeId: user?.uid ?? 'Unknown User',
                                  message: commentText,
                                );

                                await insertReview(review).then((val) {
                                  Navigator.pop(context);
                                  setState(() {});
                                });
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ScheduleDeliveryScreen()),
                                );
                              },
                              child: const Text('Submit'),
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
