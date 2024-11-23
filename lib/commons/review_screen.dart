import 'package:delivery/model/review.dart';
import 'package:delivery/model/user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  User? currentUser = FirebaseAuth.instance.currentUser;
  List<Review> reviewList = [];
  List<ReviewInfo> reviewInfoList = [];

  Future getCurrentUserReviews() async {
    DatabaseReference reviewRef = FirebaseDatabase.instance.ref("review");
    DatabaseReference userRef = FirebaseDatabase.instance.ref("user/${currentUser?.uid}");
    DataSnapshot user = await userRef.get();
    Map<Object?, Object?> userModel = user.value as Map<Object?, Object?>;

    DatabaseEvent event = await reviewRef.once();
    Map<Object?, Object?> data = event.snapshot.value as Map<Object?, Object?>;

    data.forEach((key, value) async {
      Map<String, dynamic> reviewData = (value as Map<Object?, Object?>).map(
        (k, v) => MapEntry(k as String, v),
      );
      print(reviewData);
      if (userModel['isRider'] == true) {
        if (reviewData['driverId'] == userModel['uid'] && reviewData['reviewerUserType'] == "Customer") {
          setState(() {
            reviewList.add(Review.fromMap(reviewData));
          });
        }
      } else {
        if (reviewData['customerId'] == userModel['uid'] && reviewData['reviewerUserType'] == "Rider") {
          setState(() {
            reviewList.add(Review.fromMap(reviewData));
          });
        }
      }
    });
  }

  Future<List<Map<String, dynamic>>> getUserList() async {
    DatabaseReference userRef = FirebaseDatabase.instance.ref("user");
    DataSnapshot userSnapShot = await userRef.get();

    if (userSnapShot.value != null) {
      Map<dynamic, dynamic> userMap = userSnapShot.value as Map<dynamic, dynamic>;

      // Convert the map values to a list of objects
      List<Map<String, dynamic>> userList = userMap.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      return userList;
    } else {
      return [];
    }
  }

  Future<bool> getUserType() async {
    DatabaseReference userRef = FirebaseDatabase.instance.ref("user/${currentUser?.uid}");
    DataSnapshot user = await userRef.get();
    Map<Object?, Object?> userModel = user.value as Map<Object?, Object?>;

    return !(userModel['isRider'] as bool);
  }

  @override
  void initState() {
    super.initState();

    getCurrentUserReviews();
    getUserList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews'),
      ),
      body: ListView.builder(
        itemCount: reviewList.length,
        itemBuilder: (BuildContext context, int index) {
          Review review = reviewList[index];
          DateTime dateTime = DateTime.parse(review.timestamp);

          if (review.reviewerUserType != "Rider") {
            return Card(
              child: ListTile(
                title: Text(review.customerName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        RatingBarIndicator(
                          rating: review.rating,
                          itemBuilder: (context, index) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          itemCount: 5,
                          itemSize: 15.0,
                          direction: Axis.horizontal,
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Text(review.rating.toString()),
                      ],
                    ),
                    Text(review.message ?? ''),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(DateFormat('yyyy-MM-dd hh:mm a').format(dateTime)),
                  ],
                ),
              ),
            );
          } else {
            return Card(
              child: ListTile(
                title: Text(review.driverName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        RatingBarIndicator(
                          rating: review.rating,
                          itemBuilder: (context, index) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          itemCount: 5,
                          itemSize: 15.0,
                          direction: Axis.horizontal,
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Text(review.rating.toString()),
                      ],
                    ),
                    Text(review.message ?? ''),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(DateFormat('yyyy-MM-dd hh:mm a').format(dateTime)),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

class ReviewInfo {
  String? reviewerName;
  String? revieweeName;
  double? rating;
  String? message;
  String? date;

  ReviewInfo({this.reviewerName, this.revieweeName, this.rating, this.message, this.date});
}
